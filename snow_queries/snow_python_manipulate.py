from snowflake.snowpark import Session
import os

connection_parameters = {
    "account": os.getenv("SNOWFLAKE_ACCOUNT"),
    "user": os.getenv("SNOWFLAKE_USER"),
    "password": os.getenv("SNOWFLAKE_PASSWORD"),
    "role": os.getenv("SNOWFLAKE_ROLE"),
    "warehouse": os.getenv("SNOWFLAKE_WAREHOUSE"),
    "database": os.getenv("SNOWFLAKE_DATABASE"),
    "schema": os.getenv("SNOWFLAKE_SCHEMA")
}

try:
    session = Session.builder.configs(connection_parameters).create()
    if session.get_active_session():

        print("Snowpark Session created successfully")
        print("\nSession details: \n", session.get_active_session())
except Exception as e:
    print(e)

session.sql("CREATE OR REPLACE TABLE small_table (id int, name varchar(50), surname varchar(50), age int)").collect()

# session.commit()

