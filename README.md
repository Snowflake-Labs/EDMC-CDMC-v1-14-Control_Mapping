# EDMC_CDMC_Control_Mapping

## The EDMC CDMC Background
This is the code required to build the testbed for proving Snowflake and Alation can be coupled to meet [the CDMC 14 Key Controls for managing sensitive data in the cloud](https://edmcouncil.org/page/cdmc-14-key-controls-and-automation). The CDMC™ (Cloud Data Management Capabilities) Workgroup, part of [the EDM Council](https://edmcouncil.org/page/aboutedmcouncilrevi), introduced the CDMC 14 Key Controls & Automation, as part of the full CDMC v1 Framework. Download the 14 Key Controls document to review the business and regulatory requirements for managing sensitive data in the cloud.

Snowflake and Alation teamed up to be the first to be assessed against these controls, and [proved they have all the required capabilities through an assessment done by KPMG](https://investors.snowflake.com/news/news-details/2021/Snowflake-Achieves-First-Cloud-Data-Management-Capabilities-CDMC-Assessment/default.aspx). 

## How To Use This
If you wished to replicate the testing Snowflake and Alation did to satisfy the 14 Key Controls, this would give you what you need to do so. It can also serve as a reference for how various capabilities were deployed to meet the stated test criteria in the 14 Key Controls. 

To replicate this exactly you would need:
* 3 Snowflake Accounts, ideally in different clouds. Our testing was done with one account each in AWS, Azure, and GCP. (See architecture diagram below)
* An Okta account, or an equivalent IdP to be used for SCIM and SAML
* An instance of Alation 
* This code base
* The Snowflake built in sample data, specifically the TPCDS_SF100TCL data
* Proper authorization in all systems to create objects and integrations from scratch

The test sets up a fictional organization where all the divisions have selected different cloud service providers, but all have agreed on Snowflake as a means to manage and share data in the cloud. 

The design for this testbed is pictured here:
![CDMC Arch with Alation & Snowflake](./CDMC_Arch_with_Alation_Snowflake.png "CDMC Arch with Alation & Snowflake")

Steps to create the Snowflake parts are as follows:
1. Designate Snowflake accounts as the Corp, Finance, and Retail roles in the fictional organization. 
2. For Corp, run the numbered SQL scripts Corp_01* through Corp_05*. 
3. For Finance, run the numbered SQL scripts Fin_01* through Fin_04*.
4. For Retail, run the numbered SQL scripts Ret_01* through Ret_03*.
5. To make sure there are activities being run against this data, use the SQL provided in the [Corp_06_TPCDS_SF100TCL_Queries](Corp_06_TPCDS_SF100TCL_Queries), [Fin_05_User_Activity_Queries](Fin_05_User_Activity_Queries), and [Ret_04_TPCDS_SF100TCL_Queries](Ret_04_TPCDS_SF100TCL_Queries) directories. There are simple shell scripts included which can be used with cron to run these on a schedule. These could also be run by hand or using any other method that is acceptable in your context. The only requirement is to run them to make sure there is activity that can be traced to the users. 
6. Once the user activity is set up and running, then run the remaining SQL scripts for each of the three accounts. 

At this stage, you are able to move on to the configuration of the Alation instance. 

Steps to create the Alation parts are as follows:
If using the Alation instance on-premise, install the Alation.  This is not required if using an Alation cloud-managed instance.
Restore the instance backup file.
Switch on Alation Analytics.
Copy the data quality test harness python script file to the Alation one_off_scripts directory using the Alation shell.
Use CRON to schedule the data quality test harness python script file to execute once an hour.
Copy all policy bot python script files to the Alation one_off_scripts directory using the Alation shell.
Use CRON to schedule each policy bot python script file to execute once every 15 minutes.
Create an Entitlement Audit Report using a BI tool that queries Alation Analytics and embed the report in the catalog page entitled Entitlement Audit Tracking.
