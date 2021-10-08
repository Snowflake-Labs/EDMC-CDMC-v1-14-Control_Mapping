-------
-- Corp_03_Shared_Objects.sql
-------

-- create opt in table to determine what is shared to retail
-- "randomly" assigned an opt in value to each customer key
use role CORP_BIZ_OWNER;

create table CORP_DATA.CORP_SCHEMA.CUSTOMER_OPTIN as (
    SELECT 
        C_CUSTOMER_SK,
        IFF(RANDOM() % 2 = 0, (IFF(RANDOM() % 2 = 0, 'YES', 'NO')), NULL) AS OPTIN
    FROM CORP_DATA.CORP_SCHEMA.CUSTOMER
);

-- create secure views to share

create view CORP_DATA.CORP_SCHEMA.CUSTOMER_CONTROLLED as (
select         
    a.C_CUSTOMER_SK, 
    a.C_CUSTOMER_ID, 
    a.C_CURRENT_CDEMO_SK, 
    a.C_CURRENT_HDEMO_SK, 
    a.C_CURRENT_ADDR_SK, 
    a.C_FIRST_SHIPTO_DATE_SK, 
    a.C_FIRST_SALES_DATE_SK, 
    a.C_SALUTATION, 
    a.C_FIRST_NAME, 
    a.C_LAST_NAME, 
    a.C_PREFERRED_CUST_FLAG, 
    a.C_BIRTH_DAY, 
    a.C_BIRTH_MONTH, 
    a.C_BIRTH_YEAR, 
    a.C_BIRTH_COUNTRY, 
    a.C_LOGIN, 
    a.C_EMAIL_ADDRESS, 
    a.C_LAST_REVIEW_DATE, 
    b.OPTIN
from 
    CORP_DATA.CORP_SCHEMA.CUSTOMER a, 
    CORP_DATA.CORP_SCHEMA.CUSTOMER_OPTIN b 
where 
    a.C_CUSTOMER_SK = b.C_CUSTOMER_SK
);

alter view CORP_DATA.CORP_SCHEMA.CUSTOMER_CONTROLLED set secure;

create view CORP_DATA.CORP_SCHEMA.CUSTOMER_ADDRESS_CONTROLLED as (
select 
    a.CA_ADDRESS_SK, 
    a.CA_ADDRESS_ID, 
    a.CA_STREET_NUMBER, 
    a.CA_STREET_NAME, 
    a.CA_STREET_TYPE, 
    a.CA_SUITE_NUMBER, 
    a.CA_CITY, 
    a.CA_COUNTY, 
    a.CA_STATE, 
    a.CA_ZIP, 
    a.CA_COUNTRY, 
    a.CA_GMT_OFFSET, 
    a.CA_LOCATION_TYPE, 
    b.OPTIN
from
    CORP_DATA.CORP_SCHEMA.CUSTOMER_ADDRESS a, 
    CORP_DATA.CORP_SCHEMA.CUSTOMER_OPTIN b, 
    CORP_DATA.CORP_SCHEMA.CUSTOMER c
where
    c.C_CUSTOMER_SK = b.C_CUSTOMER_SK
and
    c.C_CURRENT_ADDR_SK = a.CA_ADDRESS_SK
);

alter view CORP_DATA.CORP_SCHEMA.CUSTOMER_ADDRESS_CONTROLLED set secure;
