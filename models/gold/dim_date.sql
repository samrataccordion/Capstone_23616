WITH dates AS (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2024-04-01' as date)",
        end_date="cast('2024-09-28' as date)"
    ) }}

)

SELECT
    TO_NUMBER(TO_CHAR(date_day,'YYYYMMDD')) AS date_key,
    date_day AS full_date,
    YEAR(date_day) AS year,
    QUARTER(date_day) AS quarter,
    MONTH(date_day) AS month,
    WEEK(date_day) AS week,
    DAYNAME(date_day) AS day_of_week,

    CASE
        WHEN MONTH(date_day) IN (12,1,2) THEN 'Winter'
        WHEN MONTH(date_day) IN (3,4,5) THEN 'Spring'
        WHEN MONTH(date_day) IN (6,7,8) THEN 'Summer'
        ELSE 'Fall'
    END AS season,

    CASE
        WHEN MONTH(date_day)=1 AND DAY(date_day)=1 THEN TRUE
        WHEN MONTH(date_day)=7 AND DAY(date_day)=4 THEN TRUE
        WHEN MONTH(date_day)=12 AND DAY(date_day)=25 THEN TRUE
        ELSE FALSE
    END AS holiday_flag

FROM dates
ORDER BY full_date