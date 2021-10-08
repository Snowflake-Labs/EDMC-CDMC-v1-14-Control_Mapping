-------
-- Corp_05_Shares.sql
-------

-- set up incoming share from FIN and RET
use role accountadmin;
show shares; -- determine the account names of the share providers
create database RET_DATA from share <SHARE_PROVIDER_ACCOUNT>.RET_DATA;
grant imported privileges on database RET_DATA to role CORP_BIZ_OWNER;

use role CORP_BIZ_OWNER;
create secure view CORP_DATA.CORP_SCHEMA.CATALOG_PAGE_RET as (select * from RET_DATA.RET_SCHEMA.CATALOG_PAGE);
create secure view CORP_DATA.CORP_SCHEMA.CATALOG_RETURNS_RET as (select * from RET_DATA.RET_SCHEMA.CATALOG_RETURNS);
create secure view CORP_DATA.CORP_SCHEMA.CATALOG_SALES_RET as (select * from RET_DATA.RET_SCHEMA.CATALOG_SALES);
create secure view CORP_DATA.CORP_SCHEMA.PROMOTION_RET as (select * from RET_DATA.RET_SCHEMA.PROMOTION);
create secure view CORP_DATA.CORP_SCHEMA.REASON_RET as (select * from RET_DATA.RET_SCHEMA.REASON);
create secure view CORP_DATA.CORP_SCHEMA.SHIP_MODE_RET as (select * from RET_DATA.RET_SCHEMA.SHIP_MODE);
create secure view CORP_DATA.CORP_SCHEMA.STORE_RET as (select * from RET_DATA.RET_SCHEMA.STORE);
create secure view CORP_DATA.CORP_SCHEMA.STORE_RETURNS_RET as (select * from RET_DATA.RET_SCHEMA.STORE_RETURNS);
create secure view CORP_DATA.CORP_SCHEMA.STORE_SALES_RET as (select * from RET_DATA.RET_SCHEMA.STORE_SALES);
create secure view CORP_DATA.CORP_SCHEMA.WEB_PAGE_RET as (select * from RET_DATA.RET_SCHEMA.WEB_PAGE);
create secure view CORP_DATA.CORP_SCHEMA.WEB_RETURNS_RET as (select * from RET_DATA.RET_SCHEMA.WEB_RETURNS);
create secure view CORP_DATA.CORP_SCHEMA.WEB_SALES_RET as (select * from RET_DATA.RET_SCHEMA.WEB_SALES);
create secure view CORP_DATA.CORP_SCHEMA.WEB_SITE_RET as (select * from RET_DATA.RET_SCHEMA.WEB_SITE);

use role accountadmin;
create database FIN_DATA from share <SHARE_PROVIDER_ACCOUNT>.FIN_DATA;
grant imported privileges on database FIN_DATA to role CORP_BIZ_OWNER;

use role CORP_BIZ_OWNER;
create secure view CORP_DATA.CORP_SCHEMA.CUSTOMER_DEMOGRAPHICS_FIN as (select * from FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS);
create secure view CORP_DATA.CORP_SCHEMA.HOUSEHOLD_DEMOGRAPHICS_FIN as (select * from FIN_DATA.FIN_SCHEMA.HOUSEHOLD_DEMOGRAPHICS);
create secure view CORP_DATA.CORP_SCHEMA.INCOME_BAND_FIN as (select * from FIN_DATA.FIN_SCHEMA.INCOME_BAND);
