

with product as (

    select * from {{ ref('silver_product') }} p
    left join {{ ref('silver_supplier') }} s
        on p.supplier_id = s.supplier_id

)

select
    -- Surrogate key: unique per version of the product record
    {{ dbt_utils.generate_surrogate_key(['product_id']) }} as product_key,

    -- Natural key
    product_id,

    -- Descriptive attributes
    product_name,
    category,
    subcategory,
    brand,
    color,
    size,
    unit_price,
    cost_price,
    supplier_name,

from product 
