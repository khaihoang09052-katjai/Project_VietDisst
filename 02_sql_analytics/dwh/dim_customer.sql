-- Tạo bảng nếu chưa có.
CREATE TABLE IF NOT EXISTS dwh.dim_customers (
    customer_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "customer_id" text NOT NULL,
    "customer_name" text,
    "customer_type" text,
    "channel" text,
    "province" text,
    "region" text,
    "address" text,
    "phone" text,
    "tax_code" text,
    "join_date" date,
    "credit_limit" numeric,
    "status" text,
    "loyalty_tier" text,
    UNIQUE ("customer_id")
);

-- Nạp dữ liệu một lần; WHERE NOT EXISTS giúp chạy lại không thêm dòng.
INSERT INTO dwh.dim_customers (
    "customer_id", "customer_name", "customer_type", "channel", "province", "region", "address", "phone", "tax_code", "join_date", "credit_limit", "status", "loyalty_tier"
)
SELECT
    "customer_id",
    "customer_name",
    "customer_type",
    "channel",
    "province",
    "region",
    "address",
    "phone",
    "tax_code",
    "join_date",
    "credit_limit",
    "status",
    NULL::text AS loyalty_tier
FROM staging.stg_customer_master
WHERE NOT EXISTS (SELECT 1 FROM dwh.dim_customers);

-- Kiểm tra: kỳ vọng 2000 dòng; khóa thiếu và dòng trùng đều bằng 0.
SELECT
    COUNT(*) AS total_rows, 2000 AS expected_rows,
    COUNT(*) FILTER (WHERE customer_key IS NULL OR customer_id IS NULL) AS missing_key_rows,
    COUNT(customer_key) - COUNT(DISTINCT customer_key) AS duplicate_primary_key_rows,
    COUNT(customer_id) - COUNT(DISTINCT customer_id) AS duplicate_business_key_rows
FROM dwh.dim_customers;
