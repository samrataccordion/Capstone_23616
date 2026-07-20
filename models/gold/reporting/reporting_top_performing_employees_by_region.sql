{{
    config(
        materialized='view',
        schema='reporting'
    )
}}

-- Ranks employees by total sales WITHIN their region (partitioned rank), not
-- globally — so each region has its own #1, #2, etc.
-- An employee selling across multiple regions gets one row per region.

with fact as (

    select * from {{ ref('fact_sales') }}

),

employee as (

    select
        employee_key,
        employee_id,
        full_name
    from {{ ref('dim_employee') }}

),

employee_region_sales as (

    select
        employee_key,
        region,
        sum(total_sales_amount)     as total_sales_amount,
        sum(profit_amount)          as total_profit_amount,
        count(distinct order_id)    as total_orders
    from fact
    group by employee_key, region

)

select
    e.employee_id,
    e.full_name,
    ers.region,
    ers.total_orders,
    ers.total_sales_amount,
    ers.total_profit_amount,
    dense_rank() over (partition by ers.region order by ers.total_sales_amount desc) as region_sales_rank
from employee_region_sales ers
left join employee e
    on ers.employee_key = e.employee_key
order by ers.region, region_sales_rank