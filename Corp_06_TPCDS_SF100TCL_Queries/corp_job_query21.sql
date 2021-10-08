alter session set query_tag='corp_job query21';
use role CORP_BIZ_USER; 
use database CORP_DATA; 
use schema CORP_SCHEMA; 
use warehouse DATAGOV;

select  *
 from(select w_warehouse_name
            ,i_item_id
            ,sum(case when (cast(d_date as date) < cast ('1998-04-08' as date))
	                then inv_quantity_on_hand 
                      else 0 end) as inv_before
            ,sum(case when (cast(d_date as date) >= cast ('1998-04-08' as date))
                      then inv_quantity_on_hand 
                      else 0 end) as inv_after
   from CORP_DATA.CORP_SCHEMA.INVENTORY inventory
       ,CORP_DATA.CORP_SCHEMA.WAREHOUSE warehouse
       ,CORP_DATA.CORP_SCHEMA.ITEM item
       ,CORP_DATA.CORP_SCHEMA.DATE_DIM date_dim
   where i_current_price between 0.99 and 1.49
     and i_item_sk          = inv_item_sk
     and inv_warehouse_sk   = w_warehouse_sk
     and inv_date_sk    = d_date_sk
     --and d_date between (cast ('1998-04-08' as date) - interval '30' days)
     --               and (cast ('1998-04-08' as date) + interval '30' days)
     and d_date between (dateadd(day, -30, to_date('1998-04-08')))
                    and (dateadd(day, 30, to_date('1998-04-08')))
      group by w_warehouse_name, i_item_id) x
 where (case when inv_before > 0 
             then inv_after / inv_before 
             else null
             end) between 2.0/3.0 and 3.0/2.0
 order by w_warehouse_name
         ,i_item_id
 limit 100; 
