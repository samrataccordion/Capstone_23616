WITH supplier_flattened AS (
    SELECT
        f.value:supplier_id::STRING AS supplier_id,
        f.value:supplier_name::STRING AS supplier_name,
        f.value:supplier_type::STRING AS supplier_type,
        f.value:tax_id::STRING AS tax_id,
        f.value:website::STRING AS website,
        f.value:preferred_carrier::STRING AS preferred_carrier,
        f.value:payment_terms::STRING AS payment_terms,
        f.value:credit_rating::STRING AS credit_rating,
        f.value:is_active::BOOLEAN AS is_active,
        f.value:lead_time_days::NUMBER AS lead_time_days,
        f.value:minimum_order_quantity::NUMBER AS minimum_order_quantity,
        f.value:year_established::NUMBER AS year_established,
        f.value:last_order_date::STRING AS last_order_date,
        f.value:last_modified_date::STRING AS last_modified_date,
        f.value:contact_information.contact_person::STRING AS contact_person,
        f.value:contact_information.email::STRING AS email,
        f.value:contact_information.phone::STRING AS phone,
        f.value:contact_information.address::STRING AS address,
        f.value:contract_details.contract_id::STRING AS contract_id,
        f.value:contract_details.start_date::STRING AS contract_start_date,
        f.value:contract_details.end_date::STRING AS contract_end_date,
        f.value:contract_details.exclusivity::BOOLEAN AS exclusivity,
        f.value:contract_details.renewal_option::BOOLEAN AS renewal_option,
        f.value:performance_metrics.average_delay_days::FLOAT AS average_delay_days,
        f.value:performance_metrics.defect_rate::FLOAT AS defect_rate,
        f.value:performance_metrics.on_time_delivery_rate::FLOAT AS on_time_delivery_rate,
        f.value:performance_metrics.quality_rating::STRING AS quality_rating,
        f.value:performance_metrics.response_time_hours::FLOAT AS response_time_hours,
        f.value:performance_metrics.returns_percentage::FLOAT AS returns_percentage,
        ARRAY_TO_STRING(f.value:categories_supplied,', ') AS categories_supplied,
        _loaded_at,
        _source_file,
        _batch_id
    FROM {{ ref('bronze_supplier') }},
    LATERAL FLATTEN(input => VALUE:suppliers_data) f
),

sorted_suppliers AS (
    SELECT
        TRIM(supplier_id) AS supplier_id,
        INITCAP(TRIM(supplier_name)) AS supplier_name,
        INITCAP(TRIM(supplier_type)) AS supplier_type,
        UPPER(TRIM(tax_id)) AS tax_id,
        LOWER(TRIM(website)) AS website,
        INITCAP(TRIM(preferred_carrier)) AS preferred_carrier,
        TRIM(payment_terms) AS payment_terms,
        UPPER(TRIM(credit_rating)) AS credit_rating,
        COALESCE(is_active,FALSE) AS is_active,
        COALESCE(lead_time_days,0) AS lead_time_days,
        COALESCE(minimum_order_quantity,0)AS minimum_order_quantity,
        year_established,
        COALESCE(
            TRY_TO_TIMESTAMP_TZ(last_modified_date,'YYYY-MM-DD'),
            TRY_TO_TIMESTAMP_TZ(last_modified_date,'MM-DD-YYYY'),
            TRY_TO_TIMESTAMP_TZ(last_modified_date,'DD-MM-YYYY'),
            TRY_TO_TIMESTAMP_TZ(last_modified_date,'MM/DD/YYYY'),
            TRY_TO_TIMESTAMP_TZ(last_modified_date,'DD/MM/YYYY')
        ) AS last_order_date,
        COALESCE(
            TRY_TO_TIMESTAMP_TZ(last_modified_date,'YYYY-MM-DD'),
            TRY_TO_TIMESTAMP_TZ(last_modified_date,'MM-DD-YYYY'),
            TRY_TO_TIMESTAMP_TZ(last_modified_date,'DD-MM-YYYY'),
            TRY_TO_TIMESTAMP_TZ(last_modified_date,'MM/DD/YYYY'),
            TRY_TO_TIMESTAMP_TZ(last_modified_date,'DD/MM/YYYY')
        ) AS last_modified_date,
        INITCAP(TRIM(contact_person))AS contact_person,
        CASE
            WHEN REGEXP_LIKE(LOWER(TRIM(email)),'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
            THEN LOWER(TRIM(email))
            ELSE NULL
        END AS email,
        RIGHT(REGEXP_REPLACE(phone,'[^0-9]',''),10) AS phone,
        TRIM(address) AS address,
        TRIM(contract_id) AS contract_id,
        COALESCE(
            TRY_TO_DATE(last_modified_date,'YYYY-MM-DD'),
            TRY_TO_DATE(last_modified_date,'MM-DD-YYYY'),
            TRY_TO_DATE(last_modified_date,'DD-MM-YYYY'),
            TRY_TO_DATE(last_modified_date,'MM/DD/YYYY'),
            TRY_TO_DATE(last_modified_date,'DD/MM/YYYY')
        ) AS contract_start_date,
        COALESCE(
            TRY_TO_DATE(last_modified_date,'YYYY-MM-DD'),
            TRY_TO_DATE(last_modified_date,'MM-DD-YYYY'),
            TRY_TO_DATE(last_modified_date,'DD-MM-YYYY'),
            TRY_TO_DATE(last_modified_date,'MM/DD/YYYY'),
            TRY_TO_DATE(last_modified_date,'DD/MM/YYYY')
        ) AS contract_end_date,
        COALESCE(exclusivity,FALSE)AS exclusivity,
        COALESCE(renewal_option,FALSE)AS renewal_option,
        COALESCE(average_delay_days,0)AS average_delay_days,
        COALESCE(defect_rate,0)AS defect_rate,
        COALESCE(on_time_delivery_rate,0)AS on_time_delivery_rate,
        INITCAP(TRIM(quality_rating))AS quality_rating,
        COALESCE(response_time_hours,0) AS response_time_hours,
        COALESCE(returns_percentage,0)AS returns_percentage,
        INITCAP(TRIM(categories_supplied))AS categories_supplied,
        _loaded_at,
        _source_file,
        _batch_id
    FROM supplier_flattened
)

SELECT *
FROM sorted_suppliers
QUALIFY ROW_NUMBER()OVER ( PARTITION BY supplier_id ORDER BY last_modified_date DESC, _loaded_at DESC)=1