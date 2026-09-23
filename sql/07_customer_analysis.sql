-- Анализ клиентов

-- Выбор базы данных

USE ecommerce_analysis;

-- Основные показатели покупателей

-- Определяю количество строк и покупателей с известным CustomerID.
-- Покупатели без CustomerID не использую в анализе индивидуального поведения, поскольку их невозможно однозначно связать между собой.

SELECT
COUNT(*) AS rows_count,
COUNT(DISTINCT CustomerID) AS customers_count
FROM online_retail_clean
WHERE CustomerID IS NOT NULL;

-- Основные показатели по каждому покупателю:
-- выручка, 
-- количество заказов, 
-- количество купленных единиц
-- средний чек.

SELECT
CustomerID,
ROUND(SUM(Revenue), 2) AS customer_revenue,
COUNT(DISTINCT InvoiceNo) AS customer_orders,
SUM(Quantity) AS customer_quantity,
ROUND(SUM(Revenue) / COUNT(DISTINCT InvoiceNo), 2) AS customer_AOV
FROM online_retail_clean
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY customer_revenue DESC;

-- Концентрация выручки
-- Ранжирую покупателей по выручке и рассчитываю накопленную выручку и её долю в общей выручке
-- покупателей с известным CustomerID.

WITH customer_stats AS (
SELECT
CustomerID,
SUM(Revenue) AS customer_revenue
FROM online_retail_clean
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID),
ranked_customers AS (
SELECT
CustomerID,
customer_revenue,
ROW_NUMBER() OVER (ORDER BY customer_revenue DESC, CustomerID) AS customer_rank,
SUM(customer_revenue) OVER () AS total_revenue
FROM customer_stats)
SELECT
CustomerID,
ROUND(customer_revenue, 2) AS customer_revenue,
customer_rank,
ROUND(SUM(customer_revenue) OVER (ORDER BY customer_rank), 2) AS cumulative_revenue,
ROUND(SUM(customer_revenue) OVER (ORDER BY customer_rank) / total_revenue * 100, 2) AS cumulative_revenue_share
FROM ranked_customers
ORDER BY customer_rank;

-- Концентрация выручки в наиболее крупных группах покупателей
-- Рассчитываю долю общей выручки, которую формируют
-- топ-1%, 5%, 10% и 20% покупателей по выручке.

WITH customer_stats AS (
SELECT
CustomerID,
SUM(Revenue) AS customer_revenue
FROM online_retail_clean
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID),
ranked_customers AS (
SELECT
CustomerID,
customer_revenue,
ROW_NUMBER() OVER (ORDER BY customer_revenue DESC, CustomerID) AS customer_rank,
COUNT(*) OVER () AS total_customers,
SUM(customer_revenue) OVER () AS total_revenue,
SUM(customer_revenue) OVER (ORDER BY customer_revenue DESC, CustomerID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue
FROM customer_stats),
concentration AS (
SELECT
'Топ 1%' AS customer_group,
FLOOR(MAX(total_customers) * 0.01) AS customers_count,
MAX(CASE WHEN customer_rank = FLOOR(total_customers * 0.01) THEN cumulative_revenue END) AS cumulative_revenue,
MAX(total_revenue) AS total_revenue,
1 AS group_order
FROM ranked_customers
UNION ALL
SELECT
'Топ 5%',
FLOOR(MAX(total_customers) * 0.05),
MAX(CASE WHEN customer_rank = FLOOR(total_customers * 0.05) THEN cumulative_revenue END ), 
MAX(total_revenue), 
2
FROM ranked_customers
UNION ALL
SELECT
'Топ 10%',
FLOOR(MAX(total_customers) * 0.10),
MAX(CASE WHEN customer_rank = FLOOR(total_customers * 0.10) THEN cumulative_revenue END),
MAX(total_revenue),
3
FROM ranked_customers
UNION ALL
SELECT
'Топ 20%',
FLOOR(MAX(total_customers) * 0.20),
MAX(CASE WHEN customer_rank = FLOOR(total_customers * 0.20) THEN cumulative_revenue END),
MAX(total_revenue),
4
FROM ranked_customers)
SELECT
customer_group,
customers_count,
ROUND(cumulative_revenue / total_revenue * 100, 1) AS revenue_share
FROM concentration
ORDER BY group_order;

-- Покупатели с одной и повторными покупками

-- Разделяю покупателей на две группы:
-- совершившие только один заказ;
-- совершившие два и более заказа.

WITH customer_stats AS (
SELECT
CustomerID,
SUM(Revenue) AS customer_revenue,
COUNT(DISTINCT InvoiceNo) AS customer_orders,
SUM(Quantity) AS customer_quantity,
SUM(Revenue) / COUNT(DISTINCT InvoiceNo) AS customer_AOV
FROM online_retail_clean
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID),
customer_types AS (
SELECT
*,
CASE WHEN customer_orders = 1 THEN 'One-time' ELSE 'Repeat' END AS customer_type
FROM customer_stats)
SELECT
customer_type,
COUNT(*) AS clients_count,
ROUND(SUM(customer_revenue), 2) AS total_revenue,
ROUND(AVG(customer_revenue), 2) AS avg_revenue,
ROUND(AVG(customer_orders), 2) AS avg_orders,
ROUND(AVG(customer_AOV), 2) AS avg_AOV,
ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 2) AS client_share,
ROUND(SUM(customer_revenue) / SUM(SUM(customer_revenue)) OVER () * 100, 2) AS revenue_share
FROM customer_types
GROUP BY customer_type
ORDER BY CASE
WHEN customer_type = 'One-time' THEN 1
WHEN customer_type = 'Repeat' THEN 2
END;

