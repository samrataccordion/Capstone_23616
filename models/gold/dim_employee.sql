SELECT
    {{ dbt_utils.generate_surrogate_key(['employee_id']) }} AS employee_key,
    employee_id,
    full_name,
    role,
    work_location,
    DATEDIFF(year, hire_date, CURRENT_DATE()) AS tenure_years,
    email,
    phone,
    performance_rating,
    target_achievement_percentage,
    department,
    employment_status,
FROM {{ ref('silver_employee') }}