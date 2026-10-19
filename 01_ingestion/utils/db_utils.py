from datetime import datetime, timezone
from pathlib import Path
import os
import re
import uuid
from dotenv import load_dotenv
from sqlalchemy import create_engine, Text, DateTime, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.engine import URL

ROOT = Path(__file__).resolve().parents[2]
load_dotenv(ROOT / ".env")


def get_engine():
    '''Chuẩn bị kết nối PostgreSQL'''
    url = URL.create(
        "postgresql+psycopg2",
        username=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        host=os.environ["DB_HOST"],
        port=int(os.environ["DB_PORT"]),
        database=os.environ["DB_NAME"],
    )
    return create_engine(url)


def add_metadata(df, file_name, platform, batch_id):
    '''Gắn thông tin truy vết cho dữ liệu'''
    metadata = {"_source_file", "_source_platform", "_ingested_at", "_batch_id"}
    if metadata.intersection(df.columns):
        raise ValueError("Tên cột nguồn trùng metadata; cần mapping rõ ràng")
    result = df.copy()
    result["_source_file"] = file_name
    result["_source_platform"] = platform
    result["_ingested_at"] = datetime.now(timezone.utc)
    result["_batch_id"] = uuid.UUID(str(batch_id))
    return result


def load_to_bronze(df, table_name, conn):
    '''Nạp DataFrame vào bảng raw'''
    if not re.fullmatch(r"[a-z][a-z0-9_]*", table_name):
        raise ValueError("Tên bảng không hợp lệ")
    if not df.columns.is_unique:
        raise ValueError("Tên cột bị trùng")
    if any(len(str(col).encode("utf-8")) > 63 for col in df.columns):
        raise ValueError("Tên cột quá dài; cần mapping trước khi nạp")

    types = {col: Text() for col in df.columns}
    types["_ingested_at"] = DateTime(timezone=True)
    types["_batch_id"] = UUID(as_uuid=True)
    df.to_sql(
        table_name, con=conn, schema="raw", if_exists="append",
        index=False, dtype=types, chunksize=1000,
    )
    return len(df)


def write_log(conn, batch_id, source_name, source_file,
              rows_loaded, status, duration_sec, error_message=None):
    '''Ghi lịch sử nạp dữ liệu'''
    conn.execute(text("""
        INSERT INTO raw.ingest_log (
            batch_id, source_name, source_file, source_platform,
            rows_loaded, status, duration_sec, error_message
        ) VALUES (
            :batch_id, :source_name, :source_file, 'google_drive',
            :rows_loaded, :status, :duration_sec, :error_message
        )
    """), {
        "batch_id": batch_id, "source_name": source_name,
        "source_file": source_file, "rows_loaded": rows_loaded,
        "status": status, "duration_sec": duration_sec,
        "error_message": error_message,
    })