-- Выбор базы данных

USE ecommerce_analysis;

-- Формирование правил очистки

-- На предыдущем этапе были выявлены отрицательные значения
-- Quantity, нулевые и отрицательные значения UnitPrice,
-- а также отменённые заказы.


-- Для основного анализа продаж формируется отдельный набор
-- данных, содержащий только фактические положительные продажи.


-- Используются следующие правила:
-- Quantity > 0 — положительное количество проданного товара;
-- UnitPrice > 0 — положительная цена товара.


-- Отмены, возвраты и внутренние корректировки таким образом
-- не попадают в основной набор данных.

-- Проверяю количество строк, которые соответствуют
-- выбранным правилам очистки.

SELECT
COUNT(*) AS clean_rows
FROM online_retail_raw
WHERE Quantity > 0
AND UnitPrice > 0;


-- Контроль применения правил очистки


-- Проверяю, что после применения условий в наборе
-- действительно отсутствуют отрицательные Quantity,
-- неположительные UnitPrice и отменённые заказы.

SELECT
SUM(CASE WHEN Quantity < 0 THEN 1 ELSE 0 END) AS negative_quantity,
SUM(CASE WHEN UnitPrice <= 0 THEN 1 ELSE 0 END) AS non_positive_unitprice,
SUM(CASE WHEN InvoiceNo LIKE 'C%' THEN 1 ELSE 0 END) AS cancellation_rows
FROM online_retail_raw
WHERE Quantity > 0
AND UnitPrice > 0;

-- Проверяю минимальные значения после очистки.

SELECT
MIN(Quantity) AS min_quantity,
MIN(UnitPrice) AS min_unitprice
FROM online_retail_raw
WHERE Quantity > 0
AND UnitPrice > 0;


-- Создание очищенной таблицы


-- Создаю отдельную таблицу для основного анализа.
-- Исходная таблица online_retail_raw сохраняется без изменений.

DROP TABLE IF EXISTS online_retail_clean;

CREATE TABLE online_retail_clean AS
SELECT *
FROM online_retail_raw
WHERE Quantity > 0
AND UnitPrice > 0;

--  Контроль структуры очищенного набора данных


-- Проверяю количество уникальных заказов, товаров,
-- клиентов и стран после очистки.

SELECT
COUNT(DISTINCT InvoiceNo) AS unique_orders,
COUNT(DISTINCT BINARY StockCode) AS unique_products,
COUNT(DISTINCT CustomerID) AS unique_customers,
COUNT(DISTINCT Country) AS unique_countries
FROM online_retail_clean;

-- Проверяю временной период очищенного набора данных.

SELECT
DATE_FORMAT(MIN(InvoiceDate), '%d.%m.%Y %H:%i') AS period_start,
DATE_FORMAT(MAX(InvoiceDate), '%d.%m.%Y %H:%i') AS period_end
FROM online_retail_clean;

-- Проверяю итоговый размер очищенного набора данных.

SELECT
COUNT(*) AS clean_rows
FROM online_retail_clean;
