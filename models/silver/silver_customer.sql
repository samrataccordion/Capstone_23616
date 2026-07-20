WITH customer_flattened AS (
    SELECT
        f.value:customer_id::STRING AS customer_id,
        f.value:first_name::STRING AS first_name,
        f.value:last_name::STRING AS last_name,
        f.value:email::STRING AS email,
        f.value:phone::STRING AS phone,
        f.value:birth_date::STRING AS birth_date,
        f.value:registration_date::STRING AS registration_date,
        f.value:last_purchase_date::STRING AS last_purchase_date,
        f.value:last_modified_date::STRING AS last_modified_date,
        f.value:income_bracket::STRING AS income_bracket,
        f.value:loyalty_tier::STRING AS loyalty_tier,
        f.value:occupation::STRING AS occupation,
        f.value:preferred_communication::STRING AS preferred_communication,
        f.value:preferred_payment_method::STRING AS preferred_payment_method,
        f.value:marketing_opt_in::BOOLEAN AS marketing_opt_in,
        f.value:total_purchases::NUMBER AS total_purchases,
        f.value:total_spend::NUMBER(18,2) AS total_spend,
        f.value:address.street::STRING AS street,
        f.value:address.city::STRING AS city,
        f.value:address.state::STRING AS state,
        f.value:address.country::STRING AS country,
        f.value:address.zip_code::STRING AS zip_code,
        _loaded_at,
        _source_file,
        _batch_id
    FROM {{ ref('bronze_customer') }},
    LATERAL FLATTEN(input => VALUE:customers_data) f
),

