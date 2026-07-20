{{
    config(
        materialized='view',
        schema='reporting'
    )
}}

with employee as (

    select
        employee_key,
        employee_id,
        full_name,
        role,
        tenure_years,
        performance_rating,
        target_achievement_percentage
    from {{ ref('dim_employee') }}

),

fact as (

    select * from {{ ref('fact_sales') }}

),

employee_sales as (

    select
        employee_key,
        sum(total_sales_amount)     as total_sales_amount,
        sum(profit_amount)          as total_profit_amount,
        count(distinct order_id)    as total_orders
    from fact
    group by employee_key

)

select
    e.employee_id,
    e.full_name,
    e.role,
    e.tenure_years,
    e.performance_rating,
    e.target_achievement_percentage,
    coalesce(es.total_orders, 0)         as total_orders,
    coalesce(es.total_sales_amount, 0)   as total_sales_amount,
    coalesce(es.total_profit_amount, 0)  as total_profit_amount
from employee e
left join employee_sales es
    on e.employee_key = es.employee_key
order by e.tenure_years desc