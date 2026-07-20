{% snapshot customer_snapshot %}

{{
    config(
      target_schema='snapshots',
      unique_key='customer_id',
      strategy='check',
      check_cols='all'
    )
}}

select *
from {{ ref('silver_customer') }}
{% endsnapshot %}