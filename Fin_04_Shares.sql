-------
-- Fin_04_Shares.sql
-------

-- set up incoming share from CORP_DATA
use role accountadmin;
show shares; -- determine the account names of the share providers
create database CORP_DATA from share <SHARE_PROVIDER_ACCOUNT>.CORP_DATA; 
grant imported privileges on database CORP_DATA to role FIN_BIZ_OWNER;

use role FIN_BIZ_OWNER;
create secure view FIN_DATA.FIN_SCHEMA.CALL_CENTER_CORP as (select * from CORP_DATA.CORP_SCHEMA.CALL_CENTER);
create secure view FIN_DATA.FIN_SCHEMA.CUSTOMER_CORP as (select * from CORP_DATA.CORP_SCHEMA.CUSTOMER);
create secure view FIN_DATA.FIN_SCHEMA.CUSTOMER_ADDRESS_CORP as (select * from CORP_DATA.CORP_SCHEMA.CUSTOMER_ADDRESS);
create secure view FIN_DATA.FIN_SCHEMA.INVENTORY_CORP as (select * from CORP_DATA.CORP_SCHEMA.INVENTORY);
create secure view FIN_DATA.FIN_SCHEMA.ITEM_CORP as (select * from CORP_DATA.CORP_SCHEMA.ITEM);
create secure view FIN_DATA.FIN_SCHEMA.WAREHOUSE_CORP as (select * from CORP_DATA.CORP_SCHEMA.WAREHOUSE);
create secure view FIN_DATA.FIN_SCHEMA.TIME_DIM_CORP as (select * from CORP_DATA.CORP_SCHEMA.TIME_DIM);
create secure view FIN_DATA.FIN_SCHEMA.DATE_DIM_CORP as (select * from CORP_DATA.CORP_SCHEMA.DATE_DIM);
