-------
-- Ret_02_IAM.sql
-------

-- using IdP here in order to satisfy CDMC v1.0 Capability 1.2 Control 2 Test Criteria 3.1.1
-- IdP type is not important. what is important is the use of an authoritative source of users.
use role accountadmin;
create security integration CDMC_Retail_IdP
    type = saml2
    enabled = true
    saml2_issuer = 'http://www.okta.com/<APPID_FROM_OKTA>'
    saml2_sso_url = 'https://<YOUR_OKTA_DOMAIN>.oktapreview.com/app/snowflake/<APPID_FROM_OKTA>/sso/saml'
    saml2_provider = 'OKTA'
    saml2_x509_cert='MII...' -- value of cert supplied by Okta
    saml2_sp_initiated_login_page_label = 'CDMC_Retail_IdP'
    saml2_enable_sp_initiated = true
;

use role accountadmin;
create security integration CDMC_Retail_SCIM
    type=scim
    scim_client='okta'
    run_as_role='USERADMIN'
;
select system$generate_scim_access_token('CDMC_RETAIL_SCIM');  -- produces token to be used in Okta config

-- after SCIM assignment and creation of users, assign public keys for scripting AuthN
-- actual user names here are just samples used in the testing. names may vary.
use role useradmin;
alter user "ALBERT-JOHN-LUTHULI@EDMC-CDMC-ORG.COM" set rsa_public_key='MII...';
alter user "DEREK-WALCOTT@EDMC-CDMC-ORG.COM" set rsa_public_key='MII...';
alter user "RALPH-BUNCHE@EDMC-CDMC-ORG.COM" set rsa_public_key='MII...';
alter user "TONI-MORRISON@EDMC-CDMC-ORG.COM" set rsa_public_key='MII...';
alter user "WANGARI-MAATHAI@EDMC-CDMC-ORG.COM" set rsa_public_key='MII...';
alter user "WILLIAM-ARTHUR-LEWIS@EDMC-CDMC-ORG.COM" set rsa_public_key='MII...';
alter user "WOLE-SOYINKA@EDMC-CDMC-ORG.COM" set rsa_public_key='MII...';

use role RET_BIZ_OWNER;
grant usage on schema RET_DATA.RET_SCHEMA to role RET_BIZ_USER;
grant select on all tables in schema RET_DATA.RET_SCHEMA to role RET_BIZ_USER;
grant select on future tables in schema RET_DATA.RET_SCHEMA to role RET_BIZ_USER;
grant select on all views in schema RET_DATA.RET_SCHEMA to role RET_BIZ_USER;
grant select on future views in schema RET_DATA.RET_SCHEMA to role RET_BIZ_USER;

use role useradmin;
grant role RET_BIZ_USER to user "ALBERT-JOHN-LUTHULI@EDMC-CDMC-ORG.COM";
grant role RET_BIZ_USER to user "DEREK-WALCOTT@EDMC-CDMC-ORG.COM";
grant role RET_BIZ_USER to user "RALPH-BUNCHE@EDMC-CDMC-ORG.COM";
grant role RET_BIZ_USER to user "TONI-MORRISON@EDMC-CDMC-ORG.COM";
grant role RET_BIZ_USER to user "WANGARI-MAATHAI@EDMC-CDMC-ORG.COM";
grant role RET_BIZ_USER to user "WILLIAM-ARTHUR-LEWIS@EDMC-CDMC-ORG.COM";
grant role RET_BIZ_USER to user "WOLE-SOYINKA@EDMC-CDMC-ORG.COM";
