WITH source_data AS (
SELECT *,
        ROW_NUMBER() OVER(PARTITION BY sample_id ORDER BY updated_at DESC) as deduplicated
FROM {{ source('play_source', 'samples') }}
)
SELECT sample_id, analysis_id, disease, sample_type, status, updated_at
FROM source_data
WHERE deduplicated = 1