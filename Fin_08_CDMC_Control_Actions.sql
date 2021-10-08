-------
-- Fin_08_CDMC_Control_Actions.sql
-------

-- active experiment in order to demonstrate CDMC v1.0 Capability 2.1 Control 5 Test Criteria 2.1 & 2.2
use role FIN_BIZ_OWNER;
alter table FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS add column C_BIRTH_DAY number;
alter table FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS add column C_BIRTH_MONTH number;
alter table FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS add column C_BIRTH_YEAR number;
insert into FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS(C_BIRTH_DAY, C_BIRTH_MONTH, C_BIRTH_YEAR)
    select
        a.C_BIRTH_DAY, a.C_BIRTH_MONTH, a.C_BIRTH_YEAR
    from 
        FIN_DATA.FIN_SCHEMA.CUSTOMER_CORP a
    inner join
        FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS b 
    on
        a.c_customer_sk = b.cd_demo_sk
;

use role FIN_BIZ_OWNER;
alter table FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS rename column C_BIRTH_YEAR to C_BIRTH_YEAR_AND_AGE;

use role FIN_BIZ_OWNER;
alter table FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS drop column C_BIRTH_DAY;
alter table FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS drop column C_BIRTH_MONTH;
alter table FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS drop column C_BIRTH_YEAR_AND_AGE;

-- lineage data actions

-- active experiment in order to demonstrate CDMC v1.0 Capability 6.1 Control 13 Test Criteria 3.1
use role FIN_BIZ_OWNER;
create table FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS_CTAS as ( select * from FIN_DATA.FIN_SCHEMA.CUSTOMER_DEMOGRAPHICS);

-- active experiment in order to demonstrate CDMC v1.0 Capability 6.1 Control 13 Test Criteria 3.2

-- this is the sending end of a data transmission to the CORP account to show cross account/cloud lineage tracking
use role accountadmin;
create storage integration CDMCLINEAGESOURCE
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3 -- or the cloud storage of your choice
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::<YOUR_AWS_ACCT_ID>:role/cdmc-lineage-role'
  STORAGE_ALLOWED_LOCATIONS = ('s3://<YOUR_S3_BUCKET_NAME>/fin-to-corp/')
  ;

desc integration CDMCLINEAGESOURCE;

grant create stage on schema FIN_DATA.FIN_SCHEMA to role FIN_BIZ_OWNER;
grant usage on integration CDMCLINEAGESOURCE to role FIN_BIZ_OWNER;

use role FIN_BIZ_OWNER;
create or replace file format FIN_DATA.FIN_SCHEMA.MY_CSV_FORMAT
  type = csv
  field_delimiter = '|'
  skip_header = 1
  null_if = ('NULL', 'null')
  empty_field_as_null = true
  compression = gzip;

create or replace stage FIN_DATA.FIN_SCHEMA.CDMC_LINEAGE_SOURCE
  storage_integration = CDMCLINEAGESOURCE
  url = 's3://<YOUR_S3_BUCKET_NAME>/fin-to-corp/'
  file_format = FIN_DATA.FIN_SCHEMA.my_csv_format;

grant usage on stage FIN_DATA.FIN_SCHEMA.CDMC_LINEAGE_SOURCE to role fin_biz_user;
grant usage on file format FIN_DATA.FIN_SCHEMA.my_csv_format to role fin_biz_user;

use role fin_biz_user;
copy into @FIN_DATA.FIN_SCHEMA.CDMC_LINEAGE_SOURCE
  from FIN_DATA.FIN_SCHEMA.HOUSEHOLD_DEMOGRAPHICS
  ;
