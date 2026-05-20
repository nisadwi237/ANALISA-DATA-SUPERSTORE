create database superstore;

--1. Menampilkan semua tabel di database.
SELECT
 table_name,
 table_schema
FROM information_schema.tables
WHERE table_schema = 'PUBLIC';

--2. Memahami struktur kolom dari tabel.
SELECT
    table_name,
    column_name,
    data_type,
FROM information_schema.columns
where table_name = 'ORDERS'
and table_schema = 'PUBLIC';

--3. Mencari tabel dengan jumlah data
terbanyak di database.
SELECT
    table_name,
    column_name,
    data_type,
FROM information_schema.columns
WHERE table_name = 'PRODUCTS'
and table_schema = 'PUBLIC';

--4. Melihat sampel data di dalam tabel
SELECT
    table_name,
    row_count,
FROM information_schema.tables
where table_schema = 'PUBLIC'
ORDER BY row_count DESC;

SELECT * FROM orders LIMIT 5;

SELECT * FROM ORDERS SAMPLE (5 ROWS)

-- 5. Memeriksa kombinasi nilai-nilai di sebuah kolom dalam tabel
SELECT
    order_priority,
    COUNT(*) AS count
FROM ORDERS
GROUP BY order_priority
ORDER BY count DESC;

SELECT
 COUNT(*) AS total_rows,
 SUM(
 CASE
 WHEN order_priority IS NULL THEN 1
ELSE 0
 END
 ) AS null_count,
 SUM(
 CASE
 WHEN TRIM(order_priority) = '' THEN 1
 ELSE 0
 END
 ) AS empty_count
FROM ORDERS;
