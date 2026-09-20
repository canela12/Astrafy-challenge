{{ config(
    materialized='table',
    incremental_strategy='insert_overwrite',
    partition_by={
        'field': 'order_date',
        'data_type': 'date'
    },
    cluster_by=['order_id', 'product_id', 'customer_id'],
    dataset='STG'
) }}

/* I would like a incremental with insert_overwrite strategy but
I do not access to DML statements in
BigQuery, so I will use a table materialization instead of incremental. */

select
    date_date as order_date,
    customer_id,
    order_id,
    products_id as product_id,
    net_sales,
    qty
from {{ source('google_sheets', 'sales_recrutement') }}
