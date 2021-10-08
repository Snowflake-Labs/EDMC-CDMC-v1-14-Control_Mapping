-------
-- Corp_04_Policy.sql
-------

use role CORP_BIZ_OWNER;
grant create masking policy on schema CORP_DATA.CORP_SCHEMA to role CORP_POLICY_ADMIN;

use role CORP_POLICY_ADMIN;

create masking policy CORP_DATA.CORP_SCHEMA.HIDE_OPTOUTS_STR as
(col_value varchar, optin string) returns varchar ->
  case
    when optin = 'YES' then col_value
    else '***MASKED***'
  end;

alter view CORP_DATA.CORP_SCHEMA.CUSTOMER_CONTROLLED modify column C_SALUTATION
set masking policy CORP_DATA.CORP_SCHEMA.HIDE_OPTOUTS_STR using (C_SALUTATION, optin);

alter view CORP_DATA.CORP_SCHEMA.CUSTOMER_CONTROLLED modify column C_FIRST_NAME
set masking policy CORP_DATA.CORP_SCHEMA.HIDE_OPTOUTS_STR using (C_FIRST_NAME, optin);

alter view CORP_DATA.CORP_SCHEMA.CUSTOMER_CONTROLLED modify column C_LAST_NAME
set masking policy CORP_DATA.CORP_SCHEMA.HIDE_OPTOUTS_STR using (C_LAST_NAME, optin);

alter view CORP_DATA.CORP_SCHEMA.CUSTOMER_CONTROLLED modify column C_BIRTH_COUNTRY
set masking policy CORP_DATA.CORP_SCHEMA.HIDE_OPTOUTS_STR using (C_BIRTH_COUNTRY, optin);

alter view CORP_DATA.CORP_SCHEMA.CUSTOMER_CONTROLLED modify column C_LOGIN
set masking policy CORP_DATA.CORP_SCHEMA.HIDE_OPTOUTS_STR using (C_LOGIN, optin);

alter view CORP_DATA.CORP_SCHEMA.CUSTOMER_CONTROLLED modify column C_EMAIL_ADDRESS
set masking policy CORP_DATA.CORP_SCHEMA.HIDE_OPTOUTS_STR using (C_EMAIL_ADDRESS, optin);

alter view CORP_DATA.CORP_SCHEMA.CUSTOMER_ADDRESS_CONTROLLED modify column CA_STREET_NUMBER
set masking policy CORP_DATA.CORP_SCHEMA.HIDE_OPTOUTS_STR using (CA_STREET_NUMBER, optin);

alter view CORP_DATA.CORP_SCHEMA.CUSTOMER_ADDRESS_CONTROLLED modify column CA_STREET_NAME
set masking policy CORP_DATA.CORP_SCHEMA.HIDE_OPTOUTS_STR using (CA_STREET_NAME, optin);

alter view CORP_DATA.CORP_SCHEMA.CUSTOMER_ADDRESS_CONTROLLED modify column CA_STREET_TYPE
set masking policy CORP_DATA.CORP_SCHEMA.HIDE_OPTOUTS_STR using (CA_STREET_TYPE, optin);

alter view CORP_DATA.CORP_SCHEMA.CUSTOMER_ADDRESS_CONTROLLED modify column CA_SUITE_NUMBER
set masking policy CORP_DATA.CORP_SCHEMA.HIDE_OPTOUTS_STR using (CA_SUITE_NUMBER, optin);

alter view CORP_DATA.CORP_SCHEMA.CUSTOMER_ADDRESS_CONTROLLED modify column CA_CITY
set masking policy CORP_DATA.CORP_SCHEMA.HIDE_OPTOUTS_STR using (CA_CITY, optin);

alter view CORP_DATA.CORP_SCHEMA.CUSTOMER_ADDRESS_CONTROLLED modify column CA_COUNTY
set masking policy CORP_DATA.CORP_SCHEMA.HIDE_OPTOUTS_STR using (CA_COUNTY, optin);

alter view CORP_DATA.CORP_SCHEMA.CUSTOMER_ADDRESS_CONTROLLED modify column CA_STATE
set masking policy CORP_DATA.CORP_SCHEMA.HIDE_OPTOUTS_STR using (CA_STATE, optin);

alter view CORP_DATA.CORP_SCHEMA.CUSTOMER_ADDRESS_CONTROLLED modify column CA_ZIP
set masking policy CORP_DATA.CORP_SCHEMA.HIDE_OPTOUTS_STR using (CA_ZIP, optin);

alter view CORP_DATA.CORP_SCHEMA.CUSTOMER_ADDRESS_CONTROLLED modify column CA_COUNTRY
set masking policy CORP_DATA.CORP_SCHEMA.HIDE_OPTOUTS_STR using (CA_COUNTRY, optin);

alter view CORP_DATA.CORP_SCHEMA.CUSTOMER_ADDRESS_CONTROLLED modify column CA_LOCATION_TYPE
set masking policy CORP_DATA.CORP_SCHEMA.HIDE_OPTOUTS_STR using (CA_LOCATION_TYPE, optin);

create masking policy CORP_DATA.CORP_SCHEMA.HIDE_OPTOUTS_NUM as
(col_value number, optin string) returns number ->
  case
    when optin = 'YES' then col_value
    else 9999
  end;

alter view CORP_DATA.CORP_SCHEMA.CUSTOMER_CONTROLLED modify column C_BIRTH_DAY
set masking policy CORP_DATA.CORP_SCHEMA.HIDE_OPTOUTS_NUM using (C_BIRTH_DAY, optin);

alter view CORP_DATA.CORP_SCHEMA.CUSTOMER_CONTROLLED modify column C_BIRTH_MONTH
set masking policy CORP_DATA.CORP_SCHEMA.HIDE_OPTOUTS_NUM using (C_BIRTH_MONTH, optin);

alter view CORP_DATA.CORP_SCHEMA.CUSTOMER_CONTROLLED modify column C_BIRTH_YEAR
set masking policy CORP_DATA.CORP_SCHEMA.HIDE_OPTOUTS_NUM using (C_BIRTH_YEAR, optin);
