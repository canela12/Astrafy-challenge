-- Relationships tests cover missing headers. This checks their shared 
-- attributes.
select
    sales.order_id,
    sales.product_id,
    sales.customer_id as sales_customer_id,
    orders.customer_id as order_customer_id,
    sales.order_date as sales_order_date,
    orders.order_date as header_order_date
from {{ ref('stg_sales_recrutement') }} as sales
inner join {{ ref('stg_orders_recrutement') }} as orders
    on sales.order_id = orders.order_id
where
    sales.customer_id is distinct from orders.customer_id
    or sales.order_date is distinct from orders.order_date
