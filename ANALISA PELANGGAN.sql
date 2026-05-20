USE DATABASE superstore;

--1. Menampilkan semua tabel di database.
SELECT
 table_name,
 table_schema
FROM information_schema.tables
WHERE table_schema = 'PUBLIC';

--#29.  Menghitung jumlah pelanggan per segmen 
SELECT  
    s.segment AS segment_name,  
    COUNT(c.customer_id) AS total_customers 
FROM customers c 
JOIN segments s  
ON c.segment_id = s.segment_id 
GROUP BY  
s.segment 
ORDER BY  
total_customers DESC; 

--#30. Mengidentifikasi pelanggan dengan nilai pembelian tertinggi 
SELECT  
    c.customer_id,
    c.name AS customer_name,  
    SUM(od.sales) AS total_sales
FROM customers c 
JOIN orders o
ON o.customer_id = c.customer_id
JOIN order_details od 
ON od.order_id = o.order_id
GROUP BY c.customer_id, c.name
ORDER BY total_sales DESC
LIMIT 10;

--#31. Mencari pelanggan dengan pembelian tertinggi di periode tertentu 
-- Mengetahui pelanggan dengan total pembelian tertinggi dalam periode tertentu, misalnya dalam Q4 2023 (Oktober - Desember 2023)
SELECT  
c.customer_id,  
c.name AS customer_name,  
SUM(od.sales) AS total_sales 
FROM order_details od 
JOIN orders o  
ON od.order_id = o.order_id 
JOIN customers c  
ON o.customer_id = c.customer_id 
WHERE  
o.order_date BETWEEN '2023-10-01' AND '2023-12-31'  
GROUP BY  
c.customer_id,  
c.name 
ORDER BY  
total_sales DESC 
LIMIT 10;

--#32 Mencari top pelanggan untuk setiap kategori produk 
WITH RankedCustomers AS ( -- Mengurutkan pelanggan berdasarkan total pembelian dalam setiap kategori menggunakan ROW_NUMBER(). 
    SELECT  
        c.name AS customer_name,  
        c.customer_id,  
        cat.name AS category_name,  
        SUM(od.sales) AS total_sales, 
        ROW_NUMBER()  
            OVER ( 
                PARTITION BY cat.name  
                ORDER BY SUM(od.sales) DESC 
                ) AS rank 
    FROM order_details od 
    JOIN orders o  
        ON od.order_id = o.order_id 
    JOIN customers c  
        ON o.customer_id = c.customer_id 
    JOIN products p  
        ON od.product_id = p.product_id 
    JOIN categories cat  
        ON p.category_id = cat.category_id 
    GROUP BY c.name, c.customer_id, cat.name 
     
) 
 
SELECT  
    category_name,  
    customer_id,  
    customer_name,  
    total_sales 
FROM RankedCustomers 
WHERE rank = 1 
ORDER BY  
    category_name; 

--#33 Mengidentifikasi pelanggan loyal dengan pembelian berulang 
SELECT  
    c.customer_id,  
    c.name AS customer_name,  
    COUNT(o.order_id) AS total_orders 
FROM orders o 
JOIN customers c  
ON o.customer_id = c.customer_id 
GROUP BY  
c.customer_id,  
c.name 
ORDER BY  
total_orders DESC 
LIMIT 10; 

--#34. Mengidentifikasi tren pembelian pelanggan
--Menganalisis tren pembelian pelanggan berdasarkan jumlah transaksi per bulan di SUPERSTORE
SELECT  
    c.customer_id,  
    c.name AS customer_name,  
    DATE_TRUNC('MONTH', o.order_date) AS month_start,  --Mengambil tanggal awal transaksi setiap bulan
    COUNT(o.order_id) AS total_orders 
FROM orders o 
JOIN customers c  
ON o.customer_id = c.customer_id 
GROUP BY  
c.customer_id,  
c.name,  
month_start 
ORDER BY  
c.customer_id, month_start ASC; 

--#35 Menentukan tren pembelian pelanggan berdasarkan waktu 
--Problem : mengetahui tren pembelian pelanggan berdasarkan waktu, misalnya dalam periode 2023 dengan total transaksi dan penjualan bulanan
SELECT  
    DATE_TRUNC('MONTH', o.order_date) AS month_start,  --Mengambil tanggal awal transaksi setiap bulan
    c.customer_id,  
    c.name AS customer_name,  
    COUNT(o.order_id) AS total_orders,
    SUM(od.sales) AS total_sales
FROM orders o 
JOIN customers c  
ON o.customer_id = c.customer_id 
JOIN order_details od 
ON o.order_id = od.order_id
WHERE DATE_PART('YEAR', o.order_date) = 2023
GROUP BY  
c.customer_id,  
c.name,  
month_start 
ORDER BY  
c.customer_id, month_start ASC;

--#36. Menghitung total penjualan bulanan untuk pelanggan tertentu
--Problem :  total penjualan bulanan untuk pelanggan CC-12685 di SUPERSTORE 
SELECT  
DATE_TRUNC('MONTH', o.order_date) AS month_start,  
c.customer_id,  
c.name AS customer_name,  
SUM(od.sales) AS total_sales 
FROM order_details od 
JOIN orders o  
ON od.order_id = o.order_id 
JOIN customers c  
ON o.customer_id = c.customer_id 
WHERE  
c.customer_id = 'CC-12685' 
GROUP BY  
month_start,  
c.customer_id,  
c.name 
ORDER BY month_start ASC; 

