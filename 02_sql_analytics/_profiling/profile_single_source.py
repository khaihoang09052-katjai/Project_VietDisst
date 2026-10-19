from pathlib import Path
import os
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "01_ingestion"))

from connectors.gdrive_connector import download_file_as_bytes
from utils.file_parser import parse_file
from utils.profiling_utils import build_column_profile, print_batch_summary

FILE_ID = os.environ["FILE_ID_SRC03"]
FILE_NAME = "SRC03_customer_master.csv"
TABLE_NAME = "customer_master"


def run():
    # 1. Đọc file SRC01 bằng FILE_ID đã khai báo trong .env.
    content = download_file_as_bytes(FILE_ID)
    df = parse_file(content=content, file_name=FILE_NAME)

    # 2. Xem lịch sử nạp dữ liệu vào raw.sales_transactions.
    print_batch_summary(TABLE_NAME)

    # 3. Phát hiện NULL, chuỗi rỗng và ô chỉ chứa khoảng trắng.
    column_profile = build_column_profile(df)
    print("Số dòng, số cột:", df.shape)
    print(column_profile.to_string())

    # 4. Kiểm tra dòng trùng toàn bộ nội dung.
    print("Số dòng dư trùng nội dung:", df.duplicated().sum())


if __name__ == "__main__":
    run()
