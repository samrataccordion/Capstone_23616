{{
    config(
        materialized='view',
        schema='reporting'
    )
}}

-- DESIGN NOTE: this view is at customer grain with an is_repeat_customer flag,
-- rather than pre-aggregating to a single overall rate — that way it can be
-- sliced by segment, region, etc. in your BI tool. To get the overall repeat
-- purchase rate: avg(is_repeat_customer::int) or
-- count(*) filter (where is_repeat_customer) / count(*).

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

customer_orders as (

    select
        customer_key,
        count(distinct order_id) as total_orders
    from fact
    group by customer_key

)

select
    c.customer_id,
    c.customer_segment,
    co.total_orders,
    case
        when co.total_orders > 1 then true
        else false
    end as is_repeat_customer
from customer_orders co
left join customer c
    on co.customer_key = c.customer_key