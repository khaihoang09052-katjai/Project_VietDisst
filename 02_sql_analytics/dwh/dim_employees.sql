-- Tạo bảng nếu chưa có.
CREATE TABLE IF NOT EXISTS dwh.dim_employees (
    employee_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "employee_id" text NOT NULL,
    "full_name" text,
    "gender" text,
    "date_of_birth" date,
    "join_date" date,
    "position" text,
    "region" text,
    "team" text,
    "email" text,
    "phone" text,
    "status" text,
    "resign_date" date,
    "transfer_note" text,
    "effective_from" date NOT NULL,
    "effective_to" date NOT NULL,
    "is_current" boolean NOT NULL,
    "attribute_source" text,
    UNIQUE ("employee_id", effective_from),
    CHECK (effective_to >= effective_from)
);

-- Nạp lịch sử v1 và các thay đổi vùng/nhóm từ v2; chỉ nạp khi bảng đang rỗng.
INSERT INTO dwh.dim_employees ( 
    "employee_id", "full_name", "gender", "date_of_birth", "join_date", "position", "region", "team", "email", "phone", "status", "resign_date", "transfer_note", "effective_from", "effective_to", "is_current", "attribute_source"
)
WITH 
changed_employees AS (-- Tìm nhân viên khác với bảng employee_master
    SELECT DISTINCT t.employee_id, t.region, t.team, t.effective_from
    FROM staging.stg_sales_targets_versioned AS t
    JOIN staging.stg_employee_master AS e USING (employee_id)
    WHERE t.plan_version = 'v2'
      AND (t.region IS DISTINCT FROM e.region OR t.team IS DISTINCT FROM e.team)
),
history AS (
    SELECT employee_id, region, team, effective_date AS effective_from,
           'stg_employee_master:v1'::text AS attribute_source
    FROM staging.stg_employee_master

    UNION ALL

    SELECT employee_id, region, team, effective_from,
           'stg_sales_targets_versioned:v2'::text AS attribute_source
    FROM changed_employees
),
timeline AS ( -- tìm ngày bắt đầu của lần thay đổi tiếp theo của từng nhân viên
    SELECT *, LEAD(effective_from) OVER (
        PARTITION BY employee_id ORDER BY effective_from
    ) AS next_effective_from
    FROM history
)
SELECT
    t.employee_id,
    e.full_name,
    e.gender,
    e.date_of_birth,
    e.join_date,
    e."position",
    t.region,
    t.team,
    e.email,
    e.phone,
    e.status,
    e.resign_date,
    e.transfer_note,
    t.effective_from,
    COALESCE(t.next_effective_from - 1, DATE '9999-12-31') AS effective_to,

    t.next_effective_from IS NULL AS is_current,
    t.attribute_source
FROM timeline AS t
JOIN staging.stg_employee_master e USING (employee_id)
WHERE NOT EXISTS (SELECT 1 FROM dwh.dim_employees);

-- Kiểm tra: kỳ vọng 119 dòng; khóa thiếu và dòng trùng đều bằng 0.
SELECT
    COUNT(*) AS total_rows, 119 AS expected_rows,
    COUNT(*) FILTER (WHERE employee_key IS NULL OR employee_id IS NULL OR effective_from IS NULL) AS missing_key_rows,
    COUNT(employee_key) - COUNT(DISTINCT employee_key) AS duplicate_primary_key_rows,
    COUNT(*) - COUNT(DISTINCT (employee_id, effective_from)) AS duplicate_business_key_rows,
    COUNT(DISTINCT employee_id) AS business_ids,
    COUNT(*) FILTER (WHERE is_current) AS current_rows
FROM dwh.dim_employees;
