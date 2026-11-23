/*
Проект: Анализ данных интернет-магазина
Раздел: Анализ товаров и товарных категорий

Цель:
Определить наиболее прибыльные товары и категории,
сравнить их выручку, прибыль и маржинальность.

Период исследования: 2021–2025 годы.
Валюта: USD.

Гипотеза:
Категории с высокой маржинальностью
приносят наибольшую суммарную прибыль.
*/
select 
oi.product_id,
pc.product_category,
sum(oi.quantity) as total_quantity,
count(distinct oi.order_id) as order_counts,
round(sum(oi.net_sales::numeric), 2) as total_revenue,
round(sum(oi.profit::numeric), 2) as total_profit,
round(sum(oi.profit::numeric)/ nullif(sum(oi.quantity::numeric), 0), 2) as profit_per_unit,
round(sum(oi.profit::numeric) * 100.0 / nullif(sum(oi.net_sales::numeric), 0), 2) as profit_margin_pct
from raw.order_items as oi
join raw.orders as o on o.order_id = oi.order_id
JOIN raw.product_catalog AS pc
    ON oi.product_id = pc.product_id
where o.currency = 'USD'
group by oi.product_id, pc.product_category
order by total_profit desc, oi.product_id
limit 10;

with category_metrics as(select
pc.product_category,
count(distinct pc.product_id) as product_count,
sum(oi.quantity) as total_quantity,
count(distinct o.order_id) as orders_counts,
sum(oi.net_sales::numeric)  as total_revenue,
sum(oi.profit::numeric) as total_profit,
sum(oi.profit::numeric) * 100.0 / nullif(sum(oi.net_sales::numeric), 0) as profit_margin_pct,
sum(oi.profit::numeric) / nullif(sum(oi.quantity::numeric), 0) as profit_per_unit
from raw.product_catalog as pc
join raw.order_items as oi on pc.product_id = oi.product_id
join raw.orders as o on oi.order_id = o.order_id
where o.currency = 'USD'
group by pc.product_category
)
select
*,
round(total_revenue::numeric * 100.0 / sum(total_revenue::numeric) over(), 2)as revenue_share_pct,
round(total_profit::numeric * 100.0 / sum(total_profit::numeric) over(), 2) as profit_share_pct
from category_metrics
order by total_profit desc;

/*
РЕЗУЛЬТАТЫ ИССЛЕДОВАНИЯ

1. Самый прибыльный товар — PROD-000051.
   Его суммарная прибыль составляет 222 535 USD.

2. Самая прибыльная категория — Electronics.
   Прибыль составляет около 7,65 млн USD.

3. Маржинальность Electronics составляет 32,22%,
   что не является максимальным значением
   среди товарных категорий.

ВЫВОД

Гипотеза о том, что категории с высокой
маржинальностью обязательно приносят
максимальную суммарную прибыль,
не подтвердилась.

При анализе ассортимента важно учитывать
не только маржинальность, но и объём продаж,
выручку и абсолютную прибыль.

БИЗНЕС-РЕКОМЕНДАЦИИ

1. Поддерживать наличие наиболее прибыльных товаров.
2. Анализировать категории одновременно по прибыли
   и маржинальности.
3. Изучить возможности увеличения продаж
   высокомаржинальных товаров.

ОГРАНИЧЕНИЯ

Финансовые показатели предварительные из-за
выявленных расхождений в исходных данных.
*/