-- Частота заказов

-- Разбиваю покупателей по количеству совершённых заказов.
-- Это позволяет оценить распределение клиентской базы по частоте покупок.

WITH customer_stats AS (
SELECT
CustomerID,
COUNT(DISTINCT InvoiceNo) AS customer_orders
FROM online_retail_clean
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID),
customer_segments AS (
SELECT
CustomerID,
customer_orders,
CASE WHEN customer_orders = 1 THEN '1'
WHEN customer_orders BETWEEN 2 AND 5 THEN '2–5'
WHEN customer_orders BETWEEN 6 AND 10 THEN '6–10'
WHEN customer_orders BETWEEN 11 AND 20 THEN '11–20'
WHEN customer_orders BETWEEN 21 AND 50 THEN '21–50' ELSE '51+' END AS order_segment,
CASE WHEN customer_orders = 1 THEN 1
WHEN customer_orders BETWEEN 2 AND 5 THEN 2
WHEN customer_orders BETWEEN 6 AND 10 THEN 3
WHEN customer_orders BETWEEN 11 AND 20 THEN 4
WHEN customer_orders BETWEEN 21 AND 50 THEN 5 ELSE 6 END AS segment_order
FROM customer_stats)
SELECT
order_segment,
COUNT(*) AS customers_count
FROM customer_segments
GROUP BY
order_segment,
segment_order
ORDER BY segment_order;


-- Возвраты покупателей

-- Возвраты анализируются на основе исходной таблицы online_retail_raw, поскольку после очистки отрицательные
-- Quantity были исключены из online_retail_clean.
-- В качестве признака отменённой операции используется префикс C в InvoiceNo.


-- Общая статистика по возвратам

SELECT
COUNT(*) AS return_rows,
COUNT(DISTINCT CustomerID) AS customers_with_returns,
COUNT(DISTINCT InvoiceNo) AS return_orders
FROM online_retail_raw
WHERE InvoiceNo LIKE 'C%' AND CustomerID IS NOT NULL;

-- Статистика возвратов по каждому покупателю
-- Рассчитыва. количество возвратных заказов и количество возвращённых единиц товара.

SELECT
CustomerID,
COUNT(DISTINCT InvoiceNo) AS return_orders,
SUM(ABS(Quantity)) AS returned_units
FROM online_retail_raw
WHERE InvoiceNo LIKE 'C%'AND CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY returned_units DESC;

-- Доля покупателей, совершавших хотя бы один возврат

WITH customer_stats AS (
SELECT
CustomerID
FROM online_retail_clean
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID),
return_customers AS (
SELECT
CustomerID
FROM online_retail_raw
WHERE InvoiceNo LIKE 'C%' AND CustomerID IS NOT NULL
GROUP BY CustomerID)
SELECT
COUNT(*) AS customers_with_returns,
(SELECT COUNT(*) FROM customer_stats) AS total_customers,
ROUND(COUNT(*) / (SELECT COUNT(*) FROM customer_stats) * 100, 1) AS return_customers_share
FROM return_customers;

-- Распределение количества возвратов среди покупателей с возвратами

WITH return_stats AS (
SELECT
CustomerID,
COUNT(DISTINCT InvoiceNo) AS return_orders,
SUM(ABS(Quantity)) AS returned_units
FROM online_retail_raw
WHERE InvoiceNo LIKE 'C%' AND CustomerID IS NOT NULL
GROUP BY CustomerID)
SELECT
COUNT(*) AS customer_count,
ROUND(AVG(return_orders), 2) AS avg_return_orders,
ROUND(STDDEV_SAMP(return_orders), 2) AS std_return_orders,
MIN(return_orders) AS min_return_orders,
MAX(return_orders) AS max_return_orders,
ROUND(AVG(returned_units), 2) AS avg_returned_units,
ROUND(STDDEV_SAMP(returned_units), 2) AS std_returned_units,
MIN(returned_units) AS min_returned_units,
MAX(returned_units) AS max_returned_units
FROM return_stats;

-- Медианное количество возвращённых единиц
-- Рассчитыва. медиану количества возвращённых единиц среди покупателей, совершавших возвраты.
-- Медиана используется вместе со средним значением, поскольку распределение возвратов может быть сильно
-- асимметричным из-за крупных операций.

WITH return_stats AS (
SELECT
CustomerID,
SUM(ABS(Quantity)) AS returned_units
FROM online_retail_raw
WHERE InvoiceNo LIKE 'C%'
AND CustomerID IS NOT NULL
GROUP BY CustomerID),
ranked AS (
SELECT
returned_units,
ROW_NUMBER() OVER (ORDER BY returned_units) AS rn,
COUNT(*) OVER () AS n
FROM return_stats)
SELECT
AVG(returned_units) AS median_returned_units
FROM ranked
WHERE rn IN (FLOOR((n + 1) / 2), FLOOR((n + 2) / 2));

