{{
    config(
        materialized='view',
        schema='reporting'
    )
}}

with fact as (

    select * from {{ ref('fact_sales') }}

),

product as (

    select
        product_key,
        product_id,
        product_name,
        category,
        brand
    from {{ ref('dim_product') }}

),

product_sales as (

    select
        product_key,
        sum(quantity_sold)      as total_quantity_sold,
        sum(total_sales_amount) as total_sales_amount,
        sum(profit_amount)      as total_profit_amount
    from fact
    group by product_key

)

select
    p.product_id,
    p.product_name,
    p.category,
    p.brand,
    ps.total_quantity_sold,
    ps.total_sales_amount,
    ps.total_profit_amount,
    dense_rank() over (order by ps.total_sales_amount desc) as sales_rank
from product_sales ps
left join product p
    on ps.product_key = p.product_key
order by sales_rank