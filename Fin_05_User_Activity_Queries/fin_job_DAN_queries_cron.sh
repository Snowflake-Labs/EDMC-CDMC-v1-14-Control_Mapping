#!/bin/bash

snowsql -a <YOUR_ORG_NAME>-cdmc_finance -u DAN-SHECHTMAN@EDMC-CDMC-ORG.COM --private-key-path /<FULL_PATH>/cdmc_private_rsa_key.p8 -f /<FULL_PATH>/fin_job_queryjs01.sql
snowsql -a <YOUR_ORG_NAME>-cdmc_finance -u DAN-SHECHTMAN@EDMC-CDMC-ORG.COM --private-key-path /<FULL_PATH>/cdmc_private_rsa_key.p8 -f /<FULL_PATH>/fin_job_queryjs02.sql
snowsql -a <YOUR_ORG_NAME>-cdmc_finance -u DAN-SHECHTMAN@EDMC-CDMC-ORG.COM --private-key-path /<FULL_PATH>/cdmc_private_rsa_key.p8 -f /<FULL_PATH>/fin_job_queryjs03.sql
