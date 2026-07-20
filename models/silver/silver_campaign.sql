WITH campaign_flattened AS (
    SELECT
        f.value:campaign_id::STRING AS campaign_id,
        f.value:campaign_name::STRING AS campaign_name,
        f.value:campaign_type::STRING AS campaign_type,
        f.value:channel::STRING AS channel,
        f.value:description::STRING AS description,
        f.value:target_audience::STRING AS target_audience,
        f.value:start_date::STRING AS start_date,
        f.value:end_date::STRING AS end_date,
        f.value:last_modified_date::STRING AS last_modified_date,
        f.value:budget::STRING AS budget,
        f.value:total_cost::STRING AS total_cost,
        f.value:total_revenue::STRING AS total_revenue,
        f.value:roi_calculation::STRING AS roi_calculation,
         _loaded_at,
        _source_file,
        _batch_id
    FROM {{ ref('bronze_campaign') }}
    ,LATERAL FLATTEN(input => VALUE:campaigns_data) f
),

sorted_campaign AS (
    SELECT
        TRIM(campaign_id) AS campaign_id,
        INITCAP(REGEXP_REPLACE(TRIM(campaign_name),'[^A-Za-z0-9 ]','')) AS campaign_name,
        INITCAP(TRIM(campaign_type))AS campaign_type,
        INITCAP(TRIM(channel))AS channel,
        TRIM(description)AS description,
        TRIM(target_audience)AS target_audience,
        COALESCE(
            TRY_TO_TIMESTAMP_NTZ(start_date),
            TRY_TO_TIMESTAMP_NTZ(start_date,'YYYY-MM-DD"T"HH24:MI:SS'),
            TRY_TO_TIMESTAMP_NTZ(start_date,'MM-DD-YYYY')
        ) AS start_date,
        COALESCE(
            TRY_TO_TIMESTAMP_NTZ(end_date),
            TRY_TO_TIMESTAMP_NTZ(end_date,'YYYY-MM-DD"T"HH24:MI:SS'),
            TRY_TO_TIMESTAMP_NTZ(end_date,'MM-DD-YYYY')
        ) AS end_date,
        COALESCE(
            TRY_TO_DATE(last_modified_date),
            TRY_TO_DATE(last_modified_date,'YYYY-MM-DD'),
            TRY_TO_DATE(last_modified_date,'MM-DD-YYYY'),
            TRY_TO_DATE(last_modified_date,'DD-MM-YYYY'),
            TRY_TO_DATE(last_modified_date,'MM/DD/YYYY'),
            TRY_TO_DATE(last_modified_date,'DD/MM/YYYY')
        ) AS last_modified_date,
        TRY_TO_DECIMAL(REGEXP_REPLACE(budget,'[$,]',''),18,2) AS budget,
        TRY_TO_DECIMAL(REGEXP_REPLACE(total_cost,'[$,]',''),18,2) AS total_cost,
        TRY_TO_DECIMAL(REGEXP_REPLACE(total_revenue,'[$,]',''),18,2) AS total_revenue,
        TRY_TO_DECIMAL(roi_calculation,10,2) AS roi_calculation,
         _loaded_at,
        _source_file,
        _batch_id
    FROM campaign_flattened
)

SELECT *
FROM sorted_campaign
QUALIFY ROW_NUMBER() OVER (PARTITION BY campaign_id ORDER BY last_modified_date DESC) = 1