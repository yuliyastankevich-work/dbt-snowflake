from snowflake.snowpark import Session
from snowflake.snowpark.functions import sproc
import os

access_params = {
    "account": os.getenv("SNOWFLAKE_ACCOUNT"),
    "user": os.getenv("SNOWFLAKE_USER"),
    "password": os.getenv("SNOWFLAKE_PASSWORD"),
    "role": os.getenv("SNOWFLAKE_ROLE"),
    "warehouse": os.getenv("SNOWFLAKE_WAREHOUSE"),
    "database": os.getenv("SNOWFLAKE_DATABASE"),
    "schema": os.getenv("SNOWFLAKE_SCHEMA")
}
session = Session.builder.config(access_params).create()
if session.get_active_session():
    print("Session created")

session.sql("CREATE OR REPLACE NETWORK RULE hgnc_rule_spr TYPE = HODT_PORT VALUE_LIST = ('www.genenames.org', 'storage.googleapis.com') MODE = EGRESS;").collect()
session.sql("CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION hgnc_int_spr ALLOWED_NETWORK_RULES = (hgnc_rule_spr) ENABLE = TRUE").collect()

@sproc(name = 'LOAD_HGNC_LATEST', return_type = 'str', is_permanent = True, stage_location = "@PLAY_STAGE", replace = True, packages = ['snowflake-snowpark-python', 'requests'], external_access_integrations = ['hgnc_int_spr'])
def load_hgnc_sproc(session:Session) -> str:
    import os
    import io 
    import requests

    hgnc_url = 'https://storage.googleapis.com/public-download-files/hgnc/tsv/tsv/hgnc_complete_set.txt'
    response = requests.get(hgnc_url)

    if response.status_code == 200:
        hgnc_stream = io.BytesIO(response.content)
        session.file.put_stream(input_stream = hgnc_stream, stage_location = "@PLAY_STAGE/hgnc_complete_set.txt", overwrite = True)
        return print("Successfully loaded the newest HGNC complete set to the stage")
    else: print('Failed to load the file to the stage')