--#37 Mengetahui wilayah dengan jumlah pelanggan terbanyak 
SELECT
    l.c6 AS region_name,
    COUNT(c.customer_id) AS total_customer
FROM customers c 
JOIN locations l 
ON c.location_id = TRY_CAST(l.c1 AS NUMBER)
GROUP BY l.c6
ORDER BY total_customer DESC;

--#38 Mengidentifikasi wilayah dengan pelanggan baru terbanyak selama campaign
--Problem :berapa banyak pelanggan baru yang pertama kali melakukan transaksi selama periode campaign (Juni - Agustus 2023) di SUPERSTORE
WITH FirstPurchase AS ( 
 
  SELECT  
    c.customer_id,  
    MIN(o.order_date) AS first_order_date, 
    l.region AS region_name 
  FROM customers c 
  JOIN orders o  
    ON c.customer_id = o.customer_id 
  JOIN locations l  
    ON c.location_id = l.location_id 
  GROUP BY  
    c.customer_id,  
    l.region 

     
) 
 
SELECT  
  fp.region_name,  
  COUNT(fp.customer_id) AS new_customers 
FROM FirstPurchase fp 
WHERE  
    fp.first_order_date BETWEEN '2023-06-01' AND '2023-08-31' 
GROUP BY  
    fp.region_name 
ORDER BY  
new_customers DESC;

--#39 Mengidentifikasi wilayah dengan pelanggan terbanyak sebelum dan setelah campaign 
--Problem : Perubahan jumlah pelanggan di setiap wilayah dalam 3 bulan sebelum dan 3 bulan setelah campaign pemasaran (Juni - Agustus 2023) di SUPERSTORE
WITH CustomersBefore AS ( 
SELECT  
l.region AS region_name, 
COUNT(DISTINCT c.customer_id) AS customers_before 
FROM customers c 
JOIN locations l  
ON c.location_id = l.location_id 
JOIN orders o  
ON c.customer_id = o.customer_id 
WHERE  
o.order_date BETWEEN '2023-03-01' AND '2023-05-31' 
GROUP BY  
l.region 
), 
CustomersAfter AS ( 
141 
Ngulik SQL: 50 Masalah dan Solusi 
  SELECT  
    l.region AS region_name, 
    COUNT(DISTINCT c.customer_id) AS customers_after 
  FROM customers c 
  JOIN locations l  
    ON c.location_id = l.location_id 
  JOIN orders o  
    ON c.customer_id = o.customer_id 
  WHERE  
    o.order_date BETWEEN '2023-09-01' AND '2023-11-30' 
  GROUP BY  
  l.region 
   
) 
 
SELECT  
    cb.region_name,  
    cb.customers_before,  
    COALESCE(ca.customers_after, 0) AS customers_after,  
    ROUND(((COALESCE(ca.customers_after, 0) - cb.customers_before) 
/ cb.customers_before) * 100, 2) AS growth_rate 
FROM CustomersBefore cb 
LEFT JOIN CustomersAfter ca  
    ON cb.region_name = ca.region_name 
ORDER BY  
    growth_rate DESC; 
--#40 Melakukan evaluasi churn pelanggan selama 6 bulan 
--problem : berapa banyak pelanggan yang tetap aktif atau mengalami churn dalam 6 bulan setelah campaign pemasaran (Juni - Agustus 2023) di SUPERSTORE
WITH CustomersAfter AS ( 
SELECT  
l.region AS region_name, 
COUNT(DISTINCT c.customer_id) AS customers_after 
FROM customers c 
JOIN locations l  
ON c.location_id = l.location_id 
JOIN orders o  
ON c.customer_id = o.customer_id 
WHERE  
o.order_date BETWEEN '2023-09-01' AND '2023-11-30'  -- 3 bulan 
setelah campaign 
GROUP BY  
l.region 
), 
CustomersActive AS ( 

  SELECT  
    l.region AS region_name, 
    COUNT(DISTINCT c.customer_id) AS active_customers 
  FROM customers c 
  JOIN locations l  
    ON c.location_id = l.location_id 
  JOIN orders o  
    ON c.customer_id = o.customer_id 
  WHERE  
    o.order_date BETWEEN '2023-12-01' AND '2024-05-31'  -- 6 bulan 
setelah campaign 
  GROUP BY  
    l.region 
) 
 
SELECT  
    ca.region_name,  
    ca.customers_after,  
    COALESCE(cact.active_customers, 0) AS active_customers,  
    (ca.customers_after - COALESCE(cact.active_customers, 0)) AS 
churn_customers, 
    ROUND(((ca.customers_after - COALESCE(cact.active_customers, 
0))::DECIMAL / ca.customers_after) * 100, 2) AS churn_rate 
FROM CustomersAfter ca 
LEFT JOIN CustomersActive cact  
    ON ca.region_name = cact.region_name 
ORDER BY  
    churn_rate DESC; 
