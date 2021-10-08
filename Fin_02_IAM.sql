-------
-- Fin_02_IAM.sql
-------

-- using IdP here in order to satisfy CDMC v1.0 Capability 1.2 Control 2 Test Criteria 3.1.1
-- IdP type is not important. what is important is the use of an authoritative source of users.
use role accountadmin;
create security integration CDMC_Finance_IdP
    type = saml2
    enabled = true
    saml2_issuer = 'http://www.okta.com/<APPID_FROM_OKTA>'
    saml2_sso_url = 'https://<YOUR_OKTA_DOMAIN>.oktapreview.com/app/snowflake/<APPID_FROM_OKTA>/sso/saml'
    saml2_provider = 'OKTA'
    saml2_x509_cert='MII...' -- value of cert supplied by Okta
    saml2_sp_initiated_login_page_label = 'CDMC_Finance_IdP'
    saml2_enable_sp_initiated = true
;

use role accountadmin;
create security integration CDMC_Finance_SCIM
    type=scim
    scim_client='okta'
    run_as_role='USERADMIN' --'OKTA_PROVISIONER'
;
select system$generate_scim_access_token('CDMC_FINANCE_SCIM'); -- produces token to be used in Okta config

-- after SCIM assignment and creation of users, assign public keys for scripting AuthN
-- actual user names here are just samples used in the testing. names may vary.
use role useradmin;
alter user "AKIRA-SUZUKI@EDMC-CDMC-ORG.COM" set rsa_public_key='MII...'
alter user "AKIRA-YOSHINO@EDMC-CDMC-ORG.COM" set rsa_public_key='MII...';
alter user "ARIEH-WARSHEL@EDMC-CDMC-ORG.COM" set rsa_public_key='MII...';
alter user "AZIZ-SANCAR@EDMC-CDMC-ORG.COM" set rsa_public_key='MII...';
alter user "DAN-SHECHTMAN@EDMC-CDMC-ORG.COM" set rsa_public_key='MII...';
alter user "EI-ICHI-NEGISHI@EDMC-CDMC-ORG.COM" set rsa_public_key='MII...';
alter user "MICHAEL-LEVITT@EDMC-CDMC-ORG.COM" set rsa_public_key='MII...';

use role FIN_BIZ_OWNER;
grant usage on schema FIN_DATA.FIN_SCHEMA to role FIN_BIZ_USER;
grant select on all tables in schema FIN_DATA.FIN_SCHEMA to role FIN_BIZ_USER;
grant select on future tables in schema FIN_DATA.FIN_SCHEMA to role FIN_BIZ_USER;
grant select on all views in schema FIN_DATA.FIN_SCHEMA to role FIN_BIZ_USER;
grant select on future views in schema FIN_DATA.FIN_SCHEMA to role FIN_BIZ_USER;

use role useradmin;
grant role FIN_BIZ_USER to user "AKIRA-SUZUKI@EDMC-CDMC-ORG.COM";
grant role FIN_BIZ_USER to user "AKIRA-YOSHINO@EDMC-CDMC-ORG.COM";
grant role FIN_BIZ_USER to user "ARIEH-WARSHEL@EDMC-CDMC-ORG.COM";
grant role FIN_BIZ_USER to user "AZIZ-SANCAR@EDMC-CDMC-ORG.COM";
grant role FIN_BIZ_USER to user "DAN-SHECHTMAN@EDMC-CDMC-ORG.COM";
grant role FIN_BIZ_USER to user "EI-ICHI-NEGISHI@EDMC-CDMC-ORG.COM";
grant role FIN_BIZ_USER to user "MICHAEL-LEVITT@EDMC-CDMC-ORG.COM";

grant role FIN_PII_ACCESS to user "AKIRA-YOSHINO@EDMC-CDMC-ORG.COM";
grant role FIN_PII_ACCESS to user "ARIEH-WARSHEL@EDMC-CDMC-ORG.COM";

alter user "AKIRA-YOSHINO@EDMC-CDMC-ORG.COM" set default_secondary_roles = ( 'ALL' );
alter user "ARIEH-WARSHEL@EDMC-CDMC-ORG.COM" set default_secondary_roles = ( 'ALL' );
