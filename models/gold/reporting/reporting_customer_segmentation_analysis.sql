{{
    config(
        materialized='view',
        schema='reporting'
    )
}}

-- Uses fact_sales.customer_segment_impact directly (already denormalized from
-- DIM_Customer.segment at fact build time), so no extra join to dim_customer
-- is needed for this one.

with fact as (

    select * from {{ ref('fact_sales') }}

)

select
    customer_segment_impact                                    as segment,
    count(distinct customer_key)                                as customer_count,
    count(distinct order_id)                                    as total_orders,
    sum(total_sales_amount)                                     as total_revenue,
    sum(profit_amount)                                          as total_profit,
    sum(total_sales_amount) / nullif(count(distinct customer_key), 0) as avg_revenue_per_customer,
    sum(profit_amount) / nullif(count(distinct customer_key), 0)      as avg_profit_per_customer
from fact
group by customer_segment_impact
order by total_revenue desc