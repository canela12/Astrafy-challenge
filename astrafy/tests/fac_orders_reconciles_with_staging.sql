-- Check missing/extra orders, preserved header values and quantity aggregation.
-- A full join catches dropped orders as well as unexpected output rows.
with expected as (
    select
        orders.order_id,
        orders.customer_id,
        orders.order_date,
        orders.net_sales,
        coalesce(sum(sales.qty), 0) as qty_product
    from {{ ref('stg_orders_recrutement') }} as orders
    left join {{ ref('stg_sales_recrutement') }} as sales
        on
            orders.order_id = sales.order_id
            and sales.order_date between
            date_sub(
                date_trunc(date('{{ var("start_date") }}'), year),
                interval 1 year
            )
            and date('{{ var("end_date") }}')
    where
        orders.order_date between
        date_sub(
            date_trunc(date('{{ var("start_date") }}'), year), interval 1 year
        )
        and date('{{ var("end_date") }}')
    group by
        orders.order_id, orders.customer_id, orders.order_date, orders.net_sales
)

select
    expected.qty_product as expected_qty,
    actual.qty_product as actual_qty,
    coalesce(expected.order_id, actual.order_id) as order_id
from expected
full outer join {{ ref('fac_orders') }} as actual
    on expected.order_id = actual.order_id
where
    expected.order_id is null
    or actual.order_id is null
    or expected.customer_id is distinct from actual.customer_id
    or expected.order_date is distinct from actual.order_date
    or expected.net_sales is distinct from actual.net_sales
    or expected.qty_product is distinct from actual.qty_product
