select current_database(), current_schema();

show tables in schema PLAY_SHEMA;

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