/*
Проект: Анализ данных интернет-магазина
Раздел: ABC-анализ товарного ассортимента

Цель:
Определить, какие товары формируют основную прибыль
и распределить ассортимент по группам A, B и C.

Период исследования: 2021–2025 годы.
Валюта анализа: USD.

Гипотеза:
20% товаров обеспечивают 80% общей прибыли.
*/

WITH product_metrics AS (
    SELECT
        pc.product_id,
        pc.product_category,
        SUM(oi.quantity) AS total_quantity,
        SUM(oi.net_sales::numeric) AS total_revenue,
        SUM(oi.profit::numeric) AS total_profit
    FROM raw.product_catalog AS pc
    JOIN raw.order_items AS oi
        ON pc.product_id = oi.product_id
    JOIN raw.orders AS o
        ON oi.order_id = o.order_id
    WHERE o.currency = 'USD'
    GROUP BY pc.product_id, pc.product_category
),

product_abc AS (
    SELECT
        product_id,
        product_category,
        total_profit,

        total_profit * 100.0 /
            NULLIF(SUM(total_profit) OVER (), 0)
            AS profit_share_pct,

        SUM(total_profit) OVER (
            ORDER BY total_profit DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_profit,

        SUM(total_profit) OVER (
            ORDER BY total_profit DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) * 100.0 /
            NULLIF(SUM(total_profit) OVER (), 0)
            AS cumulative_profit_pct

    FROM product_metrics
),

abc_classification AS (
    SELECT
        *,
        CASE
            WHEN cumulative_profit_pct <= 80 THEN 'A'
            WHEN cumulative_profit_pct <= 95 THEN 'B'
            ELSE 'C'
        END AS group_abc
    FROM product_abc
)

SELECT
    group_abc,
    COUNT(*) AS product_count,

    ROUND(
        COUNT(*) * 100.0 /
        NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS products_share_pct,

    ROUND(SUM(total_profit), 2) AS total_profit,

    ROUND(
        SUM(total_profit) * 100.0 /
        NULLIF(SUM(SUM(total_profit)) OVER (), 0),
        2
    ) AS profit_share_pct,

    ROUND(AVG(total_profit), 2) AS avg_profit_per_product

FROM abc_classification
GROUP BY group_abc
ORDER BY group_abc;

/*
РЕЗУЛЬТАТЫ ИССЛЕДОВАНИЯ

Группа A:
562 товара (47,83% ассортимента)
формируют 79,98% общей прибыли.

Группа B:
329 товаров (28,00% ассортимента)
формируют 15,01% общей прибыли.

Группа C:
284 товара (24,17% ассортимента)
формируют 5,02% общей прибыли.

ВЫВОД

Гипотеза о распределении прибыли по принципу
Парето 80/20 не подтвердилась.

Для формирования около 80% прибыли требуется
почти половина товарного ассортимента.

РЕКОМЕНДАЦИИ

1. Обеспечивать наличие наиболее прибыльных товаров группы A.
2. Изучить потенциал увеличения продаж товаров группы B.
3. Для группы C дополнительно оценить оборачиваемость
   и затраты на хранение.

ОГРАНИЧЕНИЯ

Финансовые результаты предварительные:
в исходных данных обнаружены расхождения между
суммами заказов и товарных позиций.
*/