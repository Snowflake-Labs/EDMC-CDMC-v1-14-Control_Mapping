alter session set query_tag='ret_job query01';
use role RET_BIZ_USER; 
use database RET_DATA; 
use schema RET_SCHEMA; 
use warehouse DATAGOV;

with customer_total_return as
(select sr_customer_sk as ctr_customer_sk
,sr_store_sk as ctr_store_sk
,sum(SR_FEE) as ctr_total_return
from RET_DATA.RET_SCHEMA.STORE_RETURNS 
,RET_DATA.RET_SCHEMA.DATE_DIM_CORP 
where sr_returned_date_sk = d_date_sk
and d_year =2000
group by sr_customer_sk
,sr_store_sk)
 select  c_customer_id
from customer_total_return ctr1
,RET_DATA.RET_SCHEMA.STORE 
,RET_DATA.RET_SCHEMA.CUSTOMER_CORP 
where ctr1.ctr_total_return > (select avg(ctr_total_return)*1.2
from customer_total_return ctr2
where ctr1.ctr_store_sk = ctr2.ctr_store_sk)
and s_store_sk = ctr1.ctr_store_sk
and s_state = 'NM'
and ctr1.ctr_customer_sk = c_customer_sk
order by c_customer_id
limit 100;
