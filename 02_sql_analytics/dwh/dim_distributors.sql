-- Tạo bảng nếu chưa có.
CREATE TABLE IF NOT EXISTS dwh.dim_distributors (
    distributor_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "distributor_id" text NOT NULL,
    "distributor_name" text,
    "tier" text,
    "channel" text,
    "province" text,
    "region" text,
    "contact_person" text,
    "phone" text,
    "email" text,
    "tax_code" text,
    "join_date" date,
    "credit_limit" numeric,
    "status" text,
    "assigned_supervisor_id" text,
    "effective_from" date NOT NULL,
    "effective_to" date NOT NULL,
    "is_current" boolean NOT NULL,
    UNIQUE ("distributor_id", effective_from),
    CHECK (effective_to >= effective_from)
);

-- Nạp dữ liệu một lần; WHERE NOT EXISTS giúp chạy lại không thêm dòng.
INSERT INTO dwh.dim_distributors (
    "distributor_id", "distributor_name", "tier", "channel", "province", "region", "contact_person", "phone", "email", "tax_code", "join_date", "credit_limit", "status", "assigned_supervisor_id", "effective_from", "effective_to", "is_current"
)
WITH parameters AS (
    SELECT DATE '2024-01-01' AS baseline_effective_from
)
SELECT
    s."distributor_id",
    s."distributor_name",
    s."tier",
    s."channel",
    s."province",
    s."region",
    s."contact_person",
    s."phone",
    s."email",
    s."tax_code",
    s."join_date",
    s."credit_limit",
    s."status",
    s."assigned_supervisor_id",
    p.baseline_effective_from AS effective_from,
    DATE '9999-12-31' AS effective_to,
    TRUE AS is_current
FROM staging.stg_distributor_master AS s
CROSS JOIN parameters AS p
WHERE NOT EXISTS (SELECT 1 FROM dwh.dim_distributors);

-- Kiểm tra: kỳ vọng 138 dòng; khóa thiếu và dòng trùng đều bằng 0.
SELECT
    COUNT(*) AS total_rows, 138 AS expected_rows,
    COUNT(*) FILTER (WHERE distributor_key IS NULL OR distributor_id IS NULL OR effective_from IS NULL) AS missing_key_rows,
    COUNT(distributor_key) - COUNT(DISTINCT distributor_key) AS duplicate_primary_key_rows,
    COUNT(*) - COUNT(DISTINCT (distributor_id, effective_from)) AS duplicate_business_key_rows,
    COUNT(DISTINCT distributor_id) AS business_ids,
    COUNT(*) FILTER (WHERE is_current) AS current_rows
FROM dwh.dim_distributors;
