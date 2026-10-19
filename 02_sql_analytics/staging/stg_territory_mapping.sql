CREATE TABLE IF NOT EXISTS staging.stg_territory_mapping AS

WITH 
source_data AS (
    SELECT *
    FROM raw.territory_mapping
    WHERE _batch_id = '214cbd7f-23c1-4860-96d0-beca2796ada5'::uuid
),
cleaned_data AS (
    SELECT
        NULLIF(BTRIM(territory_id), '') AS territory_id,
        NULLIF(BTRIM(employee_id), '') AS employee_id,
        NULLIF(BTRIM(customer_id), '') AS customer_id,
        NULLIF(BTRIM(region), '') AS region,
        NULLIF(BTRIM(team), '') AS team,
        NULLIF(BTRIM(effective_date), '')::date AS effective_date,
        NULLIF(BTRIM(expiry_date), '')::date AS expiry_date,
        NULLIF(BTRIM(version), '') AS version
    FROM source_data
)
SELECT *
FROM cleaned_data;


-- Test lại khóa territory_id: kỳ vọng 1843 dòng, 0 khóa thiếu, 0 dòng trùng.
WITH checks AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT(*) FILTER (WHERE territory_id IS NULL) AS missing_key_rows,
        COUNT(territory_id) - COUNT(DISTINCT territory_id) AS duplicate_extra_rows
    FROM staging.stg_territory_mapping
)
SELECT *, 1843 AS expected_rows,
    CASE WHEN total_rows = 1843
          AND missing_key_rows = 0 AND duplicate_extra_rows = 0
         THEN 'PASS' ELSE 'FAIL' END AS test_result
FROM checks;
