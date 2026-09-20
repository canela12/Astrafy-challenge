{% test within_order_period(model, include_previous_year=false) %}

select order_id, order_date
from {{ model }}
where order_date <
    {% if include_previous_year %}
        date_sub(date_trunc(date('{{ var("start_date") }}'), year), interval 1 year)
    {% else %}
        date_trunc(date('{{ var("start_date") }}'), year)
    {% endif %}
    or order_date > date('{{ var("end_date") }}')

{% endtest %}
