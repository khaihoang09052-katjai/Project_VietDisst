from io import BytesIO
from pathlib import Path
import pandas as pd


def parse_file(content, file_name, sheet_name=0, header=0,
               sep=",", encoding="utf-8-sig"):
    '''Đọc CSV và Excel thành DataFrame'''
    suffix = Path(file_name).suffix.lower()
    buffer = BytesIO(content)
    if suffix == ".csv":
        return pd.read_csv(
            buffer, sep=sep, encoding=encoding, header=header,
            dtype=str, keep_default_na=False,
        )
    if suffix in {".xlsx", ".xlsm", ".xlsb"}:
        engine = "pyxlsb" if suffix == ".xlsb" else "openpyxl"
        return pd.read_excel(
            buffer, sheet_name=sheet_name, header=header,
            engine=engine, dtype=str, keep_default_na=False,
        )
    raise ValueError(f"Chưa hỗ trợ định dạng: {suffix}")
