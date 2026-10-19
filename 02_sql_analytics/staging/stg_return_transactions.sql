CREATE TABLE IF NOT EXISTS staging.stg_return_transactions AS

WITH 
source_data AS (
    SELECT *
    FROM raw.return_transactions
    WHERE _batch_id = '6df21728-9cd4-41f0-adc3-4e8145acda8f'::uuid
),
cleaned_data AS (
    SELECT
        NULLIF(BTRIM(return_id), '') AS return_id,
        NULLIF(BTRIM(original_order_id), '') AS original_order_id,
        NULLIF(BTRIM(return_date), '')::date AS return_date,
        NULLIF(BTRIM(return_month), '')::integer AS return_month,
        NULLIF(BTRIM(customer_id), '') AS customer_id,
        NULLIF(BTRIM(employee_id), '') AS employee_id,
        NULLIF(BTRIM(product_id), '') AS product_id,
        NULLIF(BTRIM(region), '') AS region,
        NULLIF(BTRIM(province), '') AS province,
        NULLIF(BTRIM(return_quantity), '')::numeric AS return_quantity,
        NULLIF(BTRIM(unit_price), '')::numeric AS unit_price,
        NULLIF(BTRIM(return_amount), '')::numeric AS return_amount,
        NULLIF(BTRIM(return_reason), '') AS return_reason,
        NULLIF(BTRIM(status), '') AS status
    FROM source_data
)
SELECT *
FROM cleaned_data;


-- Test lại khóa return_id: kỳ vọng 3665 dòng, 0 khóa thiếu, 0 dòng trùng.
WITH checks AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT(*) FILTER (WHERE return_id IS NULL) AS missing_key_rows,
        COUNT(return_id) - COUNT(DISTINCT return_id) AS duplicate_extra_rows
    FROM staging.stg_return_transactions
)
SELECT *, 3665 AS expected_rows,
    CASE WHEN total_rows = 3665
          AND missing_key_rows = 0 AND duplicate_extra_rows = 0
         THEN 'PASS' ELSE 'FAIL' END AS test_result
FROM checks;
