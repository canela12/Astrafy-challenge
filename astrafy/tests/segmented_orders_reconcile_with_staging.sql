-- Validate both outputs against every source order in the reporting period.
-- Also catches dimension rows that never appear in the final fact.
with expected as (
    select
        order_id,
        customer_id,
        order_date,
        net_sales
    from {{ ref('stg_orders_recrutement') }}
    where
        order_date between date_trunc(date('{{ var("start_date") }}'), year)
        and date('{{ var("end_date") }}')
)

select
    segment.order_segmentation as expected_segment,
    actual.order_segmentation as actual_segment,
    coalesce(expected.order_id, segment.order_id, actual.order_id) as order_id
from expected
full outer join {{ ref('dim_orders') }} as segment
    on expected.order_id = segment.order_id
full outer join {{ ref('fac_orders_segment') }} as actual
    on coalesce(expected.order_id, segment.order_id) = actual.order_id
where
    expected.order_id is null
    or segment.order_id is null
    or actual.order_id is null
    or expected.order_date is distinct from segment.order_date
    or expected.order_date is distinct from actual.order_date
    or expected.customer_id is distinct from actual.customer_id
    or expected.net_sales is distinct from actual.net_sales
    or segment.order_segmentation is distinct from actual.order_segmentation
