-------
-- Fin_01_Init.sql
-------

use role useradmin;

create role FIN_DBA;
grant role FIN_DBA to user <YOUR_USERNAME>; -- you need this role to continue set up

create role FIN_BIZ_OWNER;
grant role FIN_BIZ_OWNER to user <YOUR_USERNAME>; -- you need this role to continue set up

create role FIN_BIZ_USER;

create role FIN_POLICY_ADMIN;
grant role FIN_POLICY_ADMin to user <YOUR_USERNAME>; -- you need this role to continue set up

create role FIN_PII_ACCESS;

use role accountadmin;
grant create database on account to role FIN_DBA;
grant create warehouse on account to role FIN_DBA;

-- create the base objects
use role FIN_DBA;
create database FIN_DATA;
grant usage on database FIN_DATA to role FIN_BIZ_OWNER;
grant create schema on database FIN_DATA to role FIN_BIZ_OWNER;
grant usage on database FIN_DATA to role FIN_BIZ_USER;
grant usage on database FIN_DATA to role FIN_POLICY_ADMIN;

create warehouse DATAGOV warehouse_size=small initially_suspended=true auto_suspend = 60 auto_resume = true;
grant usage on warehouse DATAGOV to role FIN_BIZ_OWNER;
grant usage on warehouse DATAGOV to role FIN_BIZ_USER;
grant usage on warehouse DATAGOV to role FIN_POLICY_ADMIN;

use role FIN_BIZ_OWNER;
create schema FIN_DATA.FIN_SCHEMA with managed access;
-- TWO THINGS YOU NEED TO KNOW
-- 1) where is the schema TPCDS_SF100TCL in your Snowflake account? the sample data may have different names.
-- 2) does your Snowflake account grant access to the sample data for all roles? if not, you must grant this to this role. 
use warehouse DATAGOV;
create table FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS as ( select * from  SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.CUSTOMER_DEMOGRAPHICS);
create table FIN_DATA.FIN_SCHEMA.HOUSEHOLD_DEMOGRAPHICS as ( select * from SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.HOUSEHOLD_DEMOGRAPHICS);
create table FIN_DATA.FIN_SCHEMA.INCOME_BAND as ( select * from SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.INCOME_BAND);
