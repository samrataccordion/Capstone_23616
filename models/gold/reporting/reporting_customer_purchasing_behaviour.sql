{{
    config(
        materialized='view',
        schema='reporting'
    )
}}

-- ASSUMPTION: dim_customer has customer_key, customer_id — adjust if dim_customer
-- isn't built yet or uses different column names.
--
-- fact_sales is at line-item grain, so orders are collapsed to order grain first
-- (one row per order_id) before aggregating up to the customer level — otherwise
-- order counts and average order value would be inflated by multi-line orders.

with fact as (

    select * from {{ ref('fact_sales') }}

),

date_dim as (

    select
        date_key,
        full_date
    from {{ ref('dim_date') }}

),

customer as (

    select
        customer_key,
        customer_id
    from {{ ref('dim_customer') }}

),

fact_with_date as (

    select
        f.*,
        d.full_date as order_date
    from fact f
    left join date_dim d
        on f.date_key = d.date_key

),

order_level as (

    select
        customer_key,
        order_id,
        min(order_date)         as order_date,
        sum(total_sales_amount) as order_total_sales_amount,
        count(*)                as line_item_count
    from fact_with_date
    group by customer_key, order_id

)

select
    c.customer_id,
    count(distinct ol.order_id)          as total_orders,
    sum(ol.order_total_sales_amount)     as total_lifetime_sales,
    avg(ol.order_total_sales_amount)     as avg_order_value,
    avg(ol.line_item_count)              as avg_items_per_order,
    min(ol.order_date)                   as first_purchase_date,
    max(ol.order_date)                   as last_purchase_date,
    datediff('day', max(ol.order_date), current_date) as days_since_last_purchase
from order_level ol
left join customer c
    on ol.customer_key = c.customer_key
group by c.customer_id