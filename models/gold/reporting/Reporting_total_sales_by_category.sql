{{
    config(
        materialized='view',
        schema='reporting'
    )
}}

-- Total sales, cost, and profit rolled up by product category / subcategory.

with fact as (

    select * from {{ ref('fact_sales') }}

),

product as (

    select
        product_key,
        category,
        subcategory
    from {{ ref('dim_product') }}

)

select
    p.category,
    p.subcategory,
    sum(f.quantity_sold)       as total_quantity_sold,
    sum(f.total_sales_amount)  as total_sales_amount,
    sum(f.cost_amount)         as total_cost_amount,
    sum(f.profit_amount)       as total_profit_amount
from fact f
left join product p
    on f.product_key = p.product_key
group by p.category, p.subcategory
order by total_sales_amount desc