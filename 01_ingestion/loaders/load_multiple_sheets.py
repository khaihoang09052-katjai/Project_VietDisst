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

FILE_ID = os.environ["FILE_ID_SRC02"]
TABLE_NAME = "sales_target_plan"
SHEET_NAMES = ["Plan_v1_Original", "Plan_v2_Adjustment_H2"]


def load_sheets_to_raw(file_id, table_name, sheet_names):
    """Đọc nhiều sheet, thêm metadata và nạp chung trong một transaction."""
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
            file_rows = 0

            with engine.begin() as conn:
                for sheet in sheet_names:
                    # Đọc từng sheet và giữ cùng batch_id cho cả file.
                    df = parse_file(content, source["name"], sheet_name=sheet)
                    df = add_metadata(df, source["name"], "google_drive", batch_id)
                    rows = load_to_bronze(df, table_name, conn)
                    write_log(conn, batch_id, table_name, source["name"], rows,
                            "SUCCESS", round(time.perf_counter() - started, 3))
                    file_rows += rows

            total_loaded += file_rows
            print(f'  OK: {source["name"]} — {file_rows} dòng từ {len(sheet_names)} sheet')

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
    load_sheets_to_raw(
        file_id=FILE_ID,
        table_name=TABLE_NAME,
        sheet_names=SHEET_NAMES,
    )


if __name__ == "__main__":
    run()
