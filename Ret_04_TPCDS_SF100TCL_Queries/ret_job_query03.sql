alter session set query_tag='ret_job query03';
use role RET_BIZ_USER; 
use database RET_DATA; 
use schema RET_SCHEMA; 
use warehouse DATAGOV;

select  dt.d_year 
       ,item.i_brand_id brand_id 
       ,item.i_brand brand
       ,sum(ss_ext_sales_price) sum_agg
 from  RET_DATA.RET_SCHEMA.DATE_DIM_CORP dt 
      ,RET_DATA.RET_SCHEMA.STORE_SALES store_sales
      ,RET_DATA.RET_SCHEMA.ITEM_CORP item
 where dt.d_date_sk = store_sales.ss_sold_date_sk
   and store_sales.ss_item_sk = item.i_item_sk
   and item.i_manufact_id = 436
   and dt.d_moy=12
 group by dt.d_year
      ,item.i_brand
      ,item.i_brand_id
 order by dt.d_year
         ,sum_agg desc
         ,brand_id
 limit 100;
