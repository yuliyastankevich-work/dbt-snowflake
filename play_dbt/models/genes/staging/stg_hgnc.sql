with raw_hgnc AS (
SELECT 
CAST(split_part("hgnc_id",':',2) AS INT) AS hgnc_id,
"symbol" as gene_symbol,
"name" as gene_name,
"locus_group" as locus_group,
"locus_type" as locus_type,
"location" as chr_location,
"alias_symbol" as alias_symbol,
"alias_name" as alias_name,
"prev_symbol" as prev_symbol,
"prev_name" as prev_name,
"gene_group" as gene_group,
CAST("date_symbol_changed" AS DATE) AS date_symbol_changed,
CAST("date_name_changed" AS DATE) AS date_name_changed,
CAST("entrez_id" AS INT) AS entrez_id,
"ensembl_gene_id" AS ensembl_id,
"refseq_accession" AS refseq_id,
"uniprot_ids" AS uniprot_id,
"pubmed_id" AS pubmed_accession,
"omim_id" AS omim_accession, 
"mane_select" AS other_ids

from {{ source('play_source', 'hgnc_table')}}
WHERE "status" = 'Approved')
select * from raw_hgnc