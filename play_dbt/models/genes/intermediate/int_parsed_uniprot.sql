SELECT 
hgnc_id,
ensembl_id,
locus_group,
f.value::STRING AS uniprot_id
FROM {{ref('stg_hgnc')}},
LATERAL FLATTEN (input => split(uniprot_id, '|'), OUTER => TRUE) f