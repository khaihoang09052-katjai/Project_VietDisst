-- Tạo bảng nếu chưa có.
CREATE TABLE IF NOT EXISTS dwh.fact_sales (
    sales_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id text NOT NULL,
    product_id text NOT NULL,
    order_date date NOT NULL,
    date_key integer NOT NULL REFERENCES dwh.dim_date(date_key),
    employee_key bigint NOT NULL REFERENCES dwh.dim_employees(employee_key),
    customer_key bigint NOT NULL REFERENCES dwh.dim_customers(customer_key),
    product_key bigint NOT NULL REFERENCES dwh.dim_products(product_key),
    sales_region text,
    sales_province text,
    sales_channel text,
    quantity numeric,
    unit_price numeric,
    discount_pct numeric,
    discount_amount numeric,
    gross_amount numeric,
    net_amount numeric,
    delivery_status text,
    payment_method text,
    payment_status text,
    UNIQUE (order_id, product_id)
);

-- Nạp dữ liệu một lần; chạy lại khi bảng đã có dữ liệu sẽ không thêm dòng.
INSERT INTO dwh.fact_sales (
    order_id, product_id, order_date, date_key, employee_key, customer_key, product_key, sales_region, sales_province, sales_channel, quantity, unit_price, discount_pct, discount_amount, gross_amount, net_amount, delivery_status, payment_method, payment_status
)
SELECT
    s.order_id AS order_id,
    s.product_id AS product_id,
    s.order_date AS order_date,
    d.date_key AS date_key,
    e.employee_key AS employee_key,
    c.customer_key AS customer_key,
    p.product_key AS product_key,
    s.region AS sales_region,
    s.province AS sales_province,
    s.channel AS sales_channel,
    s.quantity AS quantity,
    s.unit_price AS unit_price,
    s.discount_pct AS discount_pct,
    s.discount_amount AS discount_amount,
    s.gross_amount AS gross_amount,
    s.net_amount AS net_amount,
    s.delivery_status AS delivery_status,
    s.payment_method AS payment_method,
    s.payment_status AS payment_status
FROM staging.stg_sales_transactions AS s
LEFT JOIN dwh.dim_date AS d ON d.full_date = s.order_date
LEFT JOIN dwh.dim_employees AS e
    ON e.employee_id = s.employee_id
   AND s.order_date BETWEEN e.effective_from AND e.effective_to
LEFT JOIN dwh.dim_customers AS c ON c.customer_id = s.customer_id
LEFT JOIN dwh.dim_products AS p ON p.product_id = s.product_id
WHERE NOT EXISTS (SELECT 1 FROM dwh.fact_sales);

-- Kiểm tra: kỳ vọng 119101 dòng; khóa thiếu và dòng trùng đều bằng 0.
SELECT
    COUNT(*) AS total_rows, 119101 AS expected_rows,
    COUNT(*) FILTER (WHERE sales_key IS NULL OR order_id IS NULL OR product_id IS NULL OR date_key IS NULL OR employee_key IS NULL OR customer_key IS NULL OR product_key IS NULL) AS missing_key_rows,
    COUNT(sales_key) - COUNT(DISTINCT sales_key) AS duplicate_primary_key_rows,
    COUNT(*) - COUNT(DISTINCT (order_id, product_id)) AS duplicate_business_key_rows
FROM dwh.fact_sales;

-- Đối chiếu nguồn và fact: số dòng và các tổng phải giống nhau.
SELECT 'staging' AS data_source, COUNT(*) AS row_count,
    SUM(quantity) AS quantity, SUM(gross_amount) AS gross_amount, SUM(net_amount) AS net_amount
FROM staging.stg_sales_transactions
UNION ALL
SELECT 'fact', COUNT(*),
    SUM(quantity), SUM(gross_amount), SUM(net_amount)
FROM dwh.fact_sales;
