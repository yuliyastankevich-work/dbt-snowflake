import snowflake.connector
from snowflake.snowpark import Session
import os

# 1. Connect via Snowpark (for DataFrame API usage)
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
    print("Snowpark Session created successfully")
except Exception as e:
    print(e)

# 2. Connect via Python Connector (only for SQL statements written by psycopg2 cursor)
conn = snowflake.connector.connect(
    account = os.getenv("SNOWFLAKE_ACCOUNT"),
    user = os.getenv("SNOWFLAKE_USER"),
    password = os.getenv("SNOWFLAKE_PASSWORD"),
    role = os.getenv("SNOWFLAKE_ROLE"),
    database = os.getenv("SNOWFLAKE_DATABASE"),
    warehouse = os.getenv("SNOWFLAKE_WAREHOUSE"),
    schema = os.getenv("SNOWFLAKE_SCHEMA")
)
print("Connected to: ", session.user)
