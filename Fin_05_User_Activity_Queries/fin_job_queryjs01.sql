alter session set query_tag='fin_job queryjs01';
use role FIN_BIZ_USER;
use database FIN_DATA;
use schema FIN_SCHEMA;
use warehouse DATAGOV;

select 
    C_CUSTOMER_ID, 
    C_CURRENT_ADDR_SK, 
    C_BIRTH_YEAR, 
    CD_GENDER,
    CD_DEP_COUNT,
    IB_LOWER_BOUND,
    IB_UPPER_BOUND
from 
    FIN_DATA.FIN_SCHEMA.CUSTOMER_CORP,
    FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS,
    FIN_DATA.FIN_SCHEMA.INCOME_BAND
where 
    C_CUSTOMER_SK = CD_DEMO_SK and
    C_CUSTOMER_SK = IB_INCOME_BAND_SK
limit 100;
