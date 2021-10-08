-------
-- Corp_08_CDMC_Control_Actions.sql
-------

-- active experiments in order to demonstrate CDMC v1.0 Capability 6.1 Control 13 Test Criteria 3.2

-- this is the receiving end of a data transmission from the FIN account to show cross account/cloud lineage tracking
use role accountadmin;
CREATE STORAGE INTEGRATION CDMCLINEAGESOURCE
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3 -- or the cloud storage of your choice
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::<YOUR_AWS_ACCT_ID>:role/cdmc-lineage-role'
  STORAGE_ALLOWED_LOCATIONS = ('s3://<YOUR_S3_BUCKET_NAME>/fin-to-corp/')
  ;

desc integration CDMCLINEAGESOURCE;

grant create stage on schema CORP_DATA.CORP_SCHEMA to role CORP_BIZ_OWNER;
grant usage on integration CDMCLINEAGESOURCE to role CORP_BIZ_OWNER;

use role CORP_BIZ_OWNER;
create or replace file format CORP_DATA.CORP_SCHEMA.MY_CSV_FORMAT
  type = csv
  field_delimiter = '|'
  skip_header = 1
  null_if = ('NULL', 'null')
  empty_field_as_null = true
  compression = gzip;

create or replace stage CORP_DATA.CORP_SCHEMA.CDMC_LINEAGE_SOURCE
  storage_integration = CDMCLINEAGESOURCE
  url = 's3://<YOUR_S3_BUCKET_NAME>/fin-to-corp/'
  file_format = CORP_DATA.CORP_SCHEMA.MY_CSV_FORMAT;

grant usage on stage CORP_DATA.CORP_SCHEMA.CDMC_LINEAGE_SOURCE to role CORP_BIZ_USER;
grant usage on file format CORP_DATA.CORP_SCHEMA.MY_CSV_FORMAT to role CORP_BIZ_USER;

use role CORP_BIZ_OWNER;
create table CORP_DATA.CORP_SCHEMA.HOUSEHOLD_DEMOGRAPHICS_COPYTEST as (select * from CORP_DATA.CORP_SCHEMA.HOUSEHOLD_DEMOGRAPHICS_FIN limit 1);
truncate table CORP_DATA.CORP_SCHEMA.HOUSEHOLD_DEMOGRAPHICS_COPYTEST;
grant select on table CORP_DATA.CORP_SCHEMA.HOUSEHOLD_DEMOGRAPHICS_COPYTEST to role CORP_BIZ_USER;
grant insert on table CORP_DATA.CORP_SCHEMA.HOUSEHOLD_DEMOGRAPHICS_COPYTEST to role CORP_BIZ_USER;
grant update on table CORP_DATA.CORP_SCHEMA.HOUSEHOLD_DEMOGRAPHICS_COPYTEST to role CORP_BIZ_USER;

use role CORP_BIZ_USER;
copy into CORP_DATA.CORP_SCHEMA.HOUSEHOLD_DEMOGRAPHICS_COPYTEST 
  from @CORP_DATA.CORP_SCHEMA.CDMC_LINEAGE_SOURCE/<DATA_FILE_NAME>
  ;