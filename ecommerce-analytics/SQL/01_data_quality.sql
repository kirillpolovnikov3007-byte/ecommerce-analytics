/*
Проект: Анализ данных интернет-магазина
Раздел: Проверка качества данных

Цель:
Проверить целостность исходных данных перед анализом продаж, клиентов
и товарного ассортимента. Выявить ограничения, способные повлиять
на достоверность аналитических выводов.

Гипотеза:
Ключевые идентификаторы и связи между таблицами корректны,
а сумма заказа совпадает с суммой его товарных позиций.

Источники данных:
- raw.orders           — заказы;
- raw.order_items      — товарные позиции в заказах;
- raw.customer_master  — справочник клиентов;
- raw.product_catalog  — каталог товаров.

Период исследования:
2021-2025
*/

-- Задача: найти дубликаты order_id и пропуски в order_id / customer_id.
SELECT
    COUNT(*) AS orders_count,
    COUNT(DISTINCT order_id) AS unique_orders_count,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_orders_count,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_count
FROM raw.orders;
    
/*
Результаты:
- Всего заказов: 138 116.
- Уникальных order_id: 138 116.
- Пропусков order_id: 0.
- Пропусков customer_id: 0.

Вывод:
Дублирующиеся идентификаторы заказов
и пропуски в проверенных ключевых полях
не обнаружены.
*/

-- Задача: найти заказы без соответствующей записи в справочнике клиентов.
SELECT
    COUNT(*) AS orders_without_customer
FROM raw.orders AS o
LEFT JOIN raw.customer_master AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

/*
Результат:
Заказов без соответствующего клиента — 0.

Вывод:
Все заказы связаны с существующими
записями в справочнике клиентов.
*/

-- Задача: найти позиции с product_id, отсутствующим в product_catalog.
SELECT
    COUNT(*) AS order_items_without_product
FROM raw.order_items AS oi
LEFT JOIN raw.product_catalog AS p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

/*
Результат:
Товарных позиций без товара в каталоге: 0.

Вывод:
Для всех товарных позиций найден соответствующий товар в каталоге.
*/

-- Задача: найти позиции, для которых отсутствует заказ в raw.orders.
SELECT
    COUNT(*) AS order_items_without_orders
FROM raw.order_items AS oi
LEFT JOIN raw.orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

/*
Результат:
Товарных позиций без соответствующего заказа: 0.

Вывод:
Каждая товарная позиция связана с существующим заказом.
*/

-- Задача: сравнить raw.orders.net_sales с суммой raw.order_items.net_sales
-- по каждому order_id и определить долю заказов с расхождением > 0.02.
-- Приведение к numeric выполняется ДО SUM для снижения ошибок накопления.
-- Отдельно считаются заказы, для которых не найдены товарные позиции.

WITH total_items AS (
    SELECT
        order_id,
        SUM(net_sales::numeric) AS items_net_sales
    FROM raw.order_items
    GROUP BY order_id
),
order_differences AS (
    SELECT
        o.order_id,
        o.net_sales::numeric AS order_net_sales,
        ti.items_net_sales,
        o.net_sales::numeric - ti.items_net_sales AS diff
    FROM raw.orders AS o
    LEFT JOIN total_items AS ti
        ON o.order_id = ti.order_id
)
SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (
        WHERE items_net_sales IS NULL
    ) AS orders_without_items,
    COUNT(*) FILTER (
        WHERE ABS(diff) > 0.02
    ) AS orders_with_difference,
    ROUND(
        COUNT(*) FILTER (WHERE ABS(diff) > 0.02) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS difference_pct
FROM order_differences;

/*
Результат:
Всего заказов:                            138 116
Заказов без товарных позиций:             0
Заказов с расхождением > 0.02:           11 236
Доля заказов с расхождением:              8.14%

Выводы:
У 8.14% заказов суммы net_sales на уровне заказа и товарных позиций
различаются более чем на установленный порог.

Это не доказывает наличие ошибок в конкретных заказах: различия могут
быть связаны с бизнес-правилами расчёта или особенностями источника.
Причина расхождений требует отдельного исследования.
*/


/*
ИТОГИ ПРОВЕРКИ КАЧЕСТВА ДАННЫХ

1. В таблице orders обнаружено 138 116 заказов.
2. Дубликатов order_id не обнаружено.
3. Пропусков order_id и customer_id нет.
4. Заказов без клиента в справочнике нет.
5. Товарных позиций без соответствующего заказа нет.
6. Товарных позиций без товара в каталоге
   не обнаружено.
7.Заказов без товарных позиций не обнаружено.

ОСНОВНАЯ ПРОБЛЕМА

В 11 236 заказах (8,14%) обнаружено
расхождение между суммой заказа
и суммой его товарных позиций.

Порог существенности для проверки:
абсолютная разница более 0,02.

ВЫВОД

Структурные проверки ключей и связей
не выявили проблем.

Однако денежные показатели
имеют расхождения, причина которых
не установлена.

БИЗНЕС-РЕКОМЕНДАЦИИ

1. Уточнить правила расчёта net_sales.
2. Проверить возможное влияние возвратов,
   отмен и корректировок заказов.
3. Сверить суммы с первичными источниками.
4. До устранения расхождений считать
   финансовые выводы предварительными.

ОГРАНИЧЕНИЯ

В таблицах используются денежные значения
с плавающей точкой.

Для агрегирования применяется
приведение к numeric до SUM.

Проверка не устанавливает причины
обнаруженных расхождений.
*/

