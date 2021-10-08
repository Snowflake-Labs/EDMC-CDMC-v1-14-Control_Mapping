alter session set query_tag='fin_job queryjs02';
use role FIN_BIZ_USER;
use database FIN_DATA;
use schema FIN_SCHEMA;
use warehouse DATAGOV;

select 
    C_CUSTOMER_ID, 
    C_CURRENT_ADDR_SK, 
    C_BIRTH_YEAR, 
    CD_GENDER,
    CD_DEP_COUNT
from 
    FIN_DATA.FIN_SCHEMA.CUSTOMER_CORP,
    FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS
where 
    C_CUSTOMER_SK = CD_DEMO_SK
limit 100;
