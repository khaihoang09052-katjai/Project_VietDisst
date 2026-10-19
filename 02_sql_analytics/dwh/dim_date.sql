-- Lịch 2022–2026; năm tài chính bắt đầu tháng 9 và lấy tên năm bắt đầu.
-- Ví dụ: 2023-09-01 đến 2024-08-31 thuộc FY 2023.
-- Tạo bảng nếu chưa có.
CREATE TABLE IF NOT EXISTS dwh.dim_date (
    date_key integer PRIMARY KEY,
    full_date date NOT NULL UNIQUE,
    month_start_date date NOT NULL,
    calendar_year integer NOT NULL,
    calendar_quarter integer NOT NULL,
    calendar_month integer NOT NULL,
    day_of_month integer NOT NULL,
    day_of_week integer NOT NULL,
    week_of_year integer NOT NULL,
    iso_year integer NOT NULL,
    is_weekend boolean NOT NULL,
    fiscal_year integer NOT NULL,
    fiscal_month integer NOT NULL,
    fiscal_quarter integer NOT NULL
);

-- Nạp dữ liệu một lần; WHERE NOT EXISTS giúp chạy lại không thêm dòng.
INSERT INTO dwh.dim_date (
    "date_key", "full_date", "month_start_date", "calendar_year", "calendar_quarter", "calendar_month", "day_of_month", "day_of_week", "week_of_year", "iso_year", "is_weekend", "fiscal_year", "fiscal_month", "fiscal_quarter"
)

WITH
calendar AS (
    SELECT DATE '2022-01-01' + day_offset AS full_date
    FROM generate_series(
        0, DATE '2026-12-31' - DATE '2022-01-01'
    ) AS g(day_offset)
),
attributes AS (
    SELECT
        full_date,
        EXTRACT(YEAR FROM full_date)::integer AS calendar_year,
        EXTRACT(MONTH FROM full_date)::integer AS calendar_month,
        ((EXTRACT(MONTH FROM full_date)::integer - 9 + 12) % 12) + 1 AS fiscal_month
    FROM calendar
)

SELECT
    TO_CHAR(full_date, 'YYYYMMDD')::integer AS date_key,
    full_date,
    DATE_TRUNC('month', full_date)::date AS month_start_date,
    calendar_year,
    EXTRACT(QUARTER FROM full_date)::integer AS calendar_quarter,
    calendar_month,
    EXTRACT(DAY FROM full_date)::integer AS day_of_month,
    EXTRACT(ISODOW FROM full_date)::integer AS day_of_week,
    EXTRACT(WEEK FROM full_date)::integer AS week_of_year,
    EXTRACT(ISOYEAR FROM full_date)::integer AS iso_year,
    EXTRACT(ISODOW FROM full_date) IN (6, 7) AS is_weekend,
    CASE WHEN calendar_month >= 9 THEN calendar_year
         ELSE calendar_year - 1 END AS fiscal_year,
    fiscal_month,
    ((fiscal_month - 1) / 3) + 1 AS fiscal_quarter
FROM attributes
WHERE NOT EXISTS (SELECT 1 FROM dwh.dim_date);

-- Kiểm tra: kỳ vọng 1826 dòng; khóa thiếu và dòng trùng đều bằng 0.
SELECT
    COUNT(*) AS total_rows, 1826 AS expected_rows,
    COUNT(*) FILTER (WHERE date_key IS NULL OR full_date IS NULL) AS missing_key_rows,
    COUNT(date_key) - COUNT(DISTINCT date_key) AS duplicate_primary_key_rows,
    COUNT(full_date) - COUNT(DISTINCT full_date) AS duplicate_business_key_rows,
    MIN(full_date) AS first_date, MAX(full_date) AS last_date
FROM dwh.dim_date;

-- Xem các mốc chuyển năm tài chính theo quy ước tháng 9.
SELECT full_date, fiscal_year, fiscal_month, fiscal_quarter
FROM dwh.dim_date
WHERE full_date IN (DATE '2023-09-01', DATE '2024-01-01', DATE '2024-08-31', DATE '2024-09-01')
ORDER BY full_date;
