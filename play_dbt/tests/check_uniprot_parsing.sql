WITH expected AS (
    SELECT 
        SUM(COALESCE(ARRAY_SIZE(SPLIT(uniprot_id, '|')), 0)) AS expected_row_count
    FROM {{ ref('stg_hgnc') }}
),

actual AS (
    SELECT 
        COUNT(*) AS actual_row_count
    FROM {{ ref('int_parsed_uniprot') }}
    WHERE uniprot_id IS NOT NULL          
)

SELECT 
    *
FROM expected 
CROSS JOIN actual
WHERE expected_row_count != actual_row_count