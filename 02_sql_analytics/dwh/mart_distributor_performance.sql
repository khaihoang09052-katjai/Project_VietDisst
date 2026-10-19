-- Tạo bảng và nạp dữ liệu một lần; chạy lại sẽ giữ bảng đang có.
CREATE TABLE IF NOT EXISTS dwh.mart_distributor_performance AS
WITH 
lines AS (
    SELECT
        d.distributor_key, d.distributor_id, d.tier, d.channel,
        d.region AS distributor_region,
        DATE_TRUNC('month', s.order_date)::date AS month_start_date,
        s.order_id, s.qty_ordered, s.qty_delivered,
        s.gross_amount, s.delivered_amount,
        s.delivery_status, s.expected_delivery_date, s.actual_delivery_date,
        s.ontime_delivery
    FROM staging.stg_distributor_orders AS s
    JOIN dwh.dim_distributors AS d
      ON d.distributor_id = s.distributor_id
     AND s.order_date BETWEEN d.effective_from AND d.effective_to
),
orders AS (
    SELECT
        distributor_key, distributor_id, tier, channel, distributor_region,
        month_start_date, order_id,
        BOOL_AND(delivery_status = 'Cancelled') AS is_cancelled,
        COALESCE(SUM(qty_ordered) FILTER (
            WHERE delivery_status <> 'Cancelled'), 0) AS qty_ordered,
        COALESCE(SUM(qty_delivered) FILTER (
            WHERE delivery_status <> 'Cancelled'), 0) AS qty_delivered,
        COALESCE(SUM(gross_amount) FILTER (
            WHERE delivery_status <> 'Cancelled'), 0) AS ordered_amount,
        COALESCE(SUM(delivered_amount) FILTER (
            WHERE delivery_status <> 'Cancelled'), 0) AS delivered_amount,
        BOOL_AND(delivery_status IN ('Delivered', 'Partial')
            AND actual_delivery_date IS NOT NULL
            AND expected_delivery_date IS NOT NULL) AS eligible_for_ontime,
        BOOL_AND(actual_delivery_date <= expected_delivery_date) AS is_ontime,
        COUNT(*) FILTER (
            WHERE (ontime_delivery = 'Yes') IS DISTINCT FROM
                  (actual_delivery_date <= expected_delivery_date)
        ) AS source_ontime_mismatch_lines
    FROM lines
    GROUP BY distributor_key, distributor_id, tier, channel,
        distributor_region, month_start_date, order_id
)
SELECT
    distributor_key, distributor_id, tier, channel, distributor_region,
    month_start_date,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE is_cancelled) AS cancelled_orders,
    SUM(qty_ordered) AS qty_ordered,
    SUM(qty_delivered) AS qty_delivered,
    SUM(ordered_amount) AS ordered_amount,
    SUM(delivered_amount) AS delivered_amount,
    ROUND(100.0 * SUM(qty_delivered) / NULLIF(SUM(qty_ordered), 0), 2)
        AS fill_rate_pct,
    COUNT(*) FILTER (WHERE eligible_for_ontime) AS ontime_eligible_orders,
    COUNT(*) FILTER (WHERE eligible_for_ontime AND is_ontime) AS ontime_orders,
    ROUND(100.0 * COUNT(*) FILTER (WHERE eligible_for_ontime AND is_ontime)
        / NULLIF(COUNT(*) FILTER (WHERE eligible_for_ontime), 0), 2)
        AS ontime_delivery_pct,
    SUM(source_ontime_mismatch_lines) AS source_ontime_mismatch_lines
FROM orders
GROUP BY distributor_key, distributor_id, tier, channel,
    distributor_region, month_start_date;

-- Kiểm tra: kỳ vọng 1480 dòng; khóa thiếu và dòng trùng đều bằng 0.
SELECT
    COUNT(*) AS total_rows, 1480 AS expected_rows,
    COUNT(*) FILTER (WHERE distributor_key IS NULL OR month_start_date IS NULL) AS missing_key_rows,
    COUNT(*) - COUNT(DISTINCT (distributor_key, month_start_date)) AS duplicate_key_rows,
    SUM(total_orders) AS total_orders,
    SUM(delivered_amount) AS delivered_amount
FROM dwh.mart_distributor_performance;
