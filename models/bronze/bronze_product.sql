SELECT
    VALUE,
    CURRENT_TIMESTAMP() AS _loaded_at,
    METADATA$FILENAME AS _source_file,
    '{{ invocation_id }}' AS _batch_id
FROM {{ source('bronze','EX_PRODUCT') }}

{% if is_incremental() %}
WHERE METADATA$FILENAME NOT IN (
    SELECT DISTINCT _source_file
    FROM {{ this }}
)
{% endif %}