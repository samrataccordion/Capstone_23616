{{
    config(
        materialized='view',
        schema='reporting'
    )
}}

with fact as (

    select * from {{ ref('fact_sales') }}

),

customer as (

    select
        customer_key,
        customer_id,
        customer_segment 
    from {{ ref('dim_customer') }}

),

customer_agg as (

    select
        customer_key,
        count(distinct order_id)   as total_orders,
        sum(total_sales_amount)    as total_revenue,
        sum(profit_amount)         as total_profit
    from fact
    group by customer_key

)

select
    c.customer_id,
    c.customer_segment,
    ca.total_orders,
    ca.total_revenue,
    ca.total_profit                                                as customer_lifetime_value,
    case
        when ca.total_orders = 0 then 0
        else ca.total_revenue / ca.total_orders
    end                                                              as avg_order_value
from customer_agg ca
left join customer c
    on ca.customer_key = c.customer_key
order by customer_lifetime_value desc