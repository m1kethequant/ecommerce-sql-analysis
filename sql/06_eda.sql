-- Исследовательский анализ данных (EDA)

-- Выбор базы данных

USE ecommerce_analysis;

-- Основные показатели

-- Рассчитываю основные показатели продаж:
-- общую выручку, количество заказов, количество клиентов
-- и средний чек.

SELECT
ROUND(SUM(Revenue), 2) AS total_revenue,
COUNT(DISTINCT InvoiceNo) AS total_orders,
COUNT(DISTINCT CustomerID) AS total_customers,
ROUND(SUM(Revenue) / COUNT(DISTINCT InvoiceNo), 2) AS AOV
FROM online_retail_clean;

-- Проверка временных признаков

-- Проверяю диапазон часов, в которые совершались покупки.

SELECT
MIN(Hour) AS min_hour,
MAX(Hour) AS max_hour
FROM online_retail_clean;

-- Динамика продаж
-- Месячные показатели

-- Рассчитываю выручку, количество заказов и средний чек
-- по месяцам.
-- Дополнительно рассчитываю изменение каждого показателя относительно предыдущего месяца (MoM).

WITH monthly_stats AS (
SELECT
YearMonth,
SUM(Revenue) AS monthly_revenue,
COUNT(DISTINCT InvoiceNo) AS monthly_orders,
ROUND(SUM(Revenue) / COUNT(DISTINCT InvoiceNo), 2) AS monthly_AOV
FROM online_retail_clean
GROUP BY YearMonth),
monthly_with_lag AS (
SELECT
YearMonth,
monthly_revenue,
monthly_orders,
monthly_AOV,
LAG(monthly_revenue) OVER (ORDER BY YearMonth) AS previous_revenue,
LAG(monthly_orders) OVER (ORDER BY YearMonth) AS previous_orders,
LAG(monthly_AOV) OVER (ORDER BY YearMonth) AS previous_AOV
FROM monthly_stats)
SELECT
YearMonth,
monthly_revenue,
monthly_orders,
monthly_AOV,
ROUND((monthly_revenue - previous_revenue) / previous_revenue * 100, 2) AS MoM_revenue,
ROUND((monthly_orders - previous_orders) / previous_orders * 100, 2) AS MoM_orders,
ROUND((monthly_AOV - previous_AOV) / previous_AOV * 100, 2) AS MoM_AOV
FROM monthly_with_lag
ORDER BY YearMonth;

-- Анализ заказов
-- Выручка по каждому заказу

-- Для каждого заказа рассчитываю его общую выручку.

SELECT
InvoiceNo,
ROUND(SUM(Revenue), 2) AS order_revenue
FROM online_retail_clean
GROUP BY InvoiceNo
ORDER BY order_revenue DESC;

-- Распределение выручки по заказам

-- Рассчитываю основные статистики распределения выручки по заказам.

WITH order_stats AS (
SELECT
InvoiceNo,
SUM(Revenue) AS order_revenue
FROM online_retail_clean
GROUP BY InvoiceNo)
SELECT
COUNT(*) AS orders,
ROUND(MIN(order_revenue), 2) AS min_order_revenue,
ROUND(AVG(order_revenue), 2) AS avg_order_revenue,
ROUND(STDDEV_SAMP(order_revenue), 2) AS std_order_revenue,
ROUND(MAX(order_revenue), 2) AS max_order_revenue
FROM order_stats;


-- География продаж

-- Для каждой страны рассчитываю:
-- выручку, количество заказов, количество проданных единиц и долю страны в общей выручке.

SELECT
Country,
ROUND(SUM(Revenue), 2) AS country_revenue,
COUNT(DISTINCT InvoiceNo) AS country_orders,
SUM(Quantity) AS country_quantity,
ROUND(SUM(Revenue) / SUM(SUM(Revenue)) OVER () * 100, 2) AS revenue_share
FROM online_retail_clean
GROUP BY Country
ORDER BY country_revenue DESC;

-- Продажи без Великобритании
-- Убираю United Kingdom, чтобы подробнее рассмотреть распределение продаж между остальными странами.

SELECT
Country,
ROUND(SUM(Revenue), 2) AS country_revenue,
COUNT(DISTINCT InvoiceNo) AS country_orders,
SUM(Quantity) AS country_quantity,
ROUND(SUM(Revenue) / SUM(SUM(Revenue)) OVER () * 100, 2) AS revenue_share
FROM online_retail_clean
WHERE Country <> 'United Kingdom'
GROUP BY Country
ORDER BY country_revenue DESC;


-- Покупательская активность в течение дня

-- Рассчитываю показатели продаж по часам:
-- выручку, количество заказов, количество проданных единиц и средний чек.

SELECT
Hour,
ROUND(SUM(Revenue), 2) AS hour_revenue,
COUNT(DISTINCT InvoiceNo) AS hour_orders,
SUM(Quantity) AS hour_quantity,
ROUND(SUM(Revenue) / COUNT(DISTINCT InvoiceNo), 2) AS hour_AOV
FROM online_retail_clean
GROUP BY Hour
ORDER BY Hour;


-- Анализ товаров

-- На этапе проверки данных были выявлены артикулы, связанные со служебными операциями.
-- Для рейтинга товаров исключаю только заранее выявленные служебные коды.

WITH product_stats AS (
SELECT
StockCode,
ROUND(SUM(Revenue), 2) AS product_revenue,
COUNT(DISTINCT InvoiceNo) AS product_orders,
SUM(Quantity) AS product_quantity
FROM online_retail_clean
WHERE StockCode NOT IN ('DOT', 'M', 'm', 'POST', 'AMAZONFEE', 'B', 'BANK CHARGES', 'C2', 'S')
GROUP BY StockCode),
description_map AS (
SELECT
StockCode,
Description,
ROW_NUMBER() OVER (PARTITION BY StockCode ORDER BY InvoiceDate) AS rn
FROM online_retail_clean),
product_data AS (
SELECT
p.StockCode,
d.Description,
p.product_revenue,
p.product_orders,
p.product_quantity
FROM product_stats p
LEFT JOIN description_map d
ON p.StockCode = d.StockCode AND d.rn = 1)
SELECT
StockCode,
Description,
product_revenue,
product_orders,
product_quantity
FROM product_data
WHERE StockCode <> '23843'
ORDER BY product_revenue DESC
LIMIT 10;

-- Дополнительный анализ товаров по количеству

-- Отдельно рассматриваю товары с наибольшим количеством проданных единиц.
-- Это позволяет сравнить лидеров по объёму продаж и лидеров по выручке.

WITH product_stats AS (
SELECT
StockCode,
ROUND(SUM(Revenue), 2) AS product_revenue,
COUNT(DISTINCT InvoiceNo) AS product_orders,
SUM(Quantity) AS product_quantity
FROM online_retail_clean
WHERE StockCode NOT IN ('DOT', 'M', 'm','POST', 'AMAZONFEE', 'B', 'BANK CHARGES', 'C2', 'S')
GROUP BY StockCode),
description_map AS (
SELECT
StockCode,
Description,
ROW_NUMBER() OVER (PARTITION BY StockCode ORDER BY InvoiceDate) AS rn
FROM online_retail_clean)
SELECT
p.StockCode,
d.Description,
p.product_revenue,
p.product_orders,
p.product_quantity
FROM product_stats p
LEFT JOIN description_map d
ON p.StockCode = d.StockCode AND d.rn = 1
WHERE p.StockCode <> '23843'
ORDER BY p.product_quantity DESC
LIMIT 10;

