CREATE OR REPLACE NETWORK RULE hgnc_site
TYPE = HOST_PORT
VALUE_LIST = ('www.genenames.org', 'storage.googleapis.com')
MODE = EGRESS;

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION hgnc_site_integration
ALLOWED_NETWORK_RULES = (hgnc_site)
ENABLED = TRUE;

CREATE OR REPLACE PROCEDURE hgnc_load_proc()
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = "3.10"
PACKAGES = ('snowflake-snowpark-python', 'requests')
EXTERNAL_ACCESS_INTEGRATION = hgnc_site_integration()
HANDLER = 'main'
AS
$$
import io 
import requests

def main(session):
    hgnc_ftp = 'https://storage.googleapis.com/public-download-files/hgnc/tsv/tsv/hgnc_complete_set.txt'
    response = requests.get(hgnc_ftp)

    if response.status_code == 200:
        hgnc_io = io.BytesIO(response.content)
        session.file.put_stream(input_stream = hgnc_io, stage_location = '@PLAY_STAGE/hgnc_complete_set.txt', overwrite = True)
    return print("Successfully loaded the latest HGNC file")
$$
