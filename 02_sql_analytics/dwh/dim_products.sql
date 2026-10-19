-- Tạo bảng nếu chưa có.
CREATE TABLE IF NOT EXISTS dwh.dim_products (
    product_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "product_id" text NOT NULL,
    "product_name" text,
    "category" text,
    "sub_category" text,
    "unit" text,
    "unit_price" numeric,
    "cost_price" numeric,
    "weight_gram" numeric,
    "status" text,
    "launch_date" date,
    UNIQUE ("product_id")
);

-- Nạp dữ liệu một lần; WHERE NOT EXISTS giúp chạy lại không thêm dòng.
INSERT INTO dwh.dim_products (
    "product_id", "product_name", "category", "sub_category", "unit", "unit_price", "cost_price", "weight_gram", "status", "launch_date"
)
SELECT
    "product_id",
    "product_name",
    "category",
    "sub_category",
    "unit",
    "unit_price",
    "cost_price",
    "weight_gram",
    "status",
    "launch_date"
FROM staging.stg_product_master
WHERE NOT EXISTS (SELECT 1 FROM dwh.dim_products);

-- Kiểm tra: kỳ vọng 100 dòng; khóa thiếu và dòng trùng đều bằng 0.
SELECT
    COUNT(*) AS total_rows, 100 AS expected_rows,
    COUNT(*) FILTER (WHERE product_key IS NULL OR product_id IS NULL) AS missing_key_rows,
    COUNT(product_key) - COUNT(DISTINCT product_key) AS duplicate_primary_key_rows,
    COUNT(product_id) - COUNT(DISTINCT product_id) AS duplicate_business_key_rows
FROM dwh.dim_products;
