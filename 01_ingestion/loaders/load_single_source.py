from pathlib import Path
import os
import sys
import time
import uuid

INGESTION = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(INGESTION))

from connectors.gdrive_connector import list_files_in_folder, download_file_as_bytes
from utils.file_parser import parse_file
from utils.db_utils import get_engine, add_metadata, load_to_bronze, write_log

FILE_ID = os.environ["FILE_ID_SRC01"]
TABLE_NAME = "sales_transactions"

def load_source_to_raw(file_id, table_name):
    """Đọc một nguồn, thêm metadata, nạp vào raw và ghi log."""
    batch_id = uuid.uuid4()
    engine = get_engine()
    files = list_files_in_folder(os.environ["GDRIVE_FOLDER_ID"])
    print(f"Tìm thấy {len(files)} mục trong folder")

    total_loaded = 0
    for source in files:
        if source["id"] != file_id:
            continue

        started = time.perf_counter()
        try:
            content = download_file_as_bytes(source["id"])
            df = parse_file(content, source["name"])
            df = add_metadata(df, source["name"], "google_drive", batch_id)

            with engine.begin() as conn:
                rows = load_to_bronze(df, table_name, conn)
                write_log(conn, batch_id, table_name, source["name"], rows,
                          "SUCCESS", round(time.perf_counter() - started, 3))

            total_loaded += rows
            print(f'  OK: {source["name"]} — {rows} dòng')

        except Exception as error:
            print(f'  LỖI: {source["name"]} — {error}')
            try:
                with engine.begin() as conn:
                    write_log(conn, batch_id, table_name, source["name"], 0,
                              "FAILED", round(time.perf_counter() - started, 3),
                              str(error)[:2000])
            except Exception as log_error:
                print(f"  Không ghi được FAILED log: {log_error}")

    print(f"Tổng cộng: {total_loaded} dòng đã load")


def run():
    load_source_to_raw(file_id=FILE_ID, table_name=TABLE_NAME)


if __name__ == "__main__":
    run()
