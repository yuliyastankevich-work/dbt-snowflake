WITH array_preparation AS (
    SELECT
        hgnc_id,
        CASE 
            WHEN gene_symbol IS NOT NULL AND TRIM(gene_symbol) != '' 
            THEN ARRAY_CONSTRUCT(TRIM(gene_symbol))
            ELSE ARRAY_CONSTRUCT()
        END AS primary_arr,

        CASE 
            WHEN alias_symbol IS NOT NULL AND TRIM(alias_symbol) != '' 
            THEN ARRAY_DISTINCT(SPLIT(alias_symbol, '|'))
            ELSE ARRAY_CONSTRUCT()
        END AS alias_arr,

        CASE 
            WHEN prev_symbol IS NOT NULL AND TRIM(prev_symbol) != '' 
            THEN ARRAY_DISTINCT(SPLIT(prev_symbol, '|'))
            ELSE ARRAY_CONSTRUCT()
        END AS prev_arr
    FROM {{ ref('stg_hgnc') }}
),

per_gene_counts AS (
    SELECT
        hgnc_id,
        ARRAY_SIZE(primary_arr) AS primary_cnt,
        ARRAY_SIZE(ARRAY_EXCEPT(alias_arr, primary_arr)) AS unique_alias_cnt,
        ARRAY_SIZE(
            ARRAY_EXCEPT(
                ARRAY_EXCEPT(prev_arr, primary_arr),
                alias_arr
            )
        ) AS unique_prev_cnt
    FROM array_preparation
),

expected_total AS (
    SELECT 
        SUM(primary_cnt + unique_alias_cnt + unique_prev_cnt) AS expected_count
    FROM per_gene_counts
),

actual_total AS (
    SELECT 
        COUNT(*) AS actual_count
    FROM {{ ref('int_parsed_gene_names') }}
)

SELECT 
    expected_count, 
    actual_count
FROM expected_total
CROSS JOIN actual_total
WHERE expected_count != actual_count