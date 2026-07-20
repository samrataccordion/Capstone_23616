WITH store_flattened AS (
    SELECT
        f.value:store_id::STRING AS store_id,
        f.value:store_name::STRING AS store_name,
        f.value:store_type::STRING AS store_type,
        f.value:manager_id::STRING AS manager_id,
        f.value:email::STRING AS email,
        f.value:phone_number::STRING AS phone,
        f.value:region::STRING AS region,
        f.value:opening_date::STRING AS opening_date,
        f.value:last_modified_date::STRING AS last_modified_date,
        f.value:employee_count::NUMBER AS employee_count,
        f.value:current_sales::NUMBER(18,2) AS current_sales,
        f.value:sales_target::NUMBER(18,2) AS sales_target,
        f.value:monthly_rent::NUMBER(18,2) AS monthly_rent,
        f.value:size_sq_ft::NUMBER AS size_sq_ft,
        f.value:is_active::BOOLEAN AS is_active,
        f.value:address.street::STRING AS street,
        f.value:address.city::STRING AS city,
        f.value:address.state::STRING AS state,
        f.value:address.country::STRING AS country,
        f.value:address.zip_code::STRING AS zip_code,
        f.value:operating_hours.weekdays::STRING AS weekdays_hours,
        f.value:operating_hours.weekends::STRING AS weekends_hours,
        f.value:operating_hours.holidays::STRING AS holidays_hours,
        ARRAY_TO_STRING(f.value:services, ', ') AS services,
        _loaded_at,
        _source_file,
        _batch_id
    FROM {{ ref('bronze_store') }},
    LATERAL FLATTEN(input => VALUE:stores_data) f
),

sorted_stores AS (
    SELECT
        TRIM(store_id) AS store_id,
        INITCAP(REGEXP_REPLACE(TRIM(store_name),'[^A-Za-z0-9 ]','')) AS store_name,
        INITCAP(TRIM(store_type)) AS store_type,
        TRIM(manager_id) AS manager_id,
        CASE
            WHEN REGEXP_LIKE(LOWER(TRIM(email)),'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
            THEN LOWER(TRIM(email))
            ELSE NULL
        END AS email,
        RIGHT(REGEXP_REPLACE(phone,'[^0-9]',''),13) AS phone,
        INITCAP(TRIM(region)) AS region,
        COALESCE(
            TRY_TO_DATE(opening_date,'YYYY-MM-DD'),
            TRY_TO_DATE(opening_date,'MM-DD-YYYY'),
            TRY_TO_DATE(opening_date,'DD-MM-YYYY'),
            TRY_TO_DATE(opening_date,'MM/DD/YYYY'),
            TRY_TO_DATE(opening_date,'DD/MM/YYYY')
        ) AS opening_date,
        COALESCE(
            TRY_TO_DATE(last_modified_date,'YYYY-MM-DD'),
            TRY_TO_DATE(last_modified_date,'MM-DD-YYYY'),
            TRY_TO_DATE(last_modified_date,'DD-MM-YYYY'),
            TRY_TO_DATE(last_modified_date,'MM/DD/YYYY'),
            TRY_TO_DATE(last_modified_date,'DD/MM/YYYY')
        ) AS last_modified_date,
        COALESCE(employee_count,0) AS employee_count,
        COALESCE(current_sales,0) AS current_sales,
        COALESCE(sales_target,0) AS sales_target,
        COALESCE(monthly_rent,0) AS monthly_rent,
        COALESCE(size_sq_ft,0) AS size_sq_ft,
        COALESCE(is_active,FALSE) AS is_active,
        INITCAP(TRIM(street)) AS street,
        INITCAP(TRIM(city)) AS city,
        UPPER(TRIM(state)) AS state,
        UPPER(TRIM(country)) AS country,
        CASE
            WHEN REGEXP_LIKE(TRIM(zip_code),'^[0-9]{5}$')
            THEN TRIM(zip_code)
            ELSE NULL
        END AS zip_code,
        TRIM(weekdays_hours) AS weekdays_hours,
        TRIM(weekends_hours) AS weekends_hours,
        TRIM(holidays_hours) AS holidays_hours,
        services,
        DATEDIFF(year,
            COALESCE(
                TRY_TO_DATE(opening_date,'YYYY-MM-DD'),
                TRY_TO_DATE(opening_date,'MM-DD-YYYY'),
                TRY_TO_DATE(opening_date,'DD-MM-YYYY'),
                TRY_TO_DATE(opening_date,'MM/DD/YYYY'),
                TRY_TO_DATE(opening_date,'DD/MM/YYYY')),CURRENT_DATE()
        ) AS store_age,
        CASE
            WHEN size_sq_ft < 5000 THEN 'Small'
            WHEN size_sq_ft >= 5000 AND size_sq_ft <= 10000 THEN 'Medium'
            WHEN size_sq_ft > 10000 THEN 'Large'
            ELSE NULL
        END AS store_size_category,
        CASE
            WHEN sales_target > 0
            THEN (current_sales / sales_target) * 100
            ELSE NULL
        END AS sales_target_achievement_percentage,
        CASE
            WHEN size_sq_ft > 0
            THEN current_sales / size_sq_ft
            ELSE NULL
        END AS revenue_per_sq_ft,
        CASE
            WHEN employee_count > 0
            THEN current_sales / employee_count
            ELSE NULL
        END AS employee_efficiency,
        CASE
            WHEN sales_target > 0 AND (current_sales / sales_target) * 100 < 90
            THEN TRUE
            ELSE FALSE
        END AS performance_issue_flag,
        _loaded_at,
        _source_file,
        _batch_id
    FROM store_flattened
)

SELECT *
FROM sorted_stores
QUALIFY ROW_NUMBER()OVER ( PARTITION BY store_id ORDER BY last_modified_date DESC) = 1