CREATE TABLE IF NOT EXISTS staging.stg_employee_master AS

WITH 
source_data AS (
    SELECT *
    FROM raw.employee_master
    WHERE _batch_id = '2b8ad866-0169-4b1b-9ebf-b9e8c3546c25'::uuid
),
cleaned_data AS (
    SELECT
        NULLIF(BTRIM(employee_id), '') AS employee_id,
        NULLIF(BTRIM(full_name), '') AS full_name,
        NULLIF(BTRIM(gender), '') AS gender,
        NULLIF(BTRIM(date_of_birth), '')::date AS date_of_birth,
        NULLIF(BTRIM(join_date), '')::date AS join_date,
        NULLIF(BTRIM("position"), '') AS "position",
        NULLIF(BTRIM(region), '') AS region,
        NULLIF(BTRIM(team), '') AS team,
        NULLIF(BTRIM(email), '') AS email,
        NULLIF(BTRIM(phone), '') AS phone,
        NULLIF(BTRIM(status), '') AS status,
        NULLIF(BTRIM(version), '') AS version,
        NULLIF(BTRIM(effective_date), '')::date AS effective_date,
        NULLIF(BTRIM(resign_date), '')::date AS resign_date,
        NULLIF(BTRIM(transfer_note), '') AS transfer_note
    FROM source_data
)
SELECT *
FROM cleaned_data;

-- Test lại khóa employee_id: kỳ vọng 114 dòng, 0 khóa thiếu, 0 dòng trùng.
WITH checks AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT(*) FILTER (WHERE employee_id IS NULL) AS missing_key_rows,
        COUNT(employee_id) - COUNT(DISTINCT employee_id) AS duplicate_extra_rows
    FROM staging.stg_employee_master
)
SELECT *, 114 AS expected_rows,
    CASE WHEN total_rows = 114
          AND missing_key_rows = 0 AND duplicate_extra_rows = 0
         THEN 'PASS' ELSE 'FAIL' END AS test_result
FROM checks;
