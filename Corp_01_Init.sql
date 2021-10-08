-------
-- Corp_01_Init.sql
-------

use role useradmin;

create role CORP_DBA;
grant role CORP_DBA to user <YOUR_USERNAME>; -- you need this role to continue set up

create role CORP_BIZ_OWNER;
grant role CORP_BIZ_OWNER to user <YOUR_USERNAME>; -- you need this role to continue set up

create role CORP_BIZ_USER;

create role CORP_POLICY_ADMIN;
grant role CORP_POLICY_ADMIN to user <YOUR_USERNAME>; -- you need this role to continue set up

use role accountadmin;
grant create database on account to role CORP_DBA;
grant create warehouse on account to role CORP_DBA;

-- create the base objects
use role CORP_DBA;
create database CORP_DATA;
grant usage on database CORP_DATA to role CORP_BIZ_OWNER;
grant create schema on database CORP_DATA to role CORP_BIZ_OWNER;
grant usage on database CORP_DATA to role CORP_BIZ_USER;
grant usage on database CORP_DATA to role CORP_POLICY_ADMIN;

create warehouse DATAGOV warehouse_size=small initially_suspended=true auto_suspend = 60 auto_resume = true;
grant usage on warehouse DATAGOV to role CORP_BIZ_OWNER;
grant usage on warehouse DATAGOV to role CORP_BIZ_USER;
grant usage on warehouse DATAGOV to role CORP_POLICY_ADMIN;

use role CORP_BIZ_OWNER;
create schema CORP_DATA.CORP_SCHEMA with managed access;
-- TWO THINGS YOU NEED TO KNOW
-- 1) where is the schema TPCDS_SF100TCL in your Snowflake account? the sample data may have different names.
-- 2) does your Snowflake account grant access to the sample data for all roles? if not, you must grant this to this role. 
use warehouse DATAGOV;
create table CORP_DATA.CORP_SCHEMA.CALL_CENTER as (select * from SAMPLE_DATA.TPCDS_SF100TCL.CALL_CENTER);
create table CORP_DATA.CORP_SCHEMA.CUSTOMER as (select * from SAMPLE_DATA.TPCDS_SF100TCL.CUSTOMER);
create table CORP_DATA.CORP_SCHEMA.CUSTOMER_ADDRESS as (select * from SAMPLE_DATA.TPCDS_SF100TCL.CUSTOMER_ADDRESS);
create table CORP_DATA.CORP_SCHEMA.INVENTORY as (select * from SAMPLE_DATA.TPCDS_SF100TCL.INVENTORY);
create table CORP_DATA.CORP_SCHEMA.ITEM as (select * from SAMPLE_DATA.TPCDS_SF100TCL.ITEM);
create table CORP_DATA.CORP_SCHEMA.WAREHOUSE as (select * from SAMPLE_DATA.TPCDS_SF100TCL.WAREHOUSE);
create table CORP_DATA.CORP_SCHEMA.DATE_DIM as (select * from SAMPLE_DATA.TPCDS_SF100TCL.DATE_DIM);
create table CORP_DATA.CORP_SCHEMA.TIME_DIM as (select * from SAMPLE_DATA.TPCDS_SF100TCL.TIME_DIM);
