-------
-- Ret_01_Init.sql
-------

use role useradmin;

create role RET_DBA;
grant role RET_DBA to user <YOUR_USERNAME>; -- you need this role to continue set up

create role RET_BIZ_OWNER;
grant role RET_BIZ_OWNER to user <YOUR_USERNAME>; -- you need this role to continue set up

create role RET_BIZ_USER;

use role accountadmin;
grant create database on account to role RET_DBA;
grant create warehouse on account to role RET_DBA;

use role RET_DBA;
create database RET_DATA;
grant usage on database RET_DATA to role RET_BIZ_OWNER;
grant create schema on database RET_DATA to role RET_BIZ_OWNER;
grant usage on database RET_DATA to role RET_BIZ_USER;

create warehouse DATAGOV warehouse_size=small initially_suspended=true auto_suspend = 60 auto_resume = true;
grant usage on warehouse DATAGOV to role RET_BIZ_OWNER;
grant usage on warehouse DATAGOV to role RET_BIZ_USER;

use role RET_BIZ_OWNER;
create schema RET_DATA.RET_SCHEMA with managed access;
-- TWO THINGS YOU NEED TO KNOW
-- 1) where is the schema tpcds_sf100tcl in your Snowflake account? the sample data may have different names.
-- 2) does your Snowflake account grant access to the sample data for all roles? if not, you must grant this to this role.
use warehouse DATAGOV;
create table RET_DATA.RET_SCHEMA.CATALOG_PAGE as (select * from SAMPLE_DATA.TPCDS_SF100TCL.CATALOG_PAGE);
create table RET_DATA.RET_SCHEMA.CATALOG_RETURNS as (select * from SAMPLE_DATA.TPCDS_SF100TCL.CATALOG_RETURNS limit 100000); -- you may put as much data as you like, but this is a suggested minimum to ensure query results
create table RET_DATA.RET_SCHEMA.CATALOG_SALES as (select * from SAMPLE_DATA.TPCDS_SF100TCL.CATALOG_SALES limit 100000); -- you may put as much data as you like, but this is a suggested minimum to ensure query results
create table RET_DATA.RET_SCHEMA.PROMOTION as (select * from SAMPLE_DATA.TPCDS_SF100TCL.PROMOTION);
create table RET_DATA.RET_SCHEMA.REASON as (select * from SAMPLE_DATA.TPCDS_SF100TCL.REASON);
create table RET_DATA.RET_SCHEMA.SHIP_MODE as (select * from SAMPLE_DATA.TPCDS_SF100TCL.SHIP_MODE);
create table RET_DATA.RET_SCHEMA.STORE as (select * from SAMPLE_DATA.TPCDS_SF100TCL.STORE);
create table RET_DATA.RET_SCHEMA.STORE_RETURNS as (select * from SAMPLE_DATA.TPCDS_SF100TCL.STORE_RETURNS limit 100000); -- you may put as much data as you like, but this is a suggested minimum to ensure query results
create table RET_DATA.RET_SCHEMA.STORE_SALES as (select * from SAMPLE_DATA.TPCDS_SF100TCL.STORE_SALES limit 100000); -- you may put as much data as you like, but this is a suggested minimum to ensure query results
create table RET_DATA.RET_SCHEMA.WEB_PAGE as (select * from SAMPLE_DATA.TPCDS_SF100TCL.WEB_PAGE);
create table RET_DATA.RET_SCHEMA.WEB_RETURNS as (select * from SAMPLE_DATA.TPCDS_SF100TCL.WEB_RETURNS limit 100000); -- you may put as much data as you like, but this is a suggested minimum to ensure query results
create table RET_DATA.RET_SCHEMA.WEB_SALES as (select * from SAMPLE_DATA.TPCDS_SF100TCL.WEB_SALES limit 100000); -- you may put as much data as you like, but this is a suggested minimum to ensure query results
create table RET_DATA.RET_SCHEMA.WEB_SITE as (select * from SAMPLE_DATA.TPCDS_SF100TCL.WEB_SITE);
