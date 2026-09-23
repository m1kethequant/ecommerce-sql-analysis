-- E-commerce SQL Analysis

-- Создание базы данных

CREATE DATABASE IF NOT EXISTS ecommerce_analysis;

USE ecommerce_analysis;

-- Создание таблицы исходных данных
-- Содержит набор данных после базового преобразования типов.
-- На этом этапе аналитическая очистка не выполняется.

CREATE TABLE online_retail_raw (
InvoiceNo VARCHAR(20),
StockCode VARCHAR(20),
Description VARCHAR(255),
Quantity INT,
InvoiceDate DATETIME,
UnitPrice DECIMAL(15,6),
CustomerID INT,
Country VARCHAR(100));

-- Создание таблиц для загрузки
-- Временная промежуточная таблица для загрузки исходных данных
-- Все столбцы имеют тип VARCHAR, так как исходный CSV содержит
-- десятичные разделители-запятые, строковые представления дат и пустые значения.

CREATE TABLE online_retail_import (
InvoiceNo VARCHAR(20),
StockCode VARCHAR(20),
Description VARCHAR(255),
Quantity VARCHAR(50),
InvoiceDate VARCHAR(50),
UnitPrice VARCHAR(50),
CustomerID VARCHAR(50),
Country VARCHAR(100));

-- Проверка структуры базы данных

SHOW TABLES;
DESCRIBE online_retail_raw;
DESCRIBE online_retail_import;