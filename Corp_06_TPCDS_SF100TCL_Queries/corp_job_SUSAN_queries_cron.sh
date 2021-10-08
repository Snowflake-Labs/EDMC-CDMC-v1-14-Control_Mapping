#!/bin/bash

snowsql -a <YOUR_ORG_NAME>-cdmc_corp -u SUSAN-FOREMAN@EDMC-CDMC-ORG.COM --private-key-path /<FULL_PATH>/cdmc_private_rsa_key.p8 -f /<FULL_PATH>/corp_job_query07.sql
snowsql -a <YOUR_ORG_NAME>-cdmc_corp -u SUSAN-FOREMAN@EDMC-CDMC-ORG.COM --private-key-path /<FULL_PATH>/cdmc_private_rsa_key.p8 -f /<FULL_PATH>/corp_job_query10.sql
snowsql -a <YOUR_ORG_NAME>-cdmc_corp -u SUSAN-FOREMAN@EDMC-CDMC-ORG.COM --private-key-path /<FULL_PATH>/cdmc_private_rsa_key.p8 -f /<FULL_PATH>/corp_job_query21.sql
snowsql -a <YOUR_ORG_NAME>-cdmc_corp -u SUSAN-FOREMAN@EDMC-CDMC-ORG.COM --private-key-path /<FULL_PATH>/cdmc_private_rsa_key.p8 -f /<FULL_PATH>/corp_job_query22.sql
