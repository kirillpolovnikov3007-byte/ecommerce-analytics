/*
Проект: Анализ данных интернет-магазина
Раздел: Динамика продаж

Цель:
Изучить изменение количества заказов,
выручки и среднего чека за 2021–2025 годы.

Гипотезы:
1. Количество заказов ежегодно растёт.
2. В продажах присутствует сезонность.
3. Средний чек увеличивается со временем.

Метрики:
1. Количество заказов.
2. MoM — изменение к предыдущему месяцу.
3. YoY — изменение к аналогичному периоду прошлого года.
4. Выручка в USD.
5. Средний чек (AOV) в USD.
*/

WITH monthly_orders AS (
    SELECT
        DATE_TRUNC('month', order_date::date)::date AS order_month,
        COUNT(*) AS orders_count
    FROM raw.orders
    GROUP BY 1
),
mom_growth as(SELECT
    order_month,
    orders_count,
    LAG(orders_count, 1) OVER (
    ORDER BY order_month
) AS previous_month_orders,
	LAG(orders_count, 12) OVER (
    ORDER BY order_month
) AS previous_year_orders
FROM monthly_orders
)
select 
order_month,
orders_count,
previous_month_orders,
previous_year_orders,
ROUND(
    (orders_count - previous_month_orders) * 100.0
    / NULLIF(previous_month_orders, 0),
    2
) AS mom_growth_pct,
ROUND(
    (orders_count - previous_year_orders) * 100.0
    / NULLIF(previous_year_orders, 0),
    2
) AS yoy_growth_pct
from mom_growth
ORDER BY order_month;

with year_orders as(select 
extract(year from order_date::date) as order_year,
count(*) as orders_count,
sum(quantity) as total_quantity
from raw.orders
group by 1
),
yoy_growth as (select
order_year,
orders_count,
total_quantity,
lag(orders_count) over(order by order_year) as previous_year_orders
from year_orders
)
select 
order_year,
orders_count,
total_quantity,
previous_year_orders,
round((orders_count - previous_year_orders) *100.0 / nullif(previous_year_orders, 0), 2) as yoy_growth_pct
FROM yoy_growth
ORDER BY order_year;

SELECT
    EXTRACT(YEAR FROM order_date::date)::int AS order_year,
    COUNT(*) AS orders_count,
    ROUND(
        SUM(net_sales::numeric),
        2
    ) AS total_revenue,
    ROUND(
        SUM(net_sales::numeric) / NULLIF(COUNT(*), 0),
        2
    ) AS avg_order_value
FROM raw.orders
WHERE currency = 'USD'
GROUP BY 1
ORDER BY 1;

/*
РЕЗУЛЬТАТЫ ИССЛЕДОВАНИЯ

1. Количество заказов демонстрирует сезонность:
   наиболее высокие показатели наблюдаются
   в ноябре и декабре.

2. В декабре 2025 года оформлено 3 468 заказов:
   MoM = +8,68%, YoY = +0,73%.

3. Выручка в USD за 2021–2025 годы
   снизилась примерно на 1,06%.

4. Средний чек снизился примерно на 1,51%.

ВЫВОД

Гипотеза об устойчивом ежегодном росте
количества заказов не подтвердилась.

Гипотеза о сезонности подтвердилась.

Гипотеза о росте среднего чека
не подтвердилась.

БИЗНЕС-РЕКОМЕНДАЦИИ

1. Планировать запасы и ресурсы с учётом
   повышенного спроса в ноябре и декабре.

2. Исследовать причины снижения среднего чека.

3. Анализировать YoY наряду с MoM,
   чтобы не путать сезонность с ростом бизнеса.

ОГРАНИЧЕНИЯ

Денежные показатели рассчитаны только
по заказам в USD без конвертации валют.

В исходных данных выявлены расхождения
между суммами заказов и товарных позиций.
Поэтому финансовые результаты
требуют дополнительной сверки.
*/