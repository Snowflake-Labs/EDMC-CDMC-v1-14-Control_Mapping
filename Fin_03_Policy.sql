-------
-- Fin_03_Policy.sql
-------

-- set up row access policies
use role FIN_BIZ_OWNER;
grant usage on schema FIN_DATA.FIN_SCHEMA to role FIN_POLICY_ADMIN;
grant create ROW ACCESS POLICY on schema FIN_DATA.FIN_SCHEMA to role FIN_POLICY_ADMIN;

create table FIN_DATA.FIN_SCHEMA.FIN_SCHEMA_DATA_READER_ROLES (
  role_name varchar,
  allowed   varchar
);

grant select on FIN_DATA.FIN_SCHEMA.FIN_SCHEMA_DATA_READER_ROLES to role FIN_POLICY_ADMIN;
grant insert on FIN_DATA.FIN_SCHEMA.FIN_SCHEMA_DATA_READER_ROLES to role FIN_POLICY_ADMIN;

use role FIN_POLICY_ADMIN;
use warehouse DATAGOV;

insert into FIN_DATA.FIN_SCHEMA.FIN_SCHEMA_DATA_READER_ROLES
  values
  ('ACCOUTADMIN','FALSE'),
  ('FIN_BIZ_OWNER','FALSE'),
  ('FIN_BIZ_USER','TRUE');

create or replace row access policy FIN_DATA.FIN_SCHEMA.FIN_USERS_ONLY as (empty number) returns boolean ->
  case
      -- check for full read access
      when exists ( 
            select 1 from FIN_DATA.FIN_SCHEMA.FIN_SCHEMA_DATA_READER_ROLES
              where role_name = current_role()
                and allowed = 'TRUE'
          ) then true
      -- always default deny
      else false
  end
;

use role FIN_BIZ_OWNER;
grant apply on row access policy FIN_DATA.FIN_SCHEMA.FIN_USERS_ONLY to role FIN_BIZ_OWNER;
alter table FIN_DATA.FIN_SCHEMA.HOUSEHOLD_DEMOGRAPHICS add row access policy FIN_DATA.FIN_SCHEMA.FIN_USERS_ONLY on (HD_DEMO_SK);
alter table FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS add row access policy FIN_DATA.FIN_SCHEMA.FIN_USERS_ONLY on (CD_DEMO_SK);

-- set up masking policies
use role FIN_BIZ_OWNER;
grant create masking policy on schema FIN_DATA.FIN_SCHEMA to role FIN_POLICY_ADMIN;

use role FIN_POLICY_ADMIN;
create or replace masking policy FIN_DATA.FIN_SCHEMA.FIN_MASKING_STR as (val string) returns string ->
  case
    when is_role_in_session('FIN_PII_ACCESS') then val
    when invoker_share() in ('FIN_DATA') then '***SHAREMASK***'
    else '***MASKED***' -- defult deny
  end;

use role accountadmin;
grant apply on masking policy FIN_DATA.FIN_SCHEMA.FIN_MASKING_STR to role FIN_BIZ_OWNER;

use role FIN_BIZ_OWNER;
alter table FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS modify column CD_GENDER set masking policy FIN_DATA.FIN_SCHEMA.FIN_MASKING_STR;
alter table FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS modify column CD_MARITAL_STATUS set masking policy FIN_DATA.FIN_SCHEMA.FIN_MASKING_STR;
alter table FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS modify column CD_EDUCATION_STATUS set masking policy FIN_DATA.FIN_SCHEMA.FIN_MASKING_STR;
alter table FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS modify column CD_CREDIT_RATING set masking policy FIN_DATA.FIN_SCHEMA.FIN_MASKING_STR;
alter table FIN_DATA.FIN_SCHEMA.HOUSEHOLD_DEMOGRAPHICS modify column HD_BUY_POTENTIAL set masking policy FIN_DATA.FIN_SCHEMA.FIN_MASKING_STR;

use role FIN_POLICY_ADMIN;
create or replace masking policy FIN_DATA.FIN_SCHEMA.FIN_MASKING_NUM as (val number) returns number ->
  case
    when is_role_in_session('FIN_PII_ACCESS') then val
    when invoker_share() in ('FIN_DATA') then 90909090
    else 80808080 -- defult deny
  end;

use role accountadmin;
grant apply on masking policy FIN_DATA.FIN_SCHEMA.FIN_MASKING_NUM to role FIN_BIZ_OWNER;

use role FIN_BIZ_OWNER;
alter table FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS modify column CD_PURCHASE_ESTIMATE set masking policy FIN_DATA.FIN_SCHEMA.FIN_MASKING_NUM;
alter table FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS modify column CD_DEP_COUNT set masking policy FIN_DATA.FIN_SCHEMA.FIN_MASKING_NUM;
alter table FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS modify column CD_DEP_EMPLOYED_COUNT set masking policy FIN_DATA.FIN_SCHEMA.FIN_MASKING_NUM;
alter table FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS modify column CD_DEP_COLLEGE_COUNT set masking policy FIN_DATA.FIN_SCHEMA.FIN_MASKING_NUM;
alter table FIN_DATA.FIN_SCHEMA.HOUSEHOLD_DEMOGRAPHICS modify column HD_DEP_COUNT set masking policy FIN_DATA.FIN_SCHEMA.FIN_MASKING_NUM;
alter table FIN_DATA.FIN_SCHEMA.HOUSEHOLD_DEMOGRAPHICS modify column HD_VEHICLE_COUNT set masking policy FIN_DATA.FIN_SCHEMA.FIN_MASKING_NUM;
alter table FIN_DATA.FIN_SCHEMA.INCOME_BAND modify column IB_LOWER_BOUND set masking policy FIN_DATA.FIN_SCHEMA.FIN_MASKING_NUM;
alter table FIN_DATA.FIN_SCHEMA.INCOME_BAND modify column IB_UPPER_BOUND set masking policy FIN_DATA.FIN_SCHEMA.FIN_MASKING_NUM;
