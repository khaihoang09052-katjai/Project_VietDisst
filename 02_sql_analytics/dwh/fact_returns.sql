-- Tạo bảng nếu chưa có.
CREATE TABLE IF NOT EXISTS dwh.fact_returns (
    return_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    return_id text NOT NULL,
    original_order_id text NOT NULL,
    product_id text NOT NULL,
    original_sales_key bigint NOT NULL REFERENCES dwh.fact_sales(sales_key),
    return_date date NOT NULL,
    date_key integer NOT NULL REFERENCES dwh.dim_date(date_key),
    employee_key bigint NOT NULL REFERENCES dwh.dim_employees(employee_key),
    customer_key bigint NOT NULL REFERENCES dwh.dim_customers(customer_key),
    product_key bigint NOT NULL REFERENCES dwh.dim_products(product_key),
    return_region text,
    return_province text,
    return_quantity numeric,
    unit_price numeric,
    return_amount numeric,
    return_reason text,
    status text,
    UNIQUE (return_id)
);

-- Nạp dữ liệu một lần; chạy lại khi bảng đã có dữ liệu sẽ không thêm dòng.
INSERT INTO dwh.fact_returns (
    return_id, original_order_id, product_id, original_sales_key, return_date, date_key, employee_key, customer_key, product_key, return_region, return_province, return_quantity, unit_price, return_amount, return_reason, status
)
SELECT
    s.return_id AS return_id,
    s.original_order_id AS original_order_id,
    s.product_id AS product_id,
    f.sales_key AS original_sales_key,
    s.return_date AS return_date,
    d.date_key AS date_key,
    e.employee_key AS employee_key,
    c.customer_key AS customer_key,
    p.product_key AS product_key,
    s.region AS return_region,
    s.province AS return_province,
    s.return_quantity AS return_quantity,
    s.unit_price AS unit_price,
    s.return_amount AS return_amount,
    s.return_reason AS return_reason,
    s.status AS status
FROM staging.stg_return_transactions AS s
LEFT JOIN dwh.fact_sales AS f
    ON f.order_id = s.original_order_id AND f.product_id = s.product_id
LEFT JOIN dwh.dim_date AS d ON d.full_date = s.return_date
LEFT JOIN dwh.dim_employees AS e
    ON e.employee_id = s.employee_id
   AND s.return_date BETWEEN e.effective_from AND e.effective_to
LEFT JOIN dwh.dim_customers AS c ON c.customer_id = s.customer_id
LEFT JOIN dwh.dim_products AS p ON p.product_id = s.product_id
WHERE NOT EXISTS (SELECT 1 FROM dwh.fact_returns);

-- Kiểm tra: kỳ vọng 3665 dòng; khóa thiếu và dòng trùng đều bằng 0.
SELECT
    COUNT(*) AS total_rows, 3665 AS expected_rows,
    COUNT(*) FILTER (WHERE return_key IS NULL OR return_id IS NULL OR original_sales_key IS NULL OR date_key IS NULL OR employee_key IS NULL OR customer_key IS NULL OR product_key IS NULL) AS missing_key_rows,
    COUNT(return_key) - COUNT(DISTINCT return_key) AS duplicate_primary_key_rows,
    COUNT(return_id) - COUNT(DISTINCT return_id) AS duplicate_business_key_rows
FROM dwh.fact_returns;

-- Đối chiếu nguồn và fact: số dòng và các tổng phải giống nhau.
SELECT 'staging' AS data_source, COUNT(*) AS row_count,
    SUM(return_quantity) AS return_quantity, SUM(return_amount) AS return_amount
FROM staging.stg_return_transactions
UNION ALL
SELECT 'fact', COUNT(*),
    SUM(return_quantity), SUM(return_amount)
FROM dwh.fact_returns;
