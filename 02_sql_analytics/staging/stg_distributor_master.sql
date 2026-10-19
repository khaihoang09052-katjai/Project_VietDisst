CREATE TABLE IF NOT EXISTS staging.stg_distributor_master AS

WITH 
source_data AS (
    SELECT *
    FROM raw.distributor_master
    WHERE _batch_id = '4ba2e0c0-9434-44d3-bcdc-b601fde9186d'::uuid
),
cleaned_data AS (
    SELECT
        NULLIF(BTRIM(distributor_id), '') AS distributor_id,
        NULLIF(BTRIM(distributor_name), '') AS distributor_name,
        NULLIF(BTRIM(tier), '') AS tier,
        NULLIF(BTRIM(channel), '') AS channel,
        NULLIF(BTRIM(province), '') AS province,
        NULLIF(BTRIM(region), '') AS region,
        NULLIF(BTRIM(contact_person), '') AS contact_person,
        NULLIF(BTRIM(phone), '') AS phone,
        NULLIF(BTRIM(email), '') AS email,
        NULLIF(BTRIM(tax_code), '') AS tax_code,
        NULLIF(BTRIM(join_date), '')::date AS join_date,
        NULLIF(BTRIM(credit_limit), '')::numeric AS credit_limit,
        NULLIF(BTRIM(status), '') AS status,
        NULLIF(BTRIM(assigned_supervisor_id), '') AS assigned_supervisor_id
    FROM source_data
)
SELECT *
FROM cleaned_data;

-- Test lại khóa distributor_id: kỳ vọng 138 dòng, 0 khóa thiếu, 0 dòng trùng.
WITH checks AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT(*) FILTER (WHERE distributor_id IS NULL) AS missing_key_rows,
        COUNT(distributor_id) - COUNT(DISTINCT distributor_id) AS duplicate_extra_rows
    FROM staging.stg_distributor_master
)
SELECT *, 138 AS expected_rows,
    CASE WHEN total_rows = 138
          AND missing_key_rows = 0 AND duplicate_extra_rows = 0
         THEN 'PASS' ELSE 'FAIL' END AS test_result
FROM checks;
