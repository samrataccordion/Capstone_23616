with store as (

    select * from {{ ref('silver_store') }}

)

select
    {{ dbt_utils.generate_surrogate_key(['store_id']) }} as store_key,

    -- Natural key
    store_id,

    -- Descriptive attributes
    store_name,
    street,
    city,
    state,
    country,
    zip_code,
    region,
    store_type,
    opening_date,
    store_size_category as size_category

from store