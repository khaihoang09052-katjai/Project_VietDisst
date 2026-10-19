CREATE TABLE IF NOT EXISTS staging.stg_product_master AS

WITH 
source_data AS (
    SELECT *
    FROM raw.product_master
    WHERE _batch_id = '487949c4-b7c9-466f-b8d8-0f1755cbd30b'::uuid
),
cleaned_data AS (
    SELECT
        NULLIF(BTRIM(product_id), '') AS product_id,
        NULLIF(BTRIM(product_name), '') AS product_name,
        NULLIF(BTRIM(category), '') AS category,
        NULLIF(BTRIM(sub_category), '') AS sub_category,
        NULLIF(BTRIM(unit), '') AS unit,
        NULLIF(BTRIM(unit_price), '')::numeric AS unit_price,
        NULLIF(BTRIM(cost_price), '')::numeric AS cost_price,
        NULLIF(BTRIM(weight_gram), '')::numeric AS weight_gram,
        NULLIF(BTRIM(status), '') AS status,
        NULLIF(BTRIM(launch_date), '')::date AS launch_date
    FROM source_data
)
SELECT *
FROM cleaned_data;

-- Test lại khóa product_id: kỳ vọng 100 dòng, 0 khóa thiếu, 0 dòng trùng.
WITH checks AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT(*) FILTER (WHERE product_id IS NULL) AS missing_key_rows,
        COUNT(product_id) - COUNT(DISTINCT product_id) AS duplicate_extra_rows
    FROM staging.stg_product_master
)
SELECT *, 100 AS expected_rows,
    CASE WHEN total_rows = 100
          AND missing_key_rows = 0 AND duplicate_extra_rows = 0
         THEN 'PASS' ELSE 'FAIL' END AS test_result
FROM checks;
