import io
import requests
import pandas as pd

assembly_report_ftp = 'https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.40_GRCh38.p14/GCF_000001405.40_GRCh38.p14_assembly_report.txt'
output_file = '/workspaces/dbt-snowflake/play_dbt/seeds/assembly_report.csv'

print("\nStart loading the file..")

response = requests.get(assembly_report_ftp)
if response.status_code == 200:
    try:
        table = pd.read_csv(io.StringIO(response.content.decode('utf-8')), sep='\t', comment='#', header=None)
        column_names = [' Sequence_name',	'Sequence_role',	'Assigned_molecule',	'Assigned_molecule_location',	'GenBank_name',	'Relationship',
                        'RefSeq_name',	'Assembly_unit',	'Sequence_length',	'UCSC_name']
        table.columns = column_names
        table.to_csv(output_file, index=False)
        print(f"Successfully loaded the file to the path: {output_file}")
    except Exception as e:
        print("Failed to load the file!")
        print(e)
else:
    print("Failed to download the file!")