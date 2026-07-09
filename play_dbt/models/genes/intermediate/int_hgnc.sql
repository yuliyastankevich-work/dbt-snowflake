SELECT
hgnc_id,
gene_symbol,
gene_name,
locus_group,
locus_type,
chr_location,
case
    when LOWER(chr_location) like 'mitochondrial%' then 'MT'
    when regexp_like(chr_location, '^([0-9]+|X|Y|M|MT)([pq].*|$)')
    then UPPER(regexp_substr(chr_location, '^([0-9]+|X|Y|M|MT)([pq].*|$)', 1, 1, 'i', 1))
    else chr_location
    end as chr,
alias_symbol,
alias_name,
prev_symbol,
prev_name,
gene_group,
date_symbol_changed,
date_name_changed,
entrez_id,
ensembl_id,
refseq_id,
uniprot_id,
pubmed_accession,
omim_accession,
other_ids
FROM {{ ref('stg_hgnc')}}
