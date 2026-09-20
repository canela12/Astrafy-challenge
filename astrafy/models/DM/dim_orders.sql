{% set start_date = modules.datetime.date.fromisoformat(var('start_date')) %}
{% set end_date = modules.datetime.date.fromisoformat(var('end_date')) %}

{{ config(
    materialized='table',
    partition_by={
        'field': 'order_date',
        'data_type': 'date'
    },
    cluster_by=['order_id'],
) }}

with orders as (
    select
        customer_id,
        order_date,
        order_id
    from {{ ref('stg_orders_recrutement') }}
    where
        order_date between date_sub(
            date_trunc("{{ start_date }}", year), interval 1 year
        ) and "{{ end_date }}"
    group by all
),


final as (
    select
        customer_id,
        order_date,
        order_id,
        count(order_id) over (partition by customer_id order by unix_date(order_date) range between 365 preceding and 1 preceding) as count_orders -- to count the number of orders in the last year, we use a window function with a range between 365 preceding and 1 preceding, to avoid counting the current order day -- noqa
    from orders
)

select
    order_date,
    order_id,
    case
        when count_orders = 0 then "New"
        when count_orders between 1 and 3 then "Returning"
        when count_orders > 3 then "VIP"
        else "N/A"
    end as order_segmentation
from final
where order_date >= date_trunc("{{ start_date }}", year)