sorted_customer AS (
    SELECT
        TRIM(customer_id) AS customer_id,
        INITCAP(REGEXP_REPLACE(TRIM(first_name),'[^A-Za-z ]','')) AS first_name,
        INITCAP(REGEXP_REPLACE(TRIM(last_name),'[^A-Za-z ]','')) AS last_name,
        CONCAT(INITCAP(REGEXP_REPLACE(TRIM(first_name),'[^A-Za-z ]','')),' ',
              INITCAP(REGEXP_REPLACE(TRIM(last_name),'[^A-Za-z ]',''))) AS full_name,
        CASE
            WHEN REGEXP_LIKE(LOWER(TRIM(email)),'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
            THEN LOWER(TRIM(email))
            ELSE 'INVALID'
        END AS email,
        CASE
            WHEN LENGTH(REGEXP_REPLACE(UPPER(phone),'[^0-9X]','')) = 10
            THEN REGEXP_REPLACE(UPPER(phone),'[^0-9X]','')
            ELSE 'INVALID'
        END AS phone,
        COALESCE(
            TRY_TO_DATE(birth_date,'YYYY-MM-DD'),
            TRY_TO_DATE(birth_date,'MM-DD-YYYY'),
            TRY_TO_DATE(birth_date,'DD-MM-YYYY'),
            TRY_TO_DATE(birth_date,'MM/DD/YYYY'),
            TRY_TO_DATE(birth_date,'DD/MM/YYYY')
        ) AS birth_date,
        COALESCE(
            TRY_TO_DATE(registration_date,'YYYY-MM-DD'),
            TRY_TO_DATE(registration_date,'MM-DD-YYYY'),
            TRY_TO_DATE(registration_date,'DD-MM-YYYY'),
            TRY_TO_DATE(registration_date,'MM/DD/YYYY'),
            TRY_TO_DATE(registration_date,'DD/MM/YYYY')
        ) AS registration_date,
        COALESCE(
            TRY_TO_DATE(last_purchase_date,'YYYY-MM-DD'),
            TRY_TO_DATE(last_purchase_date,'MM-DD-YYYY'),
            TRY_TO_DATE(last_purchase_date,'DD-MM-YYYY'),
            TRY_TO_DATE(last_purchase_date,'MM/DD/YYYY'),
            TRY_TO_DATE(last_purchase_date,'DD/MM/YYYY')
        ) AS last_purchase_date,
        COALESCE(
            TRY_TO_DATE(last_modified_date,'YYYY-MM-DD'),
            TRY_TO_DATE(last_modified_date,'MM-DD-YYYY'),
            TRY_TO_DATE(last_modified_date,'DD-MM-YYYY'),
            TRY_TO_DATE(last_modified_date,'MM/DD/YYYY'),
            TRY_TO_DATE(last_modified_date,'DD/MM/YYYY')
        ) AS last_modified_date,
        DATEDIFF(YEAR,
            COALESCE(
                TRY_TO_DATE(birth_date,'YYYY-MM-DD'),
                TRY_TO_DATE(birth_date,'MM-DD-YYYY'),
                TRY_TO_DATE(birth_date,'DD-MM-YYYY'),
                TRY_TO_DATE(birth_date,'MM/DD/YYYY'),
                TRY_TO_DATE(birth_date,'DD/MM/YYYY')),
            CURRENT_DATE()) AS customer_age,
        CASE
            WHEN DATEDIFF(YEAR,
                    COALESCE(
                        TRY_TO_DATE(birth_date,'YYYY-MM-DD'),
                        TRY_TO_DATE(birth_date,'MM-DD-YYYY'),
                        TRY_TO_DATE(birth_date,'DD-MM-YYYY'),
                        TRY_TO_DATE(birth_date,'MM/DD/YYYY'),
                        TRY_TO_DATE(birth_date,'DD/MM/YYYY')
                    ),CURRENT_DATE()) BETWEEN 18 AND 35
            THEN 'Young'
            WHEN DATEDIFF(
                    YEAR,
                    COALESCE(
                        TRY_TO_DATE(birth_date,'YYYY-MM-DD'),
                        TRY_TO_DATE(birth_date,'MM-DD-YYYY'),
                        TRY_TO_DATE(birth_date,'DD-MM-YYYY'),
                        TRY_TO_DATE(birth_date,'MM/DD/YYYY'),
                        TRY_TO_DATE(birth_date,'DD/MM/YYYY')
                    ),CURRENT_DATE()) BETWEEN 36 AND 55
            THEN 'Middle-aged'
            WHEN DATEDIFF(YEAR,
                    COALESCE(
                        TRY_TO_DATE(birth_date,'YYYY-MM-DD'),
                        TRY_TO_DATE(birth_date,'MM-DD-YYYY'),
                        TRY_TO_DATE(birth_date,'DD-MM-YYYY'),
                        TRY_TO_DATE(birth_date,'MM/DD/YYYY'),
                        TRY_TO_DATE(birth_date,'DD/MM/YYYY')
                    ),CURRENT_DATE()) >= 56
            THEN 'Senior'
            ELSE 'Unknown'
        END AS customer_segment,
        UPPER(TRIM(income_bracket)) AS income_bracket,
        UPPER(TRIM(loyalty_tier)) AS loyalty_tier,
        INITCAP(TRIM(occupation)) AS occupation,
        INITCAP(TRIM(preferred_communication)) AS preferred_communication,
        INITCAP(TRIM(preferred_payment_method)) AS preferred_payment_method,
        COALESCE(marketing_opt_in,FALSE) AS marketing_opt_in,
        COALESCE(total_purchases,0) AS total_purchases,
        COALESCE(total_spend,0) AS total_spend,
        INITCAP(TRIM(street)) AS street,
        INITCAP(TRIM(city)) AS city,
        UPPER(TRIM(state)) AS state,
        UPPER(TRIM(country)) AS country,
        TRIM(zip_code) AS zip_code,
        CONCAT(INITCAP(TRIM(street)),', ',
               INITCAP(TRIM(city)),', ',
               UPPER(TRIM(state)),' ',
               TRIM(zip_code),', ',
               UPPER(TRIM(country))) AS full_address,
        _loaded_at,
        _source_file,
        _batch_id
    FROM customer_flattened
)

SELECT *
FROM sorted_customer
QUALIFY ROW_NUMBER()OVER ( PARTITION BY customer_id ORDER BY last_modified_date DESC) = 1