-- Выбор базы данных

USE ecommerce_analysis;

-- Общая информация о данных

-- Проверяю размер набора данных, количество уникальных
-- объектов и временной период.

SELECT
COUNT(*) AS 'размер датасета',
COUNT(DISTINCT InvoiceNo) AS 'уникальных заказов',
COUNT(DISTINCT BINARY StockCode) AS 'уникальных товаров',
COUNT(DISTINCT CustomerID) AS 'уникальных клиентов',
COUNT(DISTINCT Country) AS 'уникальных стран',
DATE_FORMAT(MIN(InvoiceDate), '%d.%m.%Y') AS 'Начало периода',
DATE_FORMAT(MAX(InvoiceDate), '%d.%m.%Y') AS 'Конец периода'
FROM online_retail_raw;

-- Проверка пропущенных значений

-- Проверяю количество и долю пропусков в ключевых полях.

SELECT
'Description' AS 'параметр',
SUM(Description IS NULL) AS 'пропусков',
ROUND(SUM(Description IS NULL) / COUNT(*) * 100, 2) AS 'доля'
FROM online_retail_raw

UNION ALL

SELECT
'CustomerID' AS 'параметр',
SUM(CustomerID IS NULL) AS 'пропусков',
ROUND(SUM(CustomerID IS NULL) / COUNT(*) * 100, 2) AS 'доля'
FROM online_retail_raw;

-- Проверка количественных показателей

-- Проверяю наличие положительных, нулевых и отрицательных
-- значений Quantity и UnitPrice.

SELECT
'Quantity' AS metric,
SUM(CASE WHEN Quantity > 0 THEN 1 ELSE 0 END) AS '>0',
SUM(CASE WHEN Quantity = 0 THEN 1 ELSE 0 END) AS '=0',
SUM(CASE WHEN Quantity < 0 THEN 1 ELSE 0 END) AS '<0'
FROM online_retail_raw

UNION ALL

SELECT
'UnitPrice' AS metric,
SUM(CASE WHEN UnitPrice > 0 THEN 1 ELSE 0 END) AS '>0',
SUM(CASE WHEN UnitPrice = 0 THEN 1 ELSE 0 END) AS '=0',
SUM(CASE WHEN UnitPrice < 0 THEN 1 ELSE 0 END) AS '<0'
FROM online_retail_raw;

-- Проверка отмен и отрицательных количеств

-- Проверяю связь между префиксом C в InvoiceNo
-- и отрицательным Quantity.

SELECT
'с префиксом C' AS 'условие',
COUNT(*) AS 'количество строк'
FROM online_retail_raw
WHERE InvoiceNo LIKE 'C%'

UNION ALL

SELECT
'с префиксом C и Quantity < 0' AS 'условие',
COUNT(*) AS 'количество строк'
FROM online_retail_raw
WHERE InvoiceNo LIKE 'C%'
AND Quantity < 0

UNION ALL

SELECT
'без префикса C и Quantity < 0' AS 'условие',
COUNT(*) AS 'количество строк'
FROM online_retail_raw
WHERE InvoiceNo NOT LIKE 'C%'
AND Quantity < 0;

-- Проверяю операции с отрицательным Quantity,
-- которые не имеют префикса C.

SELECT *
FROM online_retail_raw
WHERE InvoiceNo NOT LIKE 'C%'
AND Quantity < 0
AND Description NOT IN ('');

-- Проверка количества уникальных товаров

-- Использую BINARY, чтобы регистр символов в StockCode
-- учитывался при подсчёте уникальных значений.

SELECT
COUNT(DISTINCT BINARY StockCode) AS unique_stockcode
FROM online_retail_raw;

-- Проверка полных дубликатов

-- Ищу строки, полностью совпадающие по всем полям.
-- Если одна строка встречается N раз, N - 1 экземпляров
-- считаются дубликатами.

SELECT
SUM(duplicate_count - 1) AS full_duplicates
FROM (
SELECT
InvoiceNo,
StockCode,
Description,
Quantity,
InvoiceDate,
UnitPrice,
CustomerID,
Country,
COUNT(*) AS duplicate_count
FROM online_retail_raw
GROUP BY
InvoiceNo,
StockCode,
Description,
Quantity,
InvoiceDate,
UnitPrice,
CustomerID,
Country
HAVING COUNT(*) > 1
) AS duplicates;

-- Проверка экстремальных значений Quantity

SELECT
MIN(Quantity) AS min_quantity,
MAX(Quantity) AS max_quantity
FROM online_retail_raw;

-- Вывожу строки с максимальным абсолютным значением Quantity.

SELECT *
FROM online_retail_raw
ORDER BY ABS(Quantity) DESC
LIMIT 2;

-- Проверка экстремальных значений UnitPrice

SELECT
MIN(UnitPrice) AS min_unitprice,
MAX(UnitPrice) AS max_unitprice
FROM online_retail_raw;

-- Проверяю строки с отрицательным UnitPrice.

SELECT *
FROM online_retail_raw
WHERE UnitPrice < 0;
