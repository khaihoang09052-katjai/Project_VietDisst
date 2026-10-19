CREATE TABLE IF NOT EXISTS staging.stg_promotion_program AS

WITH 
source_data AS (
    SELECT *
    FROM raw.promotion_program
    WHERE _batch_id = 'ad0afb01-0568-46c2-9c81-e9b0f5ebfa39'::uuid
),
cleaned_data AS (
    SELECT
        NULLIF(BTRIM(promotion_id), '') AS promotion_id,
        NULLIF(BTRIM(promotion_name), '') AS promotion_name,
        NULLIF(BTRIM(promotion_type), '') AS promotion_type,
        NULLIF(BTRIM(target_channel), '') AS target_channel,
        NULLIF(BTRIM(target_region), '') AS target_region,
        NULLIF(BTRIM(start_date), '')::date AS start_date,
        NULLIF(BTRIM(end_date), '')::date AS end_date,
        NULLIF(BTRIM(applicable_products), '') AS applicable_products,
        NULLIF(BTRIM(discount_pct), '')::numeric AS discount_pct,
        NULLIF(BTRIM(min_order_quantity), '')::numeric AS min_order_quantity,
        NULLIF(BTRIM(budget_vnd), '')::numeric AS budget_vnd,
        NULLIF(BTRIM(actual_cost_vnd), '')::numeric AS actual_cost_vnd,
        NULLIF(BTRIM(status), '') AS status,
        NULLIF(BTRIM(created_by), '') AS created_by
    FROM source_data
)
SELECT *
FROM cleaned_data;

-- Test lại khóa promotion_id: kỳ vọng 40 dòng, 0 khóa thiếu, 0 dòng trùng.
WITH checks AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT(*) FILTER (WHERE promotion_id IS NULL) AS missing_key_rows,
        COUNT(promotion_id) - COUNT(DISTINCT promotion_id) AS duplicate_extra_rows
    FROM staging.stg_promotion_program
)
SELECT *, 40 AS expected_rows,
    CASE WHEN total_rows = 40
          AND missing_key_rows = 0 AND duplicate_extra_rows = 0
         THEN 'PASS' ELSE 'FAIL' END AS test_result
FROM checks;
