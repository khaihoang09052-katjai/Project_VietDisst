-- Check đủ 2 version không
SELECT DISTINCT plan_version, stp.version_date, stp.effective_from, stp.effective_to 
FROM raw.sales_target_plan stp 

CREATE TABLE IF NOT EXISTS staging.stg_sales_targets_versioned AS

WITH 
source_data AS (
    -- Lấy batch có tổng cộng 1.950 dòng.
    SELECT *
    FROM raw.sales_target_plan
    WHERE _batch_id = 'e87b5427-b671-41c7-b8fd-461fde77f409'::uuid
),
cleaned_data AS (
    -- Chuẩn hóa chuỗi rỗng và chuyển kiểu dữ liệu.
    SELECT
        -- Thông tin phiên bản.
        NULLIF(BTRIM(plan_version), '') AS plan_version,
        NULLIF(BTRIM(version_date), '')::date AS version_date,
        NULLIF(BTRIM(effective_from), '')::date AS effective_from,
        NULLIF(BTRIM(effective_to), '')::date AS effective_to,
        -- Thông tin nhân viên.
        NULLIF(BTRIM(employee_id), '') AS employee_id,
        NULLIF(BTRIM(employee_name), '') AS employee_name,
        NULLIF(BTRIM(region), '') AS region,
        NULLIF(BTRIM(team), '') AS team,
        -- Kỳ target.
        NULLIF(BTRIM(year), '')::integer AS year,
        NULLIF(BTRIM(month), '')::integer AS month,
        -- Các chỉ tiêu.
        NULLIF(BTRIM(target_revenue), '')::numeric AS target_revenue,
        NULLIF(BTRIM(target_quantity), '')::numeric AS target_quantity,
        NULLIF(BTRIM(target_new_customers), '')::numeric AS target_new_customers
    FROM source_data
)
SELECT * 
FROM cleaned_data;

-- Kiểm tra số dòng, số nhân viên và phạm vi tháng
SELECT
    plan_version,
    COUNT(*) AS row_count,
    COUNT(DISTINCT employee_id) AS employee_count,
    ARRAY_AGG(
        DISTINCT month ORDER BY month
    ) AS months,
    MIN(effective_from) AS min_effective_from,
    MAX(effective_to) AS max_effective_to
FROM staging.stg_sales_targets_versioned
GROUP BY plan_version
ORDER BY plan_version;