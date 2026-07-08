select current_database(), current_schema();
show schemas in database PLAY_DB;
create schema if not exists PLAY_SOURCE;
show views in schema PLAY_SHEMA;
drop view if exists PLAY_SHEMA.my_second_dbt_model;
show tables in schema PLAY_SOURCE;
drop table PLAY_SHEMA.HGNC_TABLE;

select * from PLAY_SHEMA."pets";

list @play_stage;
show stages;

select * from PLAY_SHEMA.HGNC_TABLE
limit 10;

show views in schema PLAY_SHEMA;

select * from PLAY_SHEMA.stg_hgnc
limit 10;

select hgnc_id, ensembl_id, unnest(string_to_array(uniprot_id)) as uniprot_id from PLAY_SHEMA.stg_hgnc
limit 100;

select distinct locus_group from PLAY_SHEMA.stg_hgnc;
select distinct(uniprot_id) from PLAY_SHEMA.stg_hgnc
where locus_group = 'non-coding RNA';

select count(distinct hgnc_id) from PLAY_SHEMA.stg_hgnc
where uniprot_id is null;

WITH expected AS (
    SELECT 
        SUM(COALESCE(ARRAY_SIZE(SPLIT(uniprot_id, '|')), 0)) AS expected_row_count
    FROM PLAY_SHEMA.stg_hgnc
),

actual AS (
    SELECT 
        COUNT(*) AS actual_row_count
    FROM PLAY_SHEMA.int_parsed_uniprot
    WHERE uniprot_id IS NOT NULL          
)

SELECT 
    *
FROM expected 
CROSS JOIN actual
WHERE expected_row_count != actual_row_count ;

select count(hgnc_id) from PLAY_SHEMA.stg_hgnc
where gene_symbol = '';

WITH expected AS (
    SELECT
        SUM(
            CASE
                WHEN gene_symbol IS NOT NULL AND gene_symbol != '' THEN 1
                ELSE 0
                END +
            COALESCE(ARRAY_SIZE(SPLIT(alias_symbol, '|')),0) + 
            COALESCE(ARRAY_SIZE(SPLIT(prev_symbol, '|')),0)
) AS expected_num_symbols
    FROM PLAY_SHEMA.stg_hgnc
),
actual AS (
    SELECT
        COUNT(*) AS actual_num_symbols
    FROM PLAY_SHEMA.int_parsed_gene_names
)
SELECT expected_num_symbols, actual_num_symbols
FROM expected
CROSS JOIN actual
WHERE expected_num_symbols != actual_num_symbols;

SELECT count(distinct gene_symbol) AS distinct_gene_symbols
FROM PLAY_SHEMA.int_parsed_gene_names


WITH array_preparation AS (
    SELECT
        hgnc_id,
        
        -- 1. Put primary symbol into an array (handling nulls)
        CASE 
            WHEN gene_symbol IS NOT NULL AND TRIM(gene_symbol) != '' 
            THEN ARRAY_CONSTRUCT(TRIM(gene_symbol))
            ELSE ARRAY_CONSTRUCT()
        END AS primary_arr,

        -- 2. Split alias into an array and remove internal duplicates
        CASE 
            WHEN alias_symbol IS NOT NULL AND TRIM(alias_symbol) != '' 
            THEN ARRAY_DISTINCT(SPLIT(alias_symbol, '|'))
            ELSE ARRAY_CONSTRUCT()
        END AS alias_arr,

        -- 3. Split prev_symbol into an array and remove internal duplicates
        CASE 
            WHEN prev_symbol IS NOT NULL AND TRIM(prev_symbol) != '' 
            THEN ARRAY_DISTINCT(SPLIT(prev_symbol, '|'))
            ELSE ARRAY_CONSTRUCT()
        END AS prev_arr
    FROM PLAY_SHEMA.stg_hgnc
),

per_gene_counts AS (
    SELECT
        hgnc_id,
        -- Count the primary symbol
        ARRAY_SIZE(primary_arr) AS primary_cnt,
        
        -- Count aliases that are NOT present in the primary array
        ARRAY_SIZE(ARRAY_EXCEPT(alias_arr, primary_arr)) AS unique_alias_cnt,
        
        -- Count outdated symbols that are NOT in primary AND NOT in alias
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
    FROM PLAY_SHEMA.int_parsed_gene_symbols
)

-- Final comparison
SELECT 
    expected_count, 
    actual_count
FROM expected_total
CROSS JOIN actual_total
WHERE expected_count != actual_count;