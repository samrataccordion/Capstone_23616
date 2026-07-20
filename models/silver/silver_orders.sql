WITH order_flattened AS (
    SELECT
        f.value:order_id::STRING AS order_id,
        f.value:customer_id::STRING AS customer_id,
        f.value:employee_id::STRING AS employee_id,
        f.value:store_id::STRING AS store_id,
        f.value:campaign_id::STRING AS campaign_id,
        f.value:order_date::STRING AS order_date,
        f.value:created_at::STRING AS created_at,
        f.value:shipping_date::STRING AS shipping_date,
        f.value:estimated_delivery_date::STRING AS estimated_delivery_date,
        f.value:delivery_date::STRING AS delivery_date,
        f.value:order_status::STRING AS order_status,
        f.value:order_source::STRING AS order_source,
        f.value:payment_method::STRING AS payment_method,
        f.value:shipping_method::STRING AS shipping_method,
        f.value:shipping_cost::NUMBER(18,2) AS shipping_cost,
        f.value:tax_amount::NUMBER(18,2) AS tax_amount,
        f.value:discount_amount::NUMBER(18,2) AS discount_amount,
        f.value:total_amount::NUMBER(18,2) AS total_amount,
        f.value:billing_address.street::STRING AS billing_street,
        f.value:billing_address.city::STRING AS billing_city,
        f.value:billing_address.state::STRING AS billing_state,
        f.value:billing_address.zip_code::STRING AS billing_zip,
        f.value:shipping_address.street::STRING AS shipping_street,
        f.value:shipping_address.city::STRING AS shipping_city,
        f.value:shipping_address.state::STRING AS shipping_state,
        f.value:shipping_address.zip_code::STRING AS shipping_zip,
        i.value:product_id::STRING AS product_id,
        i.value:quantity::NUMBER AS quantity,
        i.value:unit_price::NUMBER(18,2) AS unit_price,
        i.value:cost_price::NUMBER(18,2) AS cost_price,
        i.value:discount_amount::NUMBER(18,2) AS item_discount_amount,
        _loaded_at,
        _source_file,
        _batch_id
    FROM {{ ref('bronze_orders') }},
         LATERAL FLATTEN(input => VALUE:orders_data) f,
         LATERAL FLATTEN(input => f.value:order_items) i
),
sorted_orders AS (
    SELECT
        TRIM(order_id) AS order_id,
        TRIM(customer_id) AS customer_id,
        TRIM(employee_id) AS employee_id,
        TRIM(store_id) AS store_id,
        TRIM(campaign_id) AS campaign_id,
        COALESCE(
            TRY_TO_TIMESTAMP_TZ(order_date,'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            TRY_TO_TIMESTAMP_TZ(order_date,'YYYY-MM-DD"T"HH24:MI:SS'),
            TRY_TO_TIMESTAMP_TZ(order_date,'MM-DD-YYYY HH24:MI:SS'),
            TRY_TO_TIMESTAMP_TZ(order_date,'DD-MM-YYYY HH24:MI:SS'),
            TRY_TO_TIMESTAMP_TZ(order_date,'MM/DD/YYYY HH24:MI:SS')
        ) AS order_date,
        COALESCE(
            TRY_TO_TIMESTAMP_TZ(created_at,'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            TRY_TO_TIMESTAMP_TZ(created_at,'YYYY-MM-DD"T"HH24:MI:SS'),
            TRY_TO_TIMESTAMP_TZ(created_at,'MM-DD-YYYY HH24:MI:SS'),
            TRY_TO_TIMESTAMP_TZ(created_at,'DD-MM-YYYY HH24:MI:SS'),
            TRY_TO_TIMESTAMP_TZ(created_at,'MM/DD/YYYY HH24:MI:SS')
        ) AS created_at,
        COALESCE(
            TRY_TO_TIMESTAMP_TZ(shipping_date,'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            TRY_TO_TIMESTAMP_TZ(shipping_date,'YYYY-MM-DD"T"HH24:MI:SS'),
            TRY_TO_TIMESTAMP_TZ(shipping_date,'MM-DD-YYYY HH24:MI:SS'),
            TRY_TO_TIMESTAMP_TZ(shipping_date,'DD-MM-YYYY HH24:MI:SS'),
            TRY_TO_TIMESTAMP_TZ(shipping_date,'MM/DD/YYYY HH24:MI:SS')
        ) AS shipping_date,
        COALESCE(
            TRY_TO_TIMESTAMP_TZ(estimated_delivery_date,'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            TRY_TO_TIMESTAMP_TZ(estimated_delivery_date,'YYYY-MM-DD"T"HH24:MI:SS'),
            TRY_TO_TIMESTAMP_TZ(estimated_delivery_date,'MM-DD-YYYY HH24:MI:SS'),
            TRY_TO_TIMESTAMP_TZ(estimated_delivery_date,'DD-MM-YYYY HH24:MI:SS'),
            TRY_TO_TIMESTAMP_TZ(estimated_delivery_date,'MM/DD/YYYY HH24:MI:SS')
        ) AS estimated_delivery_date,
        COALESCE(
            TRY_TO_TIMESTAMP_TZ(delivery_date,'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            TRY_TO_TIMESTAMP_TZ(delivery_date,'YYYY-MM-DD"T"HH24:MI:SS'),
            TRY_TO_TIMESTAMP_TZ(delivery_date,'MM-DD-YYYY HH24:MI:SS'),
            TRY_TO_TIMESTAMP_TZ(delivery_date,'DD-MM-YYYY HH24:MI:SS'),
            TRY_TO_TIMESTAMP_TZ(delivery_date,'MM/DD/YYYY HH24:MI:SS')
        ) AS delivery_date,
        INITCAP(TRIM(order_status)) AS order_status,
        INITCAP(TRIM(order_source)) AS order_source,
        INITCAP(TRIM(payment_method)) AS payment_method,
        INITCAP(TRIM(shipping_method)) AS shipping_method,
        COALESCE(shipping_cost,0) AS shipping_cost,
        COALESCE(tax_amount,0) AS tax_amount,
        COALESCE(discount_amount,0) AS discount_amount,
        COALESCE(total_amount,0) AS total_amount,
        TRIM(product_id) AS product_id,
        COALESCE(quantity,0) AS quantity,
        COALESCE(unit_price,0) AS unit_price,
        COALESCE(cost_price,0) AS cost_price,
        COALESCE(item_discount_amount,0) AS item_discount_amount,
        (quantity * unit_price) - COALESCE(item_discount_amount,0)
            AS line_revenue,
        quantity * cost_price
            AS line_cost,
        INITCAP(TRIM(billing_street)) AS billing_street,
        INITCAP(TRIM(billing_city)) AS billing_city,
        UPPER(TRIM(billing_state)) AS billing_state,
        TRIM(billing_zip) AS billing_zip,
        INITCAP(TRIM(shipping_street)) AS shipping_street,
        INITCAP(TRIM(shipping_city)) AS shipping_city,
        UPPER(TRIM(shipping_state)) AS shipping_state,
        TRIM(shipping_zip) AS shipping_zip,
        _loaded_at,
        _source_file,
        _batch_id
    FROM order_flattened
),

order_metrics AS (
    SELECT
        order_id,
        COUNT(DISTINCT product_id) AS total_items,
        SUM(quantity) AS total_quantity,
        SUM(line_revenue) AS order_total_amount,
        SUM(line_cost) AS order_total_cost,
        SUM(item_discount_amount) AS total_discount,
        SUM(line_revenue) AS line_revenue,
        SUM(line_cost) AS line_cost
    FROM sorted_orders
    GROUP BY order_id
)
SELECT
    s.*,
    m.total_items,
    m.total_quantity,
    m.order_total_amount,
    m.order_total_cost,
    m.total_discount,
    WEEK(s.order_date) AS order_week,
    MONTH(s.order_date) AS order_month,
    QUARTER(s.order_date) AS order_quarter,
    YEAR(s.order_date) AS order_year,
    DATEDIFF(day, s.order_date, s.shipping_date) AS processing_days,
    DATEDIFF(day, s.shipping_date, s.delivery_date) AS shipping_days,
    DATEDIFF(day, s.order_date, s.delivery_date) AS delivery_days,
    CASE
        WHEN EXTRACT(HOUR FROM s.order_date) BETWEEN 5 AND 11
            THEN 'Morning'
        WHEN EXTRACT(HOUR FROM s.order_date) BETWEEN 12 AND 16
            THEN 'Afternoon'
        WHEN EXTRACT(HOUR FROM s.order_date) BETWEEN 17 AND 21
            THEN 'Evening'
        ELSE 'Night'
    END AS order_time_of_day,
    CASE
        WHEN s.delivery_date IS NOT NULL
             AND s.delivery_date <= s.estimated_delivery_date
            THEN 'On Time'
        WHEN s.delivery_date IS NOT NULL
             AND s.delivery_date > s.estimated_delivery_date
            THEN 'Delayed'
        WHEN s.delivery_date IS NULL
             AND CURRENT_DATE() > CAST(s.estimated_delivery_date AS DATE)
            THEN 'Potentially Delayed'
        ELSE 'In Transit'
    END AS delivery_status,
    m.line_revenue
        - m.line_cost
        - s.shipping_cost
        - s.tax_amount
        - s.discount_amount
        AS profit_amount,
    CASE
        WHEN m.line_revenue > 0
        THEN ROUND(
            (
                m.line_revenue
                - m.line_cost
                - s.shipping_cost
                - s.tax_amount
                - s.discount_amount
            ) / m.line_revenue * 100
        ,2)
        ELSE NULL
    END AS profit_margin_percentage
FROM sorted_orders s
LEFT JOIN order_metrics m
    ON s.order_id = m.order_id
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY s.order_id, s.product_id
    ORDER BY s.created_at DESC,
             s._loaded_at DESC,
             s._source_file DESC) = 1