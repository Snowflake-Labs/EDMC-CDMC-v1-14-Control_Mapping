alter session set query_tag='ret_job query06';
use role RET_BIZ_USER; 
use database RET_DATA; 
use schema RET_SCHEMA; 
use warehouse DATAGOV;

select  a.ca_state state, count(*) cnt
 from RET_DATA.RET_SCHEMA.CUSTOMER_ADDRESS_CORP a
     ,RET_DATA.RET_SCHEMA.CUSTOMER_CORP c
     ,RET_DATA.RET_SCHEMA.STORE_SALES s
     ,RET_DATA.RET_SCHEMA.DATE_DIM_CORP d
     ,RET_DATA.RET_SCHEMA.ITEM_CORP i
 where       a.ca_address_sk = c.c_current_addr_sk
 	and c.c_customer_sk = s.ss_customer_sk
 	and s.ss_sold_date_sk = d.d_date_sk
 	and s.ss_item_sk = i.i_item_sk
 	and d.d_month_seq = 
 	     (select distinct (d_month_seq)
 	      from RET_DATA.RET_SCHEMA.DATE_DIM_CORP
               where d_year = 2000
 	        and d_moy = 2 )
 	and i.i_current_price > 1.2 * 
             (select avg(j.i_current_price) 
 	     from RET_DATA.RET_SCHEMA.ITEM_CORP j 
 	     where j.i_category = i.i_category)
 group by a.ca_state
 having count(*) >= 10
 order by cnt, a.ca_state 
 limit 100;
