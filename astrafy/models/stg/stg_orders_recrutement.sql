{{ config(
    materialized='table',
    partition_by={
        'field': 'order_date',
        'data_type': 'date'
    },
    cluster_by=['order_id', 'customer_id'],
    dataset='STG'
) }}

/* I would like a incremental with insert_overwrite strategy but
I do not access to DML statements in
BigQuery, so I will use a table materialization instead of incremental. */

select
    date_date as order_date,
    customers_id as customer_id,
    orders_id as order_id,
    net_sales
from {{ source('google_sheets', 'orders_recrutement') }}
