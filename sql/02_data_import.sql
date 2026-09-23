-- Выбор базы данных

USE ecommerce_analysis;

-- Загрузка CSV-файла во временную таблицу
-- Данные сначала загружаются в online_retail_import
-- без преобразования типов.
-- Это позволяет отдельно контролировать загрузку
-- и последующее преобразование данных.

LOAD DATA LOCAL INFILE 'D:/Online Retail.csv'
INTO TABLE online_retail_import
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
InvoiceNo,
StockCode,
Description,
Quantity,
InvoiceDate,
UnitPrice,
CustomerID,
Country
);

-- Проверка количества загруженных строк

SELECT COUNT(*) AS row_count
FROM online_retail_import;

-- Преобразование данных и перенос в исходную таблицу
-- На этом этапе:
-- Quantity преобразуется в целое число;
-- InvoiceDate преобразуется в формат DATETIME;
-- UnitPrice преобразуется в числовой формат;
-- пустые значения CustomerID преобразуются в NULL;
-- символ возврата каретки удаляется из Country.

INSERT INTO online_retail_raw (
InvoiceNo,
StockCode,
Description,
Quantity,
InvoiceDate,
UnitPrice,
CustomerID,
Country
)
SELECT
InvoiceNo,
StockCode,
Description,
CAST(Quantity AS SIGNED),
STR_TO_DATE(InvoiceDate, '%d.%m.%Y %H:%i'),
CAST(REPLACE(UnitPrice, ',', '.') AS DECIMAL(15,6)),
CAST(NULLIF(TRIM(CustomerID), '') AS SIGNED),
REPLACE(Country, '\r', '')
FROM online_retail_import;

-- Проверка структуры исходной таблицы

DESCRIBE online_retail_raw;

-- Проверка количества строк после преобразования

SELECT COUNT(*) AS row_count
FROM online_retail_raw;

