-------
-- Corp_07_Alation_Catalog_Lineage.sql
-------

-- using Alation Catalog and Lineage to meet many of the CDMC controls most notably:
-- -- CDMC v1.0 Capability 2.1 Control 5 Test Criteria [All]
-- -- CDMC v1.0 Capability 2.2 Control 6 Test Criteria [All]
-- -- CDMC v1.0 Capability 4.2 Control 10 Test Criteria [All]
-- -- CDMC v1.0 Capability 6.1 Control 13 Test Criteria [All]

use role useradmin;
create user ALATION_SVC must_change_password = true; 
-- the log in for Alartion supports username/password only today
-- you will need to ALTER this user with a proper password before this will function
create role ALATION_SVC_ROLE;
grant role ALATION_SVC_ROLE to user alation_svc;
alter user ALATION_SVC set DEFAULT_WAREHOUSE=DATAGOV;
alter user ALATION_SVC set DEFAULT_ROLE=ALATION_SVC_ROLE;

use role CORP_DBA;
grant usage on warehouse DATAGOV to role ALATION_SVC_ROLE;
grant monitor on warehouse DATAGOV to role ALATION_SVC_ROLE;
grant usage on database CORP_DATA to role ALATION_SVC_ROLE;

use role CORP_BIZ_OWNER;
grant usage on schema CORP_DATA.CORP_SCHEMA to role ALATION_SVC_ROLE;
grant usage on future schemas in database CORP_DATA to role ALATION_SVC_ROLE;
grant select on all tables in schema CORP_DATA.CORP_SCHEMA to role ALATION_SVC_ROLE;
grant select on future tables in schema CORP_DATA.CORP_SCHEMA to role ALATION_SVC_ROLE;
grant select on all views in schema CORP_DATA.CORP_SCHEMA to role ALATION_SVC_ROLE;
grant select on future views in schema CORP_DATA.CORP_SCHEMA to role ALATION_SVC_ROLE;

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
