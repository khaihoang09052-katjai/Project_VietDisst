-- Tạo bảng và nạp dữ liệu một lần; chạy lại sẽ giữ bảng đang có.
CREATE TABLE IF NOT EXISTS dwh.mart_sales_vs_target AS
WITH
actual AS ( --kết quả bán hàng thực tế của từng nhân viên trong từng tháng
    SELECT
        e.employee_id,
        DATE_TRUNC('month', f.order_date)::date AS month_start_date,
        SUM(f.net_amount) AS actual_revenue,
        SUM(f.quantity) AS actual_quantity,
        COUNT(DISTINCT f.order_id) AS actual_orders
    FROM dwh.fact_sales AS f
    JOIN dwh.dim_employees AS e ON e.employee_key = f.employee_key
    WHERE f.delivery_status = 'Delivered'
    GROUP BY e.employee_id, DATE_TRUNC('month', f.order_date)::date
),
chosen_version AS ( -- chọn phiên bản target áp dụng cho từng tháng
    SELECT DISTINCT ON (month_start_date)
        month_start_date, plan_version, version_date
    FROM dwh.fact_targets
    WHERE month_start_date BETWEEN effective_from AND effective_to
    ORDER BY month_start_date, version_date DESC, plan_version DESC
),
selected_target AS ( -- chỉ lấy các dòng target của phiên bản đã chọn
    SELECT t.*
    FROM dwh.fact_targets AS t
    JOIN chosen_version AS v
      ON v.month_start_date = t.month_start_date
     AND v.plan_version = t.plan_version
     AND v.version_date = t.version_date
    WHERE t.month_start_date BETWEEN t.effective_from AND t.effective_to
),
combined AS ( -- kết hợp dữ liệu bán hàng thực tế và mục tiêu
    SELECT
        COALESCE(a.employee_id, t.employee_id) AS employee_id,
        COALESCE(a.month_start_date, t.month_start_date) AS month_start_date,
        t.plan_region,
        t.plan_team,
        t.employee_id IS NOT NULL AS has_target,
        COALESCE(a.actual_revenue, 0) AS actual_revenue,
        COALESCE(a.actual_quantity, 0) AS actual_quantity,
        COALESCE(a.actual_orders, 0) AS actual_orders,
        t.target_revenue,
        t.target_quantity,
        t.target_new_customers
    FROM actual AS a
    FULL JOIN selected_target AS t
      ON t.employee_id = a.employee_id
     AND t.month_start_date = a.month_start_date
)
SELECT
    c.*,
    v.plan_version AS selected_plan_version,
    v.version_date AS selected_version_date,
    c.actual_revenue - c.target_revenue AS revenue_gap,
    ROUND(100.0 * c.actual_revenue / NULLIF(c.target_revenue, 0), 2)
        AS revenue_achievement_pct,
    ROUND(100.0 * c.actual_quantity / NULLIF(c.target_quantity, 0), 2)
        AS quantity_achievement_pct
FROM combined AS c
LEFT JOIN chosen_version AS v USING (month_start_date);

-- Kiểm tra: kỳ vọng 1284 dòng; khóa thiếu và dòng trùng đều bằng 0.
SELECT
    COUNT(*) AS total_rows, 1284 AS expected_rows,
    COUNT(*) FILTER (WHERE employee_id IS NULL OR month_start_date IS NULL) AS missing_key_rows,
    COUNT(*) - COUNT(DISTINCT (employee_id, month_start_date)) AS duplicate_key_rows,
    SUM(actual_revenue) AS actual_revenue,
    SUM(target_revenue) AS target_revenue
FROM dwh.mart_sales_vs_target;

-- Xem phiên bản target áp dụng ở từng tháng.
SELECT month_start_date, selected_plan_version,
    COUNT(*) FILTER (WHERE has_target) AS targeted_employees
FROM dwh.mart_sales_vs_target
GROUP BY month_start_date, selected_plan_version
ORDER BY month_start_date;
