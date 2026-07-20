{{
    config(
        materialized='view',
        schema='reporting'
    )
}}

-- Monthly sales trend, sliced by region (sourced from fact_sales, denormalized from DIM_Store).

with fact as (

    select * from {{ ref('fact_sales') }}

),

date_dim as (

    select
        date_key,
        year,
        month
    from {{ ref('dim_date') }}

)

select
    f.region,
    d.year,
    d.month,
    sum(f.total_sales_amount)          as total_sales_amount,
    sum(f.profit_amount)               as total_profit_amount,
    count(distinct f.order_id)         as order_count
from fact f
left join date_dim d
    on f.date_key = d.date_key
group by f.region, d.year, d.month
order by f.region, d.year, d.month