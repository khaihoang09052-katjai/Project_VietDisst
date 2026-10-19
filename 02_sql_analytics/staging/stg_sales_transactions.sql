CREATE TABLE IF NOT EXISTS staging.stg_sales_transactions AS

WITH source_data AS (
    SELECT *
    FROM raw.sales_transactions
    WHERE _batch_id = 'f055b828-ff5f-4365-a653-4becc3287851'::uuid
),
cleaned_data AS (
    SELECT
        NULLIF(BTRIM(order_id), '') AS order_id,
        NULLIF(BTRIM(order_date), '')::date AS order_date,
        NULLIF(BTRIM(order_month), '')::integer AS order_month,
        NULLIF(BTRIM(order_quarter), '')::integer AS order_quarter,
        NULLIF(BTRIM(order_year), '')::integer AS order_year,
        NULLIF(BTRIM(customer_id), '') AS customer_id,
        NULLIF(BTRIM(region), '') AS region,
        NULLIF(BTRIM(province), '') AS province,
        NULLIF(BTRIM(channel), '') AS channel,
        NULLIF(BTRIM(employee_id), '') AS employee_id,
        NULLIF(BTRIM(product_id), '') AS product_id,
        NULLIF(BTRIM(product_category), '') AS product_category,
        NULLIF(BTRIM(quantity), '')::numeric AS quantity,
        NULLIF(BTRIM(unit_price), '')::numeric AS unit_price,
        NULLIF(BTRIM(discount_pct), '')::numeric AS discount_pct,
        NULLIF(BTRIM(discount_amount), '')::numeric AS discount_amount,
        NULLIF(BTRIM(gross_amount), '')::numeric AS gross_amount,
        NULLIF(BTRIM(net_amount), '')::numeric AS net_amount,
        NULLIF(BTRIM(delivery_status), '') AS delivery_status,
        NULLIF(BTRIM(payment_method), '') AS payment_method,
        NULLIF(BTRIM(payment_status), '') AS payment_status
    FROM source_data
)
SELECT *
FROM cleaned_data;

--Thêm khóa PK
ALTER TABLE staging.stg_sales_transactions
ADD COLUMN sales_row_id BIGINT
GENERATED ALWAYS AS IDENTITY;

-- Kiểm tra số dòng, khóa thiếu và dòng trùng theo order_id + product_id.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_order_ids,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_id_rows,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS missing_product_id_rows,
    COUNT(*) - COUNT(DISTINCT (order_id, product_id)) AS duplicate_extra_rows
FROM staging.stg_sales_transactions;


