-- Tạo bảng nếu chưa có.
CREATE TABLE IF NOT EXISTS dwh.fact_targets (
    target_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id text NOT NULL,
    year integer NOT NULL,
    month integer NOT NULL CHECK (month BETWEEN 1 AND 12),
    plan_version text NOT NULL,
    month_start_date date NOT NULL,
    date_key integer NOT NULL REFERENCES dwh.dim_date(date_key),
    employee_key bigint NOT NULL REFERENCES dwh.dim_employees(employee_key),
    version_date date NOT NULL,
    effective_from date NOT NULL,
    effective_to date NOT NULL CHECK (effective_to >= effective_from),
    plan_region text,
    plan_team text,
    target_revenue numeric,
    target_quantity numeric,
    target_new_customers numeric,
    UNIQUE (employee_id, year, month, plan_version)
);

-- Nạp dữ liệu một lần; chạy lại khi bảng đã có dữ liệu sẽ không thêm dòng.
INSERT INTO dwh.fact_targets (
    employee_id, year, month, plan_version, month_start_date, date_key, employee_key, version_date, effective_from, effective_to, plan_region, plan_team, target_revenue, target_quantity, target_new_customers
)
SELECT
    s.employee_id AS employee_id,
    s.year AS year,
    s.month AS month,
    s.plan_version AS plan_version,
    MAKE_DATE(s.year, s.month, 1) AS month_start_date,
    d.date_key AS date_key,
    e.employee_key AS employee_key,
    s.version_date AS version_date,
    s.effective_from AS effective_from,
    s.effective_to AS effective_to,
    s.region AS plan_region,
    s.team AS plan_team,
    s.target_revenue AS target_revenue,
    s.target_quantity AS target_quantity,
    s.target_new_customers AS target_new_customers
FROM staging.stg_sales_targets_versioned AS s
LEFT JOIN dwh.dim_date AS d
    ON d.full_date = MAKE_DATE(s.year, s.month, 1)
LEFT JOIN dwh.dim_employees AS e
    ON e.employee_id = s.employee_id
   AND MAKE_DATE(s.year, s.month, 1)
       BETWEEN e.effective_from AND e.effective_to
WHERE NOT EXISTS (SELECT 1 FROM dwh.fact_targets);

-- Kiểm tra: kỳ vọng 1950 dòng; khóa thiếu và dòng trùng đều bằng 0.
SELECT
    COUNT(*) AS total_rows, 1950 AS expected_rows,
    COUNT(*) FILTER (WHERE target_key IS NULL OR employee_id IS NULL OR year IS NULL OR month IS NULL OR plan_version IS NULL OR date_key IS NULL OR employee_key IS NULL) AS missing_key_rows,
    COUNT(target_key) - COUNT(DISTINCT target_key) AS duplicate_primary_key_rows,
    COUNT(*) - COUNT(DISTINCT (employee_id, year, month, plan_version)) AS duplicate_business_key_rows
FROM dwh.fact_targets;

-- Đối chiếu nguồn và fact: số dòng và các tổng phải giống nhau.
SELECT 'staging' AS data_source, COUNT(*) AS row_count,
    SUM(target_revenue) AS target_revenue, SUM(target_quantity) AS target_quantity, SUM(target_new_customers) AS target_new_customers
FROM staging.stg_sales_targets_versioned
UNION ALL
SELECT 'fact', COUNT(*),
    SUM(target_revenue), SUM(target_quantity), SUM(target_new_customers)
FROM dwh.fact_targets;
