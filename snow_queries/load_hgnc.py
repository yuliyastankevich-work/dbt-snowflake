import requests
import os
import io
from snowflake.snowpark import Session

hgnc_url = 'https://storage.googleapis.com/public-download-files/hgnc/tsv/tsv/hgnc_complete_set.txt'

response = requests.get(hgnc_url)

connection_parameters = {
    "account": os.getenv("SNOWFLAKE_ACCOUNT"),
    "user": os.getenv("SNOWFLAKE_USER"),
    "password": os.getenv("SNOWFLAKE_PASSWORD"),
    "role": os.getenv("SNOWFLAKE_ROLE"),
    "warehouse": os.getenv("SNOWFLAKE_WAREHOUSE"),
    "database": os.getenv("SNOWFLAKE_DATABASE")
}

try:
    session = Session.builder.configs(connection_parameters).create()
    if session.get_active_session():

        print("Snowpark Session created successfully")
        print("\nSession details: \n", session.get_active_session())
except Exception as e:
    print(e)

_ = session.sql("USE SCHEMA PLAY_SOURCE").collect()
_ = session.sql("CREATE OR REPLACE STAGE source_stage").collect()

print("\nStart loading the file..")

if response.status_code == 200:
    try:
        file_stream = io.BytesIO(response.content)
        session.file.put_stream(input_stream = file_stream, stage_location = "@SOURCE_STAGE/hgnc_complete_set.txt", overwrite = True)
        hgnc = session.read.options({"FIELD_DELIMITER":"9", "PARSE_HEADER":True, "FIELD_OPTIONALLY_ENCLOSED_BY":'"'}).csv("@SOURCE_STAGE/hgnc_complete_set.txt")
        hgnc_pd = hgnc.to_pandas()
        print("\nThe table contents\n")
        print(hgnc_pd.head())
        print("\nLoading data to the Snowflake dataframe..\n")
        hgnc.write.mode("overwrite").save_as_table("PLAY_SOURCE.HGNC_TABLE")
        print("\nThe table has been loaded")
    except Exception as e:
        print(e)
