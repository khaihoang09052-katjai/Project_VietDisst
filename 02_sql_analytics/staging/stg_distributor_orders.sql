CREATE TABLE IF NOT EXISTS staging.stg_distributor_orders AS

WITH 
source_data AS (
    SELECT *
    FROM raw.distributor_orders
    WHERE _batch_id = '098840ba-d9f6-435f-8e65-d349ba4164cf'::uuid
),
cleaned_data AS (
    SELECT
        NULLIF(BTRIM(order_id), '') AS order_id,
        NULLIF(BTRIM(order_date), '')::date AS order_date,
        NULLIF(BTRIM(order_month), '')::integer AS order_month,
        NULLIF(BTRIM(order_quarter), '')::integer AS order_quarter,
        NULLIF(BTRIM(distributor_id), '') AS distributor_id,
        NULLIF(BTRIM(region), '') AS region,
        NULLIF(BTRIM(channel), '') AS channel,
        NULLIF(BTRIM(product_id), '') AS product_id,
        NULLIF(BTRIM(product_category), '') AS product_category,
        NULLIF(BTRIM(qty_ordered), '')::numeric AS qty_ordered,
        NULLIF(BTRIM(qty_delivered), '')::numeric AS qty_delivered,
        NULLIF(BTRIM(fill_rate_pct), '')::numeric AS fill_rate_pct,
        NULLIF(BTRIM(unit_price_list), '')::numeric AS unit_price_list,
        NULLIF(BTRIM(distributor_price), '')::numeric AS distributor_price,
        NULLIF(BTRIM(gross_amount), '')::numeric AS gross_amount,
        NULLIF(BTRIM(delivered_amount), '')::numeric AS delivered_amount,
        NULLIF(BTRIM(expected_delivery_date), '')::date AS expected_delivery_date,
        NULLIF(BTRIM(actual_delivery_date), '')::date AS actual_delivery_date,
        NULLIF(BTRIM(ontime_delivery), '') AS ontime_delivery,
        NULLIF(BTRIM(delivery_status), '') AS delivery_status,
        NULLIF(BTRIM(payment_terms), '') AS payment_terms
    FROM source_data
)
SELECT *
FROM cleaned_data;


-- Test lại khóa order_id, product_id: kỳ vọng 35945 dòng, 0 khóa thiếu, 0 dòng trùng.
WITH checks AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT(*) FILTER (WHERE order_id IS NULL OR product_id IS NULL) AS missing_key_rows,
        COUNT(*) FILTER (WHERE order_id IS NOT NULL AND product_id IS NOT NULL)
            - COUNT(DISTINCT (order_id, product_id)) FILTER (WHERE order_id IS NOT NULL AND product_id IS NOT NULL) AS duplicate_extra_rows
    FROM staging.stg_distributor_orders
)
SELECT *, 35945 AS expected_rows,
    CASE WHEN total_rows = 35945
          AND missing_key_rows = 0 AND duplicate_extra_rows = 0
         THEN 'PASS' ELSE 'FAIL' END AS test_result
FROM checks;
