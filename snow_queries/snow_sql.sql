select current_database(), current_schema();

show schemas in database PLAY_DB;
create schema if not exists PLAY_SOURCE;
show views in schema PLAY_SHEMA;
drop view if exists PLAY_SHEMA.my_second_dbt_model;
show tables in schema PLAY_SOURCE;
drop schema if exists PLAY_SHEMA_intermediate cascade;

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

show columns in table PLAY_SHEMA.stg_hgnc;

select distinct regexp_substr(chr_location, '^[0-9]+') as chr from PLAY_SHEMA.stg_hgnc;


select distinct regexp_substr(chr_location, '^[A-Za-z]+') as chr from PLAY_SHEMA.stg_hgnc;

select distinct(chr) 
from (select chr_location,
case
    when LOWER(chr_location) like 'mitochondrial%' then 'MT'
    when regexp_like(chr_location, '^([0-9]+|X|Y|M|MT)([pq].*|$)')
    then UPPER(regexp_substr(chr_location, '^([0-9]+|X|Y|M|MT)([pq].*|$)', 1, 1, 'i', 1))
    else chr_location
    end as chr
from PLAY_SHEMA.stg_hgnc
    )
ORDER BY chr;


CREATE TABLE IF NOT EXISTS PLAY_SOURCE.samples (
sample_id STRING,
analysis_id STRING,
disease STRING,
sample_type STRING,
status STRING,
updated_at TIMESTAMP);


