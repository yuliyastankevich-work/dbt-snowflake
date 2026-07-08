WITH primary_table AS (
    SELECT
        hgnc_id,
        ensembl_id,
        gene_symbol,
        alias_symbol,
        prev_symbol
    FROM {{ref('stg_hgnc')}}

),

primary_symbol_table AS (
    SELECT
        hgnc_id,
        ensembl_id,
        gene_symbol,
        'primary' AS source
    FROM primary_table
    WHERE gene_symbol IS NOT NULL and gene_symbol != ''
),

synonym_symbol_table AS (
    SELECT
        hgnc_id,
        ensembl_id,
        TRIM(f.value::STRING) AS gene_symbol,
        'synonym' AS source
    FROM primary_table,
    LATERAL FLATTEN (input => SPLIT(alias_symbol, '|')) f
    WHERE f.value IS NOT NULL and f.value != ''
),

outdated_symbol_table AS (
    SELECT
        hgnc_id,
        ensembl_id,
        TRIM(f.value::STRING) AS gene_symbol,
        'outdated' AS source
    FROM primary_table,
    LATERAL FLATTEN (input => SPLIT(prev_symbol, '|')) f
    WHERE f.value IS NOT NULL and f.value != ''
),
combined_tables AS (
SELECT * FROM primary_symbol_table
UNION ALL
SELECT * FROM synonym_symbol_table
UNION ALL
SELECT * FROM outdated_symbol_table
ORDER BY hgnc_id, gene_symbol),

final_table AS (
    SELECT
        hgnc_id,
        ensembl_id,
        gene_symbol,
        source,
        ROW_NUMBER() OVER (PARTITION BY hgnc_id, gene_symbol ORDER BY 
        CASE
            WHEN source = 'primary' THEN 1
            WHEN source = 'synonym' THEN 2
            WHEN source = 'outdated' THEN 3
            ELSE 4
        END) AS row_num
    FROM combined_tables
)

SELECT 
    hgnc_id,
    ensembl_id,
    gene_symbol,
    source
FROM final_table
WHERE row_num = 1
