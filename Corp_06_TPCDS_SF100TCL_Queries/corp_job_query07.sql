alter session set query_tag='corp_job query07';
use role CORP_BIZ_USER; 
use database CORP_DATA; 
use schema CORP_SCHEMA; 
use warehouse DATAGOV;

select  i_item_id, 
        avg(ss_quantity) agg1,
        avg(ss_list_price) agg2,
        avg(ss_coupon_amt) agg3,
        avg(ss_sales_price) agg4 
 from 
    CORP_DATA.CORP_SCHEMA.STORE_SALES_RET store_sales, 
    CORP_DATA.CORP_SCHEMA.CUSTOMER_DEMOGRAPHICS_FIN customer_demographics, 
    CORP_DATA.CORP_SCHEMA.DATE_DIM date_dim, 
    CORP_DATA.CORP_SCHEMA.ITEM item, 
    CORP_DATA.CORP_SCHEMA.PROMOTION_RET promotion
 where ss_sold_date_sk = d_date_sk and
       ss_item_sk = i_item_sk and
       ss_cdemo_sk = cd_demo_sk and
       ss_promo_sk = p_promo_sk and
       cd_gender = 'F' and 
       cd_marital_status = 'W' and
       cd_education_status = 'Primary' and
       (p_channel_email = 'N' or p_channel_event = 'N') and
       d_year = 1998 
 group by i_item_id
 order by i_item_id
 limit 100;
