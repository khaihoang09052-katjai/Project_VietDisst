CREATE DATABASE vietdist_dw;


-- Kết nối vào database vừa tạo, rồi chạy tiếp:
CREATE SCHEMA IF NOT EXISTS raw;       -- Bronze layer
CREATE SCHEMA IF NOT EXISTS staging;   -- Silver layer
CREATE SCHEMA IF NOT EXISTS dwh;       -- Gold layer

-- Tao bảng log để ghi lại thông tin batch load dữ liệu.
CREATE TABLE IF NOT EXISTS raw.ingest_log (
    log_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id UUID NOT NULL,
    source_name TEXT NOT NULL,
    source_file TEXT NOT NULL,
    source_platform TEXT NOT NULL,
    rows_loaded BIGINT NOT NULL CHECK (rows_loaded >= 0),
    status TEXT NOT NULL CHECK (status IN ('SUCCESS', 'FAILED')),
    duration_sec NUMERIC(12, 3),
    error_message TEXT,
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Kiểm tra:
SELECT schema_name FROM information_schema.schemata
WHERE schema_name IN ('raw', 'staging', 'dwh');


