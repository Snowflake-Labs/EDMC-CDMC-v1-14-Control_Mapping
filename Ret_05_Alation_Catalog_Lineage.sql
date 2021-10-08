-------
-- Ret_05_Alation_Catalog_Lineage.sql
-------

-- set up Alation use
use role useradmin;
create user ALATION_SVC must_change_password = true; 
-- the log in for Alartion supports username/password only today
-- you will need to ALTER this user with a proper password before this will function
create role ALATION_SVC_ROLE;
grant role ALATION_SVC_ROLE to user ALATION_SVC;
alter user ALATION_SVC set default_warehouse=DATAGOV;
alter user ALATION_SVC set default_role=ALATION_SVC_ROLE;

use role RET_DBA;
grant usage on warehouse DATAGOV to role ALATION_SVC_ROLE;
grant monitor on warehouse DATAGOV to role ALATION_SVC_ROLE;
grant usage on database corp_data to role ALATION_SVC_ROLE;

use role RET_BIZ_OWNER;
grant usage on schema RET_DATA.RET_SCHEMA to role ALATION_SVC_ROLE;
grant usage on future schemas in database RET_DATA to role ALATION_SVC_ROLE;
grant select on all tables in schema RET_DATA.RET_SCHEMA to role ALATION_SVC_ROLE;
grant select on future tables in schema RET_DATA.RET_SCHEMA to role ALATION_SVC_ROLE;
grant select on all views in schema RET_DATA.RET_SCHEMA to role ALATION_SVC_ROLE;
grant select on future views in schema RET_DATA.RET_SCHEMA to role ALATION_SVC_ROLE;

use role accountadmin;
create database METADATA_DB;
create schema METADATA_DB.METADATA_SCHEMA;
create view METADATA_DB.METADATA_SCHEMA.POLICY_REFERENCES as select * from SNOWFLAKE.ACCOUNT_USAGE.POLICY_REFERENCES;
create view METADATA_DB.METADATA_SCHEMA.MASKING_POLICIES as select * from SNOWFLAKE.ACCOUNT_USAGE.MASKING_POLICIES;
create view METADATA_DB.METADATA_SCHEMA.ROW_ACCESS_POLICIES as select * from SNOWFLAKE.ACCOUNT_USAGE.ROW_ACCESS_POLICIES;
grant usage on database METADATA_DB to role ALATION_SVC_ROLE;
grant usage on schema METADATA_DB.METADATA_SCHEMA to role ALATION_SVC_ROLE;
grant select on METADATA_DB.METADATA_SCHEMA.POLICY_REFERENCES to role ALATION_SVC_ROLE;
grant select on METADATA_DB.METADATA_SCHEMA.MASKING_POLICIES to role ALATION_SVC_ROLE;
grant select on METADATA_DB.METADATA_SCHEMA.ROW_ACCESS_POLICIES to role ALATION_SVC_ROLE;
