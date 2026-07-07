select current_database(), current_schema();

show tables in schema PLAY_SHEMA;

select * from PLAY_SHEMA."pets";

list @play_stage;
show stages;

select * from PLAY_SHEMA.HGNC_TABLE
limit 10;

show views in schema PLAY_SHEMA;

select * from PLAY_SHEMA.stg_hgnc
limit 10;