WITH employee_flattened AS (
    SELECT
        f.value:employee_id::STRING AS employee_id,
        f.value:first_name::STRING AS first_name,
        f.value:last_name::STRING AS last_name,
        f.value:email::STRING AS email,
        f.value:phone::STRING AS phone,
        f.value:date_of_birth::STRING AS date_of_birth,
        f.value:hire_date::STRING AS hire_date,
        f.value:last_modified_date::STRING AS last_modified_date,
        f.value:department::STRING AS department,
        f.value:role::STRING AS role,
        f.value:education::STRING AS education,
        f.value:employment_status::STRING AS employment_status,
        f.value:manager_id::STRING AS manager_id,
        f.value:work_location::STRING AS work_location,
        f.value:salary::NUMBER(18,2) AS salary,
        f.value:sales_target::NUMBER(18,2) AS sales_target,
        f.value:current_sales::NUMBER(18,2) AS current_sales,
        f.value:performance_rating::NUMBER(5,2) AS performance_rating,
        f.value:address.street::STRING AS street,
        f.value:address.city::STRING AS city,
        f.value:address.state::STRING AS state,
        f.value:address.zip_code::STRING AS zip_code,
        f.value:certifications AS certifications,
        _loaded_at,
        _source_file,
        _batch_id
    FROM {{ ref('bronze_employee') }},
         LATERAL FLATTEN(input => VALUE:employees_data) f
),

sorted_employee AS (
    SELECT
        TRIM(employee_id) AS employee_id,
        INITCAP(REGEXP_REPLACE(TRIM(first_name),'[^A-Za-z ]','')) AS first_name,
        INITCAP(REGEXP_REPLACE(TRIM(last_name),'[^A-Za-z ]','')) AS last_name,
        CONCAT(INITCAP(REGEXP_REPLACE(TRIM(first_name),'[^A-Za-z ]','')),' ',INITCAP(REGEXP_REPLACE(TRIM(last_name),'[^A-Za-z ]',''))
        ) AS full_name,
        CASE
            WHEN REGEXP_LIKE(LOWER(TRIM(email)),'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
            THEN LOWER(TRIM(email))
            ELSE NULL
        END AS email,
        RIGHT(REGEXP_REPLACE(phone,'[^0-9]',''),10) AS phone,
        COALESCE(
            TRY_TO_DATE(date_of_birth,'YYYY-MM-DD'),
            TRY_TO_DATE(date_of_birth,'MM-DD-YYYY'),
            TRY_TO_DATE(date_of_birth,'DD-MM-YYYY'),
            TRY_TO_DATE(date_of_birth,'MM/DD/YYYY'),
            TRY_TO_DATE(date_of_birth,'DD/MM/YYYY')
        ) AS date_of_birth,
        COALESCE(
            TRY_TO_DATE(hire_date,'YYYY-MM-DD'),
            TRY_TO_DATE(hire_date,'MM-DD-YYYY'),
            TRY_TO_DATE(hire_date,'DD-MM-YYYY'),
            TRY_TO_DATE(hire_date,'MM/DD/YYYY'),
            TRY_TO_DATE(hire_date,'DD/MM/YYYY')
        ) AS hire_date,
        COALESCE(
            TRY_TO_DATE(last_modified_date,'YYYY-MM-DD'),
            TRY_TO_DATE(last_modified_date,'MM-DD-YYYY'),
            TRY_TO_DATE(last_modified_date,'DD-MM-YYYY'),
            TRY_TO_DATE(last_modified_date,'MM/DD/YYYY'),
            TRY_TO_DATE(last_modified_date,'DD/MM/YYYY')
        ) AS last_modified_date,
        DATEDIFF(
            year,
            COALESCE(
                TRY_TO_DATE(hire_date,'YYYY-MM-DD'),
                TRY_TO_DATE(hire_date,'MM-DD-YYYY'),
                TRY_TO_DATE(hire_date,'DD-MM-YYYY'),
                TRY_TO_DATE(hire_date,'MM/DD/YYYY'),
                TRY_TO_DATE(hire_date,'DD/MM/YYYY')),CURRENT_DATE()
        ) AS tenure_years,
        INITCAP(TRIM(department)) AS department,
        CASE
            WHEN UPPER(role) LIKE '%SALES ASSOCIATE%'
            THEN 'Associate'
            WHEN UPPER(role) LIKE '%STORE MANAGER%'
            THEN 'Manager'
            WHEN UPPER(role) LIKE '%SENIOR MANAGER%'
            THEN 'Senior Manager'
            ELSE INITCAP(TRIM(role))
        END AS role,
        INITCAP(TRIM(education)) AS education,
        INITCAP(TRIM(employment_status)) AS employment_status,
        TRIM(manager_id) AS manager_id,
        INITCAP(TRIM(work_location)) AS work_location,
        COALESCE(salary,0) AS salary,
        COALESCE(sales_target,0) AS sales_target,
        COALESCE(current_sales,0) AS current_sales,
        COALESCE(performance_rating,0) AS performance_rating,
        CASE
            WHEN sales_target > 0
            THEN (current_sales / sales_target) * 100
            ELSE NULL
        END AS target_achievement_percentage,
        INITCAP(TRIM(street)) AS street,
        INITCAP(TRIM(city)) AS city,
        UPPER(TRIM(state)) AS state,
        TRIM(zip_code) AS zip_code,
        ARRAY_TO_STRING(certifications, ', ') AS certifications,
        _loaded_at,
        _source_file,
        _batch_id
    FROM employee_flattened
),

employee_order_metrics AS (
    SELECT
        employee_id,
        COUNT(DISTINCT order_id) AS total_orders_processed,
        SUM(total_amount) AS total_sales_amount
    FROM {{ ref('silver_orders') }}
    GROUP BY employee_id
)
SELECT
    e.*,
    COALESCE(m.total_orders_processed,0) AS total_orders_processed,
    COALESCE(m.total_sales_amount,0) AS total_sales_amount
FROM sorted_employee e
LEFT JOIN employee_order_metrics m
       ON e.employee_id = m.employee_id
QUALIFY ROW_NUMBER()OVER ( PARTITION BY e.employee_id ORDER BY e.last_modified_date DESC) = 1