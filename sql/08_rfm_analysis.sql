-- RFM-анализ клиентов

-- Выбор базы данных

USE ecommerce_analysis;

-- Расчёт RFM-метрик

-- RFM-анализ используется для сегментации покупателей по трём характеристикам:
-- Recency  — сколько дней прошло с последней покупки;
-- Frequency — количество совершённых заказов;
-- Monetary  — общая выручка от покупателя.
-- В анализе используются только покупатели с известным CustomerID.

WITH rfm_base AS (
SELECT
CustomerID,
MAX(InvoiceDate) AS last_purchase,
COUNT(DISTINCT InvoiceNo) AS Frequency,
SUM(Revenue) AS Monetary
FROM online_retail_clean
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID),
rfm_metrics AS (
SELECT
CustomerID,
DATEDIFF((SELECT MAX(InvoiceDate) + INTERVAL 1 DAY FROM online_retail_clean WHERE CustomerID IS NOT NULL), last_purchase) AS Recency,
Frequency,
Monetary
FROM rfm_base)
SELECT
CustomerID,
Recency,
Frequency,
ROUND(Monetary, 2) AS Monetary
FROM rfm_metrics
ORDER BY Recency, Frequency DESC, Monetary DESC;


-- Расчёт RFM-оценок

-- Каждая RFM-метрика разбивается на пять групп.
-- Для Recency меньший показатель является лучшим, поэтому шкала инвертируется:
-- 5 — самая высокая давность активности,
-- 1 — самая низкая.
-- Для Frequency и Monetary более высокие значения получают более высокий балл.
-- NTILE(5) используется как приближённый аналог квантильного разбиения, применявшегося в Python.

WITH rfm_base AS (
SELECT
CustomerID,
MAX(InvoiceDate) AS last_purchase,
COUNT(DISTINCT InvoiceNo) AS Frequency,
SUM(Revenue) AS Monetary
FROM online_retail_clean
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID),
rfm_metrics AS (
SELECT
CustomerID,
DATEDIFF((SELECT MAX(InvoiceDate) + INTERVAL 1 DAY FROM online_retail_clean WHERE CustomerID IS NOT NULL), last_purchase) AS Recency,
Frequency,
Monetary
FROM rfm_base),
rfm_scores AS (
SELECT
CustomerID,
Recency,
Frequency,
Monetary,
6 - NTILE(5) OVER (ORDER BY Recency, CustomerID) AS R_score,
NTILE(5) OVER (ORDER BY Frequency, CustomerID) AS F_score,
NTILE(5) OVER (ORDER BY Monetary, CustomerID) AS M_score
FROM rfm_metrics)
SELECT
CustomerID,
Recency,
Frequency,
ROUND(Monetary, 2) AS Monetary,
R_score,
F_score,
M_score,
R_score + F_score + M_score AS RFM_score
FROM rfm_scores
ORDER BY
RFM_score DESC,
Monetary DESC;

-- Сегментация покупателей
-- На основе RFM-оценок формирую клиентские сегменты.

-- Ключевые — высокие оценки по всем трём показателям;
-- Лояльные — относительно высокие показатели активности и частоты покупок;
-- Новые — высокая текущая активность при небольшой частоте заказов;
-- Ценные — высокая частота и выручка при низкой текущей активности;
-- Под риском — снижение текущей активности при сохранении относительно высокой частоты покупок;
-- Ушедшие — низкая текущая активность и низкая частота;
-- Потенциальные  — остальные покупатели.