INSERT INTO PLAY_SOURCE.samples (sample_id, analysis_id, disease, sample_type, status, updated_at)
VALUES
('SMP-1001', 'ANL-5001', 'Lung Cancer', 'blood', 'analysis', TIMESTAMP '2026-06-01 07:08:47'),
('SMP-1002', 'ANL-5002', 'Lung Cancer', 'FFPE', 'dna_extraction', TIMESTAMP '2026-06-24 01:01:05'),
('SMP-1003', 'ANL-5003', 'Colorectal Cancer', 'blood', 'dna_extraction', TIMESTAMP '2026-05-26 22:41:44'),
('SMP-1004', 'ANL-5004', 'Glioblastoma', 'blood', 'ready', TIMESTAMP '2026-06-05 00:48:51'),
('SMP-1005', 'ANL-5005', 'Breast Cancer', 'FFPE', 'ready', TIMESTAMP '2026-06-13 08:09:13'),
('SMP-1006', 'ANL-5006', 'Leukemia', 'blood', 'dna_extraction', TIMESTAMP '2026-06-18 03:22:54'),
('SMP-1007', 'ANL-5007', 'Leukemia', 'FFPE', 'analysis', TIMESTAMP '2026-05-06 23:29:34'),
('SMP-1008', 'ANL-5008', 'Lung Cancer', 'tissue', 'dna_extraction', TIMESTAMP '2026-06-07 20:39:56'),
('SMP-1009', 'ANL-5009', 'Leukemia', 'FFPE', 'in_progress', TIMESTAMP '2026-05-09 01:42:14'),
('SMP-1010', 'ANL-5010', 'Melanoma', 'blood', 'in_progress', TIMESTAMP '2026-05-13 12:17:29'),
('SMP-1011', 'ANL-5011', 'Leukemia', 'blood', 'analysis', TIMESTAMP '2026-06-15 06:42:17'),
('SMP-1012', 'ANL-5012', 'Lung Cancer', 'FFPE', 'in_progress', TIMESTAMP '2026-07-08 23:15:10'),
('SMP-1013', 'ANL-5013', 'Pancreatic Cancer', 'tissue', 'analysis', TIMESTAMP '2026-05-29 21:20:53'),
('SMP-1014', 'ANL-5014', 'Normal', 'blood', 'dna_extraction', TIMESTAMP '2026-06-10 12:17:04'),
('SMP-1015', 'ANL-5015', 'Colorectal Cancer', 'FFPE', 'analysis', TIMESTAMP '2026-05-28 20:31:25'),
('SMP-1016', 'ANL-5016', 'Pancreatic Cancer', 'blood', 'analysis', TIMESTAMP '2026-05-18 07:47:35'),
('SMP-1017', 'ANL-5017', 'Melanoma', 'FFPE', 'ready', TIMESTAMP '2026-06-21 11:14:08'),
('SMP-1018', 'ANL-5018', 'Pancreatic Cancer', 'blood', 'dna_extraction', TIMESTAMP '2026-05-15 04:40:10'),
('SMP-1019', 'ANL-5019', 'Glioblastoma', 'FFPE', 'dna_extraction', TIMESTAMP '2026-06-19 12:38:29'),
('SMP-1020', 'ANL-5020', 'Melanoma', 'FFPE', 'dna_extraction', TIMESTAMP '2026-05-15 21:56:34'),
('SMP-1021', 'ANL-5021', 'Melanoma', 'FFPE', 'analysis', TIMESTAMP '2026-05-15 09:27:10'),
('SMP-1022', 'ANL-5022', 'Pancreatic Cancer', 'blood', 'analysis', TIMESTAMP '2026-07-04 05:32:58'),
('SMP-1023', 'ANL-5023', 'Lung Cancer', 'FFPE', 'analysis', TIMESTAMP '2026-07-04 19:12:09'),
('SMP-1024', 'ANL-5024', 'Leukemia', 'blood', 'dna_extraction', TIMESTAMP '2026-06-11 15:01:07'),
('SMP-1025', 'ANL-5025', 'Leukemia', 'tissue', 'in_progress', TIMESTAMP '2026-05-08 07:56:36'),
('SMP-1026', 'ANL-5026', 'Lung Cancer', 'blood', 'ready', TIMESTAMP '2026-05-09 17:49:08'),
('SMP-1027', 'ANL-5027', 'Breast Cancer', 'FFPE', 'ready', TIMESTAMP '2026-05-22 08:33:55'),
('SMP-1028', 'ANL-5028', 'Glioblastoma', 'blood', 'in_progress', TIMESTAMP '2026-06-09 12:42:41'),
('SMP-1029', 'ANL-5029', 'Leukemia', 'tissue', 'ready', TIMESTAMP '2026-05-16 07:14:04'),
('SMP-1030', 'ANL-5030', 'Leukemia', 'blood', 'in_progress', TIMESTAMP '2026-05-29 00:04:45'),
('SMP-1031', 'ANL-5031', 'Normal', 'blood', 'dna_extraction', TIMESTAMP '2026-05-05 10:04:32'),
('SMP-1032', 'ANL-5032', 'Colorectal Cancer', 'tissue', 'ready', TIMESTAMP '2026-05-28 17:08:46'),
('SMP-1033', 'ANL-5033', 'Pancreatic Cancer', 'blood', 'ready', TIMESTAMP '2026-06-22 06:06:06'),
('SMP-1034', 'ANL-5034', 'Glioblastoma', 'tissue', 'ready', TIMESTAMP '2026-06-22 14:55:46'),
('SMP-1035', 'ANL-5035', 'Normal', 'FFPE', 'dna_extraction', TIMESTAMP '2026-05-08 12:46:21'),
('SMP-1036', 'ANL-5036', 'Lung Cancer', 'blood', 'in_progress', TIMESTAMP '2026-05-25 17:28:08'),
('SMP-1037', 'ANL-5037', 'Glioblastoma', 'blood', 'analysis', TIMESTAMP '2026-06-29 07:55:59'),
('SMP-1038', 'ANL-5038', 'Lung Cancer', 'tissue', 'dna_extraction', TIMESTAMP '2026-05-07 20:34:53'),
('SMP-1039', 'ANL-5039', 'Normal', 'blood', 'in_progress', TIMESTAMP '2026-05-22 13:31:30'),
('SMP-1040', 'ANL-5040', 'Colorectal Cancer', 'tissue', 'dna_extraction', TIMESTAMP '2026-05-22 12:00:24'),
('SMP-1041', 'ANL-5041', 'Melanoma', 'tissue', 'analysis', TIMESTAMP '2026-06-24 22:46:50'),
('SMP-1042', 'ANL-5042', 'Pancreatic Cancer', 'blood', 'in_progress', TIMESTAMP '2026-06-07 06:03:37'),
('SMP-1043', 'ANL-5043', 'Normal', 'FFPE', 'analysis', TIMESTAMP '2026-05-08 01:37:30'),
('SMP-1044', 'ANL-5044', 'Breast Cancer', 'blood', 'dna_extraction', TIMESTAMP '2026-05-24 02:38:04'),
('SMP-1045', 'ANL-5045', 'Colorectal Cancer', 'tissue', 'dna_extraction', TIMESTAMP '2026-06-01 18:38:02'),
('SMP-1046', 'ANL-5046', 'Lung Cancer', 'tissue', 'analysis', TIMESTAMP '2026-06-03 06:42:45'),
('SMP-1047', 'ANL-5047', 'Leukemia', 'blood', 'analysis', TIMESTAMP '2026-06-20 04:42:41'),
('SMP-1048', 'ANL-5048', 'Melanoma', 'tissue', 'analysis', TIMESTAMP '2026-05-10 00:29:39'),
('SMP-1049', 'ANL-5049', 'Lung Cancer', 'blood', 'in_progress', TIMESTAMP '2026-07-04 08:08:59'),
('SMP-1050', 'ANL-5050', 'Leukemia', 'blood', 'in_progress', TIMESTAMP '2026-06-17 09:10:28'),
('SMP-1051', 'ANL-5051', 'Melanoma', 'FFPE', 'dna_extraction', TIMESTAMP '2026-06-08 21:06:56'),
('SMP-1052', 'ANL-5052', 'Breast Cancer', 'tissue', 'dna_extraction', TIMESTAMP '2026-05-14 23:35:09'),
('SMP-1053', 'ANL-5053', 'Melanoma', 'tissue', 'in_progress', TIMESTAMP '2026-06-13 06:43:40'),
('SMP-1054', 'ANL-5054', 'Melanoma', 'FFPE', 'ready', TIMESTAMP '2026-06-02 01:05:40'),
('SMP-1055', 'ANL-5055', 'Glioblastoma', 'tissue', 'dna_extraction', TIMESTAMP '2026-05-01 10:49:08'),
('SMP-1056', 'ANL-5056', 'Melanoma', 'blood', 'ready', TIMESTAMP '2026-06-24 17:00:07'),
('SMP-1057', 'ANL-5057', 'Lung Cancer', 'FFPE', 'in_progress', TIMESTAMP '2026-05-05 11:37:35'),
('SMP-1058', 'ANL-5058', 'Breast Cancer', 'tissue', 'in_progress', TIMESTAMP '2026-05-06 09:23:57'),
('SMP-1059', 'ANL-5059', 'Normal', 'tissue', 'in_progress', TIMESTAMP '2026-06-01 21:06:22'),
('SMP-1060', 'ANL-5060', 'Glioblastoma', 'FFPE', 'in_progress', TIMESTAMP '2026-05-31 05:51:51'),
('SMP-1061', 'ANL-5061', 'Breast Cancer', 'tissue', 'dna_extraction', TIMESTAMP '2026-05-23 23:59:21'),
('SMP-1062', 'ANL-5062', 'Glioblastoma', 'FFPE', 'in_progress', TIMESTAMP '2026-06-04 05:50:44'),
('SMP-1063', 'ANL-5063', 'Lung Cancer', 'tissue', 'dna_extraction', TIMESTAMP '2026-06-30 07:12:52'),
('SMP-1064', 'ANL-5064', 'Pancreatic Cancer', 'tissue', 'analysis', TIMESTAMP '2026-05-30 07:01:42'),
('SMP-1065', 'ANL-5065', 'Colorectal Cancer', 'tissue', 'analysis', TIMESTAMP '2026-06-05 02:49:17'),
('SMP-1066', 'ANL-5066', 'Leukemia', 'FFPE', 'ready', TIMESTAMP '2026-07-08 10:01:07'),
('SMP-1067', 'ANL-5067', 'Melanoma', 'blood', 'analysis', TIMESTAMP '2026-05-05 03:38:27'),
('SMP-1068', 'ANL-5068', 'Leukemia', 'FFPE', 'analysis', TIMESTAMP '2026-06-25 19:32:07'),
('SMP-1069', 'ANL-5069', 'Glioblastoma', 'FFPE', 'in_progress', TIMESTAMP '2026-06-02 01:45:27'),
('SMP-1070', 'ANL-5070', 'Normal', 'FFPE', 'in_progress', TIMESTAMP '2026-06-16 13:04:42'),
('SMP-1071', 'ANL-5071', 'Leukemia', 'FFPE', 'analysis', TIMESTAMP '2026-05-16 23:57:19'),
('SMP-1072', 'ANL-5072', 'Melanoma', 'FFPE', 'ready', TIMESTAMP '2026-06-11 12:44:18'),
('SMP-1073', 'ANL-5073', 'Breast Cancer', 'blood', 'ready', TIMESTAMP '2026-06-18 21:47:57'),
('SMP-1074', 'ANL-5074', 'Breast Cancer', 'FFPE', 'analysis', TIMESTAMP '2026-06-21 17:53:00'),
('SMP-1075', 'ANL-5075', 'Melanoma', 'tissue', 'in_progress', TIMESTAMP '2026-06-25 18:38:41'),
('SMP-1076', 'ANL-5076', 'Leukemia', 'tissue', 'ready', TIMESTAMP '2026-06-26 21:13:32'),
('SMP-1077', 'ANL-5077', 'Pancreatic Cancer', 'FFPE', 'in_progress', TIMESTAMP '2026-05-11 09:32:42'),
('SMP-1078', 'ANL-5078', 'Leukemia', 'blood', 'in_progress', TIMESTAMP '2026-06-09 07:51:12'),
('SMP-1079', 'ANL-5079', 'Breast Cancer', 'blood', 'dna_extraction', TIMESTAMP '2026-06-01 15:39:54'),
('SMP-1080', 'ANL-5080', 'Lung Cancer', 'tissue', 'ready', TIMESTAMP '2026-05-25 22:44:24'),
('SMP-1081', 'ANL-5081', 'Pancreatic Cancer', 'tissue', 'in_progress', TIMESTAMP '2026-05-19 20:44:00'),
('SMP-1082', 'ANL-5082', 'Lung Cancer', 'tissue', 'in_progress', TIMESTAMP '2026-05-23 22:33:29'),
('SMP-1083', 'ANL-5083', 'Normal', 'FFPE', 'in_progress', TIMESTAMP '2026-05-16 14:08:51'),
('SMP-1084', 'ANL-5084', 'Pancreatic Cancer', 'FFPE', 'analysis', TIMESTAMP '2026-06-26 19:52:46'),
('SMP-1085', 'ANL-5085', 'Glioblastoma', 'FFPE', 'ready', TIMESTAMP '2026-05-21 23:55:30'),
('SMP-1086', 'ANL-5086', 'Pancreatic Cancer', 'tissue', 'in_progress', TIMESTAMP '2026-06-05 16:31:40'),
('SMP-1087', 'ANL-5087', 'Colorectal Cancer', 'tissue', 'ready', TIMESTAMP '2026-05-10 22:18:15'),
('SMP-1088', 'ANL-5088', 'Melanoma', 'tissue', 'analysis', TIMESTAMP '2026-05-11 04:09:14'),
('SMP-1089', 'ANL-5089', 'Glioblastoma', 'FFPE', 'in_progress', TIMESTAMP '2026-05-28 02:26:26'),
('SMP-1090', 'ANL-5090', 'Leukemia', 'FFPE', 'ready', TIMESTAMP '2026-06-23 01:13:53'),
('SMP-1091', 'ANL-5091', 'Glioblastoma', 'tissue', 'dna_extraction', TIMESTAMP '2026-06-18 15:00:22'),
('SMP-1092', 'ANL-5092', 'Melanoma', 'tissue', 'ready', TIMESTAMP '2026-07-08 23:47:34'),
('SMP-1093', 'ANL-5093', 'Colorectal Cancer', 'tissue', 'in_progress', TIMESTAMP '2026-06-04 13:31:01'),
('SMP-1094', 'ANL-5094', 'Glioblastoma', 'tissue', 'ready', TIMESTAMP '2026-05-22 14:58:08'),
('SMP-1095', 'ANL-5095', 'Normal', 'tissue', 'dna_extraction', TIMESTAMP '2026-05-11 20:27:08'),
('SMP-1096', 'ANL-5096', 'Pancreatic Cancer', 'blood', 'dna_extraction', TIMESTAMP '2026-06-03 12:20:13'),
('SMP-1097', 'ANL-5097', 'Pancreatic Cancer', 'tissue', 'analysis', TIMESTAMP '2026-06-18 08:48:53'),
('SMP-1098', 'ANL-5098', 'Glioblastoma', 'tissue', 'dna_extraction', TIMESTAMP '2026-06-30 00:47:34'),
('SMP-1099', 'ANL-5099', 'Normal', 'tissue', 'in_progress', TIMESTAMP '2026-05-09 20:02:48'),
('SMP-1100', 'ANL-5100', 'Normal', 'blood', 'in_progress', TIMESTAMP '2026-05-03 19:09:15');


select distinct disease from PLAY_SOURCE.samples;

select * from play_shema_play_snapshots.mrt_samples
ORDER BY sample_id ASC;

insert into play_source.samples
VALUES ('SMP-1001', 'ANL-5001', 'Lung Cancer', 'blood', 'ready', current_timestamp());

select * from play_source.samples;
