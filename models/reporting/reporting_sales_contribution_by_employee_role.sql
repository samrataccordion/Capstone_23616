{{
    config(
        materialized='view',
        schema='reporting'
    )
}}


with fact as (

    select * from {{ ref('fact_sales') }}

),

employee as (

    select
        employee_key,
        role
    from {{ ref('dim_employee') }}

)

select
    e.role,
    count(distinct f.employee_key)                                      as employee_count,
    count(distinct f.order_id)                                          as total_orders,
    sum(f.total_sales_amount)                                           as total_sales_amount,
    sum(f.profit_amount)                                                as total_profit_amount,
    sum(f.total_sales_amount) / nullif(count(distinct f.employee_key), 0) as avg_sales_per_employee
from fact f
left join employee e
    on f.employee_key = e.employee_key
group by e.role
order by total_sales_amount desc