WITH rfm_base AS (
SELECT
CustomerID,
MAX(InvoiceDate) AS last_purchase,
COUNT(DISTINCT InvoiceNo) AS Frequency,
SUM(Revenue) AS Monetary
FROM online_retail_clean
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID),
rfm_metrics AS (
SELECT
CustomerID,
DATEDIFF((SELECT MAX(InvoiceDate) + INTERVAL 1 DAY FROM online_retail_clean WHERE CustomerID IS NOT NULL), last_purchase) AS Recency,
Frequency,
Monetary
FROM rfm_base),
rfm_scores AS (
SELECT
CustomerID,
Recency,
Frequency,
Monetary,
6 - NTILE(5) OVER (ORDER BY Recency, CustomerID) AS R_score,
NTILE(5) OVER (ORDER BY Frequency, CustomerID) AS F_score,
NTILE(5) OVER (ORDER BY Monetary, CustomerID) AS M_score
FROM rfm_metrics),
rfm_segmented AS (
SELECT
CustomerID,
Recency,
Frequency,
Monetary,
R_score,
F_score,
M_score,
R_score + F_score + M_score AS RFM_score,
CASE WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 THEN 'Ключевые'
WHEN R_score >= 3 AND F_score >= 3 AND M_score >= 3 THEN 'Лояльные'
WHEN R_score >= 4 AND F_score <= 2 THEN 'Новые'
WHEN R_score <= 2 AND F_score >= 4 AND M_score >= 4 THEN 'Ценные'
WHEN R_score <= 2 AND F_score >= 3 THEN 'Под риском'
WHEN R_score <= 2 AND F_score <= 2 THEN 'Ушедшие'
ELSE 'Потенциальные' END AS Segment
FROM rfm_scores)
SELECT
CustomerID,
Recency,
Frequency,
ROUND(Monetary, 2) AS Monetary,
R_score,
F_score,
M_score,
RFM_score,
Segment
FROM rfm_segmented
ORDER BY
RFM_score DESC,
Monetary DESC;

-- 5. Статистика по сегментам

-- Для каждого сегмента рассчитываю:
-- количество покупателей, общую выручку,
-- средние Recency, Frequency и Monetary,
-- долю покупателей и долю выручки.

WITH rfm_base AS (
SELECT
CustomerID,
MAX(InvoiceDate) AS last_purchase,
COUNT(DISTINCT InvoiceNo) AS Frequency,
SUM(Revenue) AS Monetary
FROM online_retail_clean
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID),
rfm_metrics AS (
SELECT
CustomerID,
DATEDIFF((SELECT MAX(InvoiceDate) + INTERVAL 1 DAY FROM online_retail_clean WHERE CustomerID IS NOT NULL), last_purchase) AS Recency,
Frequency,
Monetary
FROM rfm_base),
rfm_scores AS (
SELECT
CustomerID,
Recency,
Frequency,
Monetary,
6 - NTILE(5) OVER (ORDER BY Recency, CustomerID) AS R_score,
NTILE(5) OVER (ORDER BY Frequency, CustomerID) AS F_score,
NTILE(5) OVER (ORDER BY Monetary, CustomerID) AS M_score
FROM rfm_metrics),
rfm_segmented AS (
SELECT
CustomerID,
Recency,
Frequency,
Monetary,
R_score,
F_score,
M_score,
CASE WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 THEN 'Ключевые'
WHEN R_score >= 3 AND F_score >= 3 AND M_score >= 3 THEN 'Лояльные'
WHEN R_score >= 4 AND F_score <= 2 THEN 'Новые'
WHEN R_score <= 2 AND F_score >= 4 AND M_score >= 4 THEN 'Ценные'
WHEN R_score <= 2 AND F_score >= 3 THEN 'Под риском'
WHEN R_score <= 2 AND F_score <= 2 THEN 'Ушедшие'
ELSE 'Потенциальные' END AS Segment
FROM rfm_scores),
segment_stats AS (
SELECT
Segment,
COUNT(*) AS customers,
SUM(Monetary) AS revenue,
AVG(Recency) AS avg_recency,
AVG(Frequency) AS avg_frequency,
AVG(Monetary) AS avg_monetary
FROM rfm_segmented
GROUP BY Segment)
SELECT
Segment,
customers,
ROUND(revenue, 2) AS revenue,
ROUND(avg_recency, 2) AS avg_recency,
ROUND(avg_frequency, 2) AS avg_frequency,
ROUND(avg_monetary, 2) AS avg_monetary,
ROUND(customers / SUM(customers) OVER () * 100, 2) AS customer_share,
ROUND(revenue / SUM(revenue) OVER () * 100, 2) AS revenue_share
FROM segment_stats
ORDER BY revenue DESC;
