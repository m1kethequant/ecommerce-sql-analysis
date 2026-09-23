-- Когортный анализ

-- Выбор базы данных

USE ecommerce_analysis;

-- Формирование когорт
-- Клиенты объединяются в когорты по месяцу их первой покупки.
-- PurchaseMonth — месяц конкретной покупки;
-- CohortMonth — месяц первой покупки клиента;
-- CohortIndex — количество месяцев между первой покупкой и текущей покупкой клиента.

-- Когортная таблица

-- Для каждой когорты и каждого месяца рассчитываю:
-- количество активных клиентов, размер когорты и долю сохранивших активность клиентов.

WITH cohort_data AS (
SELECT
CustomerID,
DATE_FORMAT(InvoiceDate, '%Y-%m-01') AS PurchaseMonth
FROM online_retail_clean
WHERE CustomerID IS NOT NULL),
cohort_with_month AS (
SELECT
CustomerID,
PurchaseMonth,
MIN(PurchaseMonth) OVER (PARTITION BY CustomerID) AS CohortMonth
FROM cohort_data),
cohort_data_final AS (
SELECT
CustomerID,
PurchaseMonth,
CohortMonth,
TIMESTAMPDIFF(MONTH, CohortMonth, PurchaseMonth) AS CohortIndex
FROM cohort_with_month),
cohort_counts AS (
SELECT
CohortMonth,
CohortIndex,
COUNT(DISTINCT CustomerID) AS customers
FROM cohort_data_final
GROUP BY
CohortMonth,
CohortIndex),
cohort_sizes AS (
SELECT
CohortMonth,
customers AS cohort_size
FROM cohort_counts
WHERE CohortIndex = 0)
SELECT
CohortMonth,
CohortIndex,
customers AS active_customers,
cohort_size,
ROUND(customers / cohort_size * 100, 1) AS retention
FROM cohort_counts
JOIN cohort_sizes
USING (CohortMonth)
ORDER BY
CohortMonth,
CohortIndex;

-- Когортная матрица удержания клиентов

-- Преобразую когортную таблицу в матричный формат.
-- Строки — когорты по месяцу первой покупки.
-- Столбцы — месяцы относительно первой покупки:
-- 0 — месяц первой покупки;
-- 1 — следующий месяц;
-- 2 — второй месяц после первой покупки;
-- и т.д.

-- Значения показывают долю клиентов когорты,
-- которые совершили покупку в соответствующий месяц.


WITH cohort_data AS (
SELECT
CustomerID,
DATE_FORMAT(InvoiceDate,'%Y-%m-01') AS PurchaseMonth
FROM online_retail_clean
WHERE CustomerID IS NOT NULL),
cohort_with_month AS (
SELECT
CustomerID,
PurchaseMonth,
MIN(PurchaseMonth) OVER (PARTITION BY CustomerID) AS CohortMonth
FROM cohort_data),
cohort_data_final AS (
SELECT
CustomerID,
PurchaseMonth,
CohortMonth,
TIMESTAMPDIFF(MONTH, CohortMonth, PurchaseMonth) AS CohortIndex
FROM cohort_with_month),
cohort_counts AS (
SELECT
CohortMonth,
CohortIndex,
COUNT(DISTINCT CustomerID) AS customers
FROM cohort_data_final
GROUP BY
CohortMonth,
CohortIndex),
cohort_sizes AS (
SELECT
CohortMonth,
customers AS cohort_size
FROM cohort_counts
WHERE CohortIndex = 0),
retention_data AS (
SELECT
c.CohortMonth,
c.CohortIndex,
ROUND(c.customers / s.cohort_size * 100, 1) AS retention
FROM cohort_counts c
JOIN cohort_sizes s
ON c.CohortMonth = s.CohortMonth)
SELECT
DATE_FORMAT(CohortMonth,'%Y-%m') AS CohortMonth,
MAX(CASE WHEN CohortIndex = 0 THEN retention END) AS `0`,
MAX(CASE WHEN CohortIndex = 1 THEN retention END) AS `1`,
MAX(CASE WHEN CohortIndex = 2 THEN retention END) AS `2`,
MAX(CASE WHEN CohortIndex = 3 THEN retention END) AS `3`,
MAX(CASE WHEN CohortIndex = 4 THEN retention END) AS `4`,
MAX(CASE WHEN CohortIndex = 5 THEN retention END) AS `5`,
MAX(CASE WHEN CohortIndex = 6 THEN retention END) AS `6`,
MAX(CASE WHEN CohortIndex = 7 THEN retention END) AS `7`,
MAX(CASE WHEN CohortIndex = 8 THEN retention END) AS `8`,
MAX(CASE WHEN CohortIndex = 9 THEN retention END) AS `9`,
MAX(CASE WHEN CohortIndex = 10 THEN retention END) AS `10`,
MAX(CASE WHEN CohortIndex = 11 THEN retention END) AS `11`
FROM retention_data
GROUP BY CohortMonth
ORDER BY CohortMonth;

