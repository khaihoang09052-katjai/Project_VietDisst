CREATE TABLE IF NOT EXISTS staging.stg_customer_master AS

WITH 
	 source_data AS ( -- Lấy 1 batch
	SELECT *
    FROM raw.customer_master
    WHERE _batch_id = '0253548e-ef2c-49f2-a4c0-bf90b2ebf13b'::uuid
),
	 cleaned_data AS ( -- Chuẩn hóa DType
	SELECT
        NULLIF(BTRIM(customer_id), '') AS customer_id,
        NULLIF(BTRIM(customer_name), '') AS customer_name,
        NULLIF(BTRIM(customer_type), '') AS customer_type,
        NULLIF(BTRIM(channel), '') AS channel,
        NULLIF(BTRIM(province), '') AS province,
        NULLIF(BTRIM(region), '') AS region,
        NULLIF(BTRIM(address), '') AS address,
        NULLIF(BTRIM(phone), '') AS phone,
        NULLIF(BTRIM(tax_code), '') AS tax_code,
        NULLIF(BTRIM(join_date), '')::date AS join_date,
        NULLIF(BTRIM(credit_limit), '')::numeric AS credit_limit,
        NULLIF(BTRIM(status), '') AS status
	  FROM source_data
)

SELECT *
FROM cleaned_data;

-- Test lại khóa customer_id: kỳ vọng 2000 dòng, 0 khóa thiếu, 0 dòng trùng.
WITH checks AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_key_rows,
        COUNT(customer_id) - COUNT(DISTINCT customer_id) AS duplicate_extra_rows,
        COUNT(*) FILTER (WHERE tax_code IS NULL) AS missing_tax_code_rows
    FROM staging.stg_customer_master
)
SELECT *, 2000 AS expected_rows,
    CASE WHEN total_rows = 2000
          AND missing_key_rows = 0 AND duplicate_extra_rows = 0
         THEN 'PASS' ELSE 'FAIL' END AS test_result
FROM checks;
