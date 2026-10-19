"""Các bước profiling dùng chung cho các bảng nguồn."""

import re

import pandas as pd
from sqlalchemy import text

from utils.db_utils import get_engine


def print_batch_summary(table_name):
    """Xem mỗi batch đã nạp bao nhiêu dòng vào bảng raw."""
    if not re.fullmatch(r"[a-z][a-z0-9_]*", table_name):
        raise ValueError("Tên bảng không hợp lệ")

    engine = get_engine()
    with engine.connect() as conn:
        batch_summary = pd.read_sql_query(
            text(f"""
                SELECT
                    _batch_id,
                    _source_file,
                    COUNT(*) AS row_count,
                    MIN(_ingested_at) AS ingested_at
                FROM raw.{table_name}
                GROUP BY _batch_id, _source_file
                ORDER BY ingested_at DESC
            """),
            conn,
        )

        print(batch_summary.to_string(index=False))


def build_column_profile(df):
    """Lập bảng kiểm tra NULL, chuỗi rỗng, khoảng trắng và giá trị khác nhau."""
    # Phân loại các dạng dữ liệu thiếu/rỗng.
    text_view = df.astype("string")
    null_mask = df.isna()
    empty_mask = text_view.eq("").fillna(False)
    space_mask = text_view.apply(
        lambda col: col.str.fullmatch(r"\s+", na=False)
    )

    # Gộp các dạng trên để tính tổng số ô thiếu.
    missing_mask = null_mask | empty_mask | space_mask
    profile = df.mask(missing_mask)

    column_profile = pd.DataFrame({
        "dtype": df.dtypes,
        "null_rows": null_mask.sum(),
        "empty_rows": empty_mask.sum(),
        "space_rows": space_mask.sum(),
        "missing_rows": missing_mask.sum(),
        "missing_pct": missing_mask.mean().mul(100).round(2),
        "distinct_nonmissing": profile.nunique(),
    })

    return column_profile
