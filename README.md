# Astrafy BI Engineer challenge

This repository contains the dbt / BigQuery transformations and the Looker
semantic layer for the take-home challenge.

- [dbt project](astrafy/): source declarations, staging and order marts.
- [Looker setup, architecture and validation](https://github.com/canela12/astrafy_looker)

## Modeling Desicions Justifications

I have uploaded the exports to google drive and leveaged the dbt-labs/dbt_external_tables allowing to schedule the data ingestion process from this source of data. I created the source file where the external files are targetted and added uniquness tests along with nullity checks. The external tables are called 
from the staging models and materializated for improving the performance. The tables are partitioned by date and clusterd with the respective fields. Ideally I would have liked to apply 
the insert_overwrite incremental strategy for the models but since I am using the BigQuery's free tier I do not have access to DML statements. The other models contain date variables to be triggered either manually or from the orchestrator. If the incremental strategy was available I would have created the incremental condition in order to update the table daily or when a backfill was needed. 

Regarding the modeling desing I decided to create two facts and one dimension. Fac_orders agregates at order level the qty from stg_sales_recrutement and combines this calculation with 
stg_orders_recrutement information to deliver the quantity of products per order.

For the last 2 exercices I decided to create a dimension at order level with the segmentation attribute. This gives us flexibility to use this attribute for further use cases related to 
order analysis. Initially I calculate the current year we introduce with the variable, "2026" for our case, and I calculate the previous year since we want to get the date in order to not bring older data wich would decrease our model performance. The attibute was calculated first pulling the information from stg_orders_recrutement at customer_id, order_date, order_id granularity. Next I created a window function
counting how many orders this user had in the last year. I build the function partitioning by user as we want to check how many orders this user had, ordered by date and applied the 
range to this date. A final CTE bucketize the order segment with a case when.

Finally I attach the segment field to the 2026 stg_orders_recrutement data generating fac_orders_segment.

## Repository Overview

For all the models I added a .yml document to describe the fields in BigQuery. There are unit tests dim_orders model as it contains the most delicate logic. Also created a test folder where extra tests for the models are added to ensure the correct model behaviour. I installed elementary wich is a tool performing statistical tests but I needed to disable it in the dbt_project as it demands from DML statements and these are disabeled with my curreny BigQuery plan.

In the .github folder I have added a CI workflows to ensure safe releases. To ensure the code quality I added sqlfluff, with is a linting tool, and is triggered in every commit by the pre-commit mechanism configured in .pre-commit-config.yaml.

## 1-3 Exercice Answers
--What is the number of orders in the year 2026? 1314
select count(distinct order_id) 
from `DM_STG.stg_orders_recrutement`
where order_date >="2026-01-01";

--What is the number of orders per month in the year 2026?
select date_trunc(order_date, month) as month ,count(distinct order_id) as orders 
from `DM_STG.stg_orders_recrutement`
where order_date >="2026-01-01"
group by 1
order by 1;
/*
month	orders
2026-07-01	74
2026-08-01	167
2026-09-01	212
2026-10-01	223
2026-11-01	389
2026-12-01	249*/


-- What is the average number of products per order for each month of the year 2026?

with t1 as (
select
date_trunc(order_date, month) as month, order_id, sum(qty) as total_num_products
from `DM_STG.stg_sales_recrutement`
group by all
order by 1
)

select month, avg(total_num_products) as avg_num_products
from t1 
group by 1
order by 1

/*
month	avg_num_products
2026-07-01	13.716216216
2026-08-01	14.461077844
2026-09-01	13.669811321
2026-10-01	13.02690583
2026-11-01	10.480719794
2026-12-01	11.332*/
