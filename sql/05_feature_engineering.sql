-- Выбор базы данных

USE ecommerce_analysis;

-- Расчёт выручки

-- Выручка рассчитывается как произведение количества товара
-- на его цену.


-- Revenue отражает выручку от продаж и не является прибылью.
-- В исходных данных отсутствуют себестоимость, маркетинговые
-- и прочие расходы.

ALTER TABLE online_retail_clean
ADD COLUMN Revenue DECIMAL(15,4);

UPDATE online_retail_clean
SET Revenue = Quantity * UnitPrice;


-- Создание временных признаков


-- Из InvoiceDate выделяю отдельные признаки для последующего
-- анализа динамики продаж и покупательской активности.

ALTER TABLE online_retail_clean
ADD COLUMN Date DATE,
ADD COLUMN Year INT,
ADD COLUMN Month INT,
ADD COLUMN DayOfWeek INT,
ADD COLUMN Hour INT,
ADD COLUMN YearMonth DATE;

-- Заполняю созданные признаки.

UPDATE online_retail_clean
SET
Date = DATE(InvoiceDate),
Year = YEAR(InvoiceDate),
Month = MONTH(InvoiceDate),
DayOfWeek = WEEKDAY(InvoiceDate),
Hour = HOUR(InvoiceDate),
YearMonth = DATE_FORMAT(InvoiceDate, '%Y-%m-01');
