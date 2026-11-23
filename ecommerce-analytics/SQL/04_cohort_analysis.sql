/*
Проект: Анализ данных интернет-магазина
Раздел: Когортный анализ клиентов

Цель:
Изучить возвращаемость клиентов в последующие
месяцы после первого наблюдаемого заказа.

Период исследования: 2021–2025 годы.

Гипотеза:
Клиенты продолжают совершать повторные покупки
в последующие месяцы после первой
наблюдаемой покупки.

Метод:
Когортный анализ по месяцу первого
наблюдаемого заказа.

Основная метрика:
Monthly Retention Rate.

Ограничение:
История заказов начинается с 2021 года,
поэтому первая наблюдаемая покупка
не обязательно является первой в жизни клиента.
*/

with cohort_first_order as (
select
customer_id,
date_trunc('month', min(order_date::date))::date as cohort_month
from raw.orders
group by customer_id
),
all_orders_customers as (
select
o.customer_id,
cfo.cohort_month,
date_trunc('month', order_date::date)::date as order_month
from raw.orders as o
join cohort_first_order as cfo on o.customer_id = cfo.customer_id
),
customer_activity as (select
customer_id,
cohort_month,
order_month,
(
    EXTRACT(YEAR FROM order_month)
    - EXTRACT(YEAR FROM cohort_month)
) * 12
+
(
    EXTRACT(MONTH FROM order_month)
    - EXTRACT(MONTH FROM cohort_month)
) as month_number
from all_orders_customers
),
cohort_activity as (
select
cohort_month,
month_number,
count(distinct customer_id) as activity_customers
from customer_activity
group by cohort_month, month_number
),
retention_data as(
select
cohort_month,
month_number,
activity_customers,
round(activity_customers * 100.0 / nullif(MAX(activity_customers) FILTER (
    WHERE month_number = 0
) OVER (
    PARTITION BY cohort_month
),0), 2 )as retention_pct
from cohort_activity
),
last_month AS (
    SELECT
        DATE_TRUNC('month', MAX(order_date::date))::date AS max_month
    FROM raw.orders
)

SELECT
    rd.cohort_month,

    MAX(rd.retention_pct) FILTER (
        WHERE rd.month_number = 0
    ) AS m0,

    CASE
        WHEN (rd.cohort_month + INTERVAL '1 month')::date <= lm.max_month
        THEN COALESCE(
            MAX(rd.retention_pct) FILTER (WHERE rd.month_number = 1),
            0
        )
        ELSE NULL
    END AS m1,

    CASE
        WHEN (rd.cohort_month + INTERVAL '2 months')::date <= lm.max_month
        THEN COALESCE(
            MAX(rd.retention_pct) FILTER (WHERE rd.month_number = 2),
            0
        )
        ELSE NULL
    END AS m2,

    CASE
        WHEN (rd.cohort_month + INTERVAL '3 months')::date <= lm.max_month
        THEN COALESCE(
            MAX(rd.retention_pct) FILTER (WHERE rd.month_number = 3),
            0
        )
        ELSE NULL
    END AS m3,

    CASE
        WHEN (rd.cohort_month + INTERVAL '4 months')::date <= lm.max_month
        THEN COALESCE(
            MAX(rd.retention_pct) FILTER (WHERE rd.month_number = 4),
            0
        )
        ELSE NULL
    END AS m4,

    CASE
        WHEN (rd.cohort_month + INTERVAL '5 months')::date <= lm.max_month
        THEN COALESCE(
            MAX(rd.retention_pct) FILTER (WHERE rd.month_number = 5),
            0
        )
        ELSE NULL
    END AS m5,

    CASE
        WHEN (rd.cohort_month + INTERVAL '6 months')::date <= lm.max_month
        THEN COALESCE(
            MAX(rd.retention_pct) FILTER (WHERE rd.month_number = 6),
            0
        )
        ELSE NULL
    END AS m6

FROM retention_data AS rd
CROSS JOIN last_month AS lm
GROUP BY rd.cohort_month, lm.max_month
ORDER BY rd.cohort_month;

/*
РЕЗУЛЬТАТЫ ИССЛЕДОВАНИЯ

1. В месяц первого наблюдаемого заказа
   Retention каждой когорты составляет 100%.

2. В последующие месяцы Retention
   значительно ниже — преимущественно 6–12%
   для когорт 2021 года.

3. Наибольший M1 среди когорт 2021 года
   наблюдается у ноября — 13,52%.

4. Повышенная возвращаемость в отдельных
   месяцах может быть связана с сезонностью.

ВЫВОД

Большая доля клиентов совершает повторные
покупки в течение всего периода наблюдения,
однако в отдельно взятом месяце возвращается
сравнительно небольшая часть когорты.

Повторные покупки за пять лет и месячный
Retention — разные показатели.

БИЗНЕС-РЕКОМЕНДАЦИИ

1. Изучить интервалы между покупками.
2. Проверить влияние сезонности на Retention.
3. Исследовать, какие категории товаров
   связаны с более частыми повторными покупками.
4. Проверить гипотезы об увеличении
   возвращаемости клиентов.

ОГРАНИЧЕНИЯ

1. Первая наблюдаемая покупка не обязательно
   является первой покупкой клиента за всё время.

2. Retention отражает активность в конкретном
   месяце, а не непрерывное удержание клиента.

3. Последние когорты имеют более короткий
   доступный период наблюдения.

4. Небольшой размер отдельных когорт
   может приводить к сильным колебаниям
   Retention в процентном выражении.
*/