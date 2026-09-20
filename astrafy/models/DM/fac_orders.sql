{% set start_date = modules.datetime.date.fromisoformat(var('start_date')) %}
{% set end_date = modules.datetime.date.fromisoformat(var('end_date')) %}

{{ config(
    materialized='table',
    partition_by={
        'field': 'order_date',
        'data_type': 'date'
    },
    cluster_by=['order_id', 'customer_id'],
) }}

with orders as (
    select
        order_date,
        customer_id,
        order_id,
        net_sales
    from {{ ref('stg_orders_recrutement') }}
    where
        order_date between date_sub(
            date_trunc("{{ start_date }}", year), interval 1 year
        ) and "{{ end_date }}"
),

order_qty as (
    select
        order_id,
        sum(qty) as qty_product
    from {{ ref('stg_sales_recrutement') }}
    where
        order_date between date_sub(
            date_trunc("{{ start_date }}", year), interval 1 year
        ) and "{{ end_date }}"
    group by 1
)

select
    order_date,
    customer_id,
    order_id,
    net_sales,
    coalesce(qty_product, 0) as qty_product
from orders
left join order_qty on orders.order_id = order_qty.order_id
