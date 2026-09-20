{% set start_date = modules.datetime.date.fromisoformat(var('start_date')) %}
{% set end_date = modules.datetime.date.fromisoformat(var('end_date')) %}

{{ config(
    materialized='table',
    partition_by={
        'field': 'order_date',
        'data_type': 'date'
    },
    cluster_by=['order_id', 'order_segmentation', 'customer_id'],
) }}

with orders as (
    select
        order_date,
        customer_id,
        order_id,
        net_sales
    from {{ ref('stg_orders_recrutement') }}
    where
        order_date between date_trunc(
            "{{ start_date }}", year
        ) and "{{ end_date }}"
),

dim_orders as (
    select
        order_id,
        order_segmentation
    from {{ ref('dim_orders') }}
    where
        order_date between date_trunc(
            "{{ start_date }}", year
        ) and "{{ end_date }}"
)


select
    order_date,
    customer_id,
    orders.order_id,
    net_sales,
    coalesce(order_segmentation, "N/A") as order_segmentation
from orders
left join dim_orders on orders.order_id = dim_orders.order_id
