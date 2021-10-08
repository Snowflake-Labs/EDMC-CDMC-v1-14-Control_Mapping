alter session set query_tag='corp_job query22';
use role CORP_BIZ_USER; 
use database CORP_DATA; 
use schema CORP_SCHEMA; 
use warehouse DATAGOV;

select  i_product_name
             ,i_brand
             ,i_class
             ,i_category
             ,avg(inv_quantity_on_hand) qoh
       from CORP_DATA.CORP_SCHEMA.INVENTORY inventory
           ,CORP_DATA.CORP_SCHEMA.DATE_DIM date_dim
           ,CORP_DATA.CORP_SCHEMA.ITEM item
       where inv_date_sk=d_date_sk
              and inv_item_sk=i_item_sk
              and d_month_seq between 1212 and 1212 + 11
       group by rollup(i_product_name
                       ,i_brand
                       ,i_class
                       ,i_category)
order by qoh, i_product_name, i_brand, i_class, i_category
limit 100;
