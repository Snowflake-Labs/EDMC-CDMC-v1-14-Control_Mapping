#!/bin/bash

snowsql -a <YOUR_ORG_NAME>-cdmc_retail -u WOLE-SOYINKA@EDMC-CDMC-ORG.COM --private-key-path /<FULL_PATH>/cdmc_private_rsa_key.p8 -f /<FULL_PATH>/ret_job_query01.sql
snowsql -a <YOUR_ORG_NAME>-cdmc_retail -u WOLE-SOYINKA@EDMC-CDMC-ORG.COM --private-key-path /<FULL_PATH>/cdmc_private_rsa_key.p8 -f /<FULL_PATH>/ret_job_query02.sql
snowsql -a <YOUR_ORG_NAME>-cdmc_retail -u WOLE-SOYINKA@EDMC-CDMC-ORG.COM --private-key-path /<FULL_PATH>/cdmc_private_rsa_key.p8 -f /<FULL_PATH>/ret_job_query03.sql
snowsql -a <YOUR_ORG_NAME>-cdmc_retail -u WOLE-SOYINKA@EDMC-CDMC-ORG.COM --private-key-path /<FULL_PATH>/cdmc_private_rsa_key.p8 -f /<FULL_PATH>/ret_job_query06.sql