WITH product_flattened AS (
    SELECT
        f.value:product_id::STRING AS product_id,
        f.value:name::STRING AS product_name,
        f.value:brand::STRING AS brand,
        f.value:category::STRING AS category,
        f.value:subcategory::STRING AS subcategory,
        f.value:product_line::STRING AS product_line,
        f.value:color::STRING AS color,
        f.value:size::STRING AS size,
        f.value:dimensions::STRING AS dimensions,
        f.value:weight::STRING AS weight,
        f.value:short_description::STRING AS short_description,
        f.value:technical_specs::STRING AS technical_specs,
        f.value:warranty_period::STRING AS warranty_period,
        f.value:supplier_id::STRING AS supplier_id,
        f.value:launch_date::STRING AS launch_date,
        f.value:last_modified_date::STRING AS last_modified_date,
        f.value:cost_price::NUMBER(18,2) AS cost_price,
        f.value:unit_price::NUMBER(18,2) AS unit_price,
        f.value:stock_quantity::NUMBER AS stock_quantity,
        f.value:reorder_level::NUMBER AS reorder_level,
        f.value:is_featured::BOOLEAN AS is_featured

    FROM {{ ref('bronze_product') }},
    LATERAL FLATTEN( input => VALUE:products_data) f
),
sorted_products AS (
    SELECT
        TRIM(product_id) AS product_id,
        INITCAP(REGEXP_REPLACE(TRIM(product_name),'[^A-Za-z0-9 ]','')) AS product_name,
        INITCAP(TRIM(brand)) AS brand,
        INITCAP(TRIM(category)) AS category,
        INITCAP(TRIM(subcategory)) AS subcategory,
        INITCAP(TRIM(product_line)) AS product_line,
        CONCAT(INITCAP(TRIM(category)),' > ',
               INITCAP(TRIM(subcategory)),' > ',
               INITCAP(TRIM(product_line))
        ) AS product_hierarchy,
        INITCAP(TRIM(color)) AS color,
        INITCAP(TRIM(size)) AS size,
        TRIM(dimensions) AS dimensions,
        TRIM(weight) AS weight,
        TRIM(short_description) AS short_description,
        CONCAT(
        INITCAP(REGEXP_REPLACE(TRIM(product_name),'[^A-Za-z0-9 ]','')),' - ',
                TRIM(short_description),' - ',
                TRIM(technical_specs)
        ) AS product_full_description,
        TRIM(technical_specs) AS technical_specs,
        TRIM(warranty_period) AS warranty_period,
        TRIM(supplier_id) AS supplier_id,
        COALESCE(
            TRY_TO_DATE(launch_date,'YYYY-MM-DD'),
            TRY_TO_DATE(launch_date,'MM-DD-YYYY'),
            TRY_TO_DATE(launch_date,'DD-MM-YYYY'),
            TRY_TO_DATE(launch_date,'MM/DD/YYYY'),
            TRY_TO_DATE(launch_date,'DD/MM/YYYY')
        ) AS launch_date,
        COALESCE(
            TRY_TO_DATE(last_modified_date,'YYYY-MM-DD'),
            TRY_TO_DATE(last_modified_date,'MM-DD-YYYY'),
            TRY_TO_DATE(last_modified_date,'DD-MM-YYYY'),
            TRY_TO_DATE(last_modified_date,'MM/DD/YYYY'),
            TRY_TO_DATE(last_modified_date,'DD/MM/YYYY')
        ) AS last_modified_date,
        COALESCE(cost_price,0) AS cost_price,
        COALESCE(unit_price,0) AS unit_price,
        COALESCE(stock_quantity,0) AS stock_quantity,
        COALESCE(reorder_level,0) AS reorder_level,
        COALESCE(is_featured,FALSE) AS is_featured,
        CASE
            WHEN unit_price > 0
            THEN ROUND(((unit_price - cost_price) / unit_price) * 100,2)
            ELSE NULL
        END AS profit_margin_percentage,
        CASE
            WHEN stock_quantity < reorder_level
            THEN TRUE
            ELSE FALSE
        END AS low_stock_flag
    FROM product_flattened
)


SELECT *
FROM sorted_products
QUALIFY ROW_NUMBER()OVER ( PARTITION BY product_id ORDER BY last_modified_date DESC) = 1