USE DATABASE superstore;
--#41 Membandingkan jumlah pesanan berdasarkan wilayah geografis 
SELECT  
l.region AS region_name,  
COUNT(o.order_id) AS total_orders 
FROM  
orders o 
JOIN customers c  
ON o.customer_id = c.customer_id 
JOIN locations l  
ON c.location_id = l.location_id 
GROUP BY  
l.region 
ORDER BY  
total_orders DESC 
LIMIT 10; 

--#42 Mendapatkan wilayah dengan jumlah pelanggan terbanyak
SELECT  
l.region AS region_name,  
COUNT(DISTINCT c.customer_id) AS total_customers 
FROM customers c 
JOIN locations l  
ON c.location_id = l.location_id 
GROUP BY  
l.region 
ORDER BY  
total_customers DESC; 

--#43 Menghitung revenue per wilayah tahunan 
SELECT  
    DATE_PART('YEAR', o.order_date) AS year,  
    l.c6 AS region_name,  
    SUM(od.sales) AS total_revenue 
FROM order_details od 
JOIN orders o  
ON od.order_id = o.order_id 
JOIN customers c  
ON o.customer_id = c.customer_id 
JOIN locations l  
ON c.location_id = TRY_CAST(l.c1 AS NUMBER)
GROUP BY  
year,  
l.c6
ORDER BY  
year ASC,  
total_revenue DESC; 

--#44 Mencari produk yang paling laku di setiap wilayah 
--problem :Mengetahui produk dengan total penjualan tertinggi di setiap wilayah di SUPERSTORE, Menentukan daftar tiga produk terlaris untuk setiap wilayah berdasarkan total penjualan.
WITH RankedSales AS ( 
 
  SELECT  
    l.c6 AS region_name,  
    p.product_name,  
    SUM(od.sales) AS total_sales, 
    ROW_NUMBER() OVER (PARTITION BY l.c6 ORDER BY 
SUM(od.sales) DESC) AS rank 
  FROM order_details od 
  JOIN products p  
    ON od.product_id = p.product_id 
  JOIN orders o  
    ON od.order_id = o.order_id 
  JOIN customers c  
    ON o.customer_id = c.customer_id 
  JOIN locations l  
    ON c.location_id = TRY_CAST(l.c1 AS NUMBER)
  GROUP BY  
    l.c6,  
    p.product_name 
) 
 
SELECT  
    region_name,  
    product_name,  
    total_sales 
FROM RankedSales 

WHERE  
rank <= 3 
ORDER BY  
region_name,  
total_sales DESC;

--#45 Mencari produk dengan kontribusi profit terbesar per wilayah
--Mengetahui kontribusi profit setiap produk terhadap total profit dalam suatu wilayah, misalnya dalam tahun 2023
WITH ProductProfit AS ( 
  SELECT  
    l.region AS region_name,  
    p.product_name,  
    SUM(od.profit) AS total_profit 
  FROM order_details od 
  JOIN products p  
    ON od.product_id = p.product_id 
  JOIN orders o  
    ON od.order_id = o.order_id 
  JOIN customers c  
    ON o.customer_id = c.customer_id 
  JOIN locations l  
    ON c.location_id = l.location_id 
  WHERE  
    DATE_PART('YEAR', o.order_date) = 2023 
  GROUP BY  
    l.region,  
    p.product_name 
), 
 
 
RegionProfit AS ( 
 
  SELECT  
    region_name,  
    product_name,  
    total_profit,  
    SUM(total_profit) OVER (PARTITION BY region_name) AS 
region_profit 
     
  FROM ProductProfit 
) 
 
SELECT  
  region_name,  
  product_name,  
  total_profit,  
  region_profit,  
  ROUND((total_profit::DECIMAL / region_profit) * 100, 2) AS 
contribution_percentage 
FROM RegionProfit 
ORDER BY  
    region_name,  
    contribution_percentage DESC;
    
--PENJELASAN KODE

--CTE 1: ProductProfit 
--Menghitung total profit per produk di setiap wilayah. 
--GROUP BY l.region, p.product_name untuk mendapatkan data per produk dalam wilayahnya. 
--CTE 2: RegionProfit (Menggunakan Window Function) 

--SUM(total_profit) OVER (PARTITION BY region_name) → Menghitung total profit per wilayah, tanpa perlu subquery tambahan. 
--PARTITION BY region_name memastikan bahwa agregasi dilakukan hanya dalam masing-masing wilayah, bukan seluruh dataset. 
  
--Final Query 
--ROUND((total_profit / region_profit) * 100, 2) AS contribution_percentage menghitung kontribusi profit produk terhadap total profit wilayah. 
--ORDER BY region_name, contribution_percentage DESC menampilkan produk dengan kontribusi profit terbesar di setiap wilayah.

--#46 Membandingkan performa segmen pelanggan per wilayah
-- Total penjualan untuk setiap segmen pelanggan di berbagai wilayah, dengan wilayah sebagai baris dan segmen sebagai kolom di SUPERSTORE
SELECT  
    l.region AS region_name, 
    SUM(CASE  
            WHEN s.segment = 'Consumer' THEN od.sales  
            ELSE 0  
        END) AS Consumer, 
    SUM(CASE  
            WHEN s.segment = 'Corporate' THEN od.sales  
            ELSE 0  
        END) AS Corporate, 
    SUM(CASE  
            WHEN s.segment = 'Home Office' THEN od.sales  
            ELSE 0  
        END) AS Home_Office 
FROM order_details od 
JOIN orders o  
    ON od.order_id = o.order_id 
JOIN customers c  
    ON o.customer_id = c.customer_id 
JOIN segments s  
    ON c.segment_id = s.segment_id 
JOIN locations l  
    ON c.location_id = l.location_id 
GROUP BY  
    l.region 
ORDER BY  
    region_name; 

--Penjelasan Kode: 
-- SUM(CASE WHEN s.segment = 'Consumer' THEN od.sales ELSE 0 END) AS Consumer → Menghitung total penjualan untuk segmen Consumer di setiap wilayah. 
-- SUM(CASE WHEN s.segment = 'Corporate' THEN od.sales ELSE 0 END) AS Corporate → Menghitung total penjualan untuk segmen Corporate di setiap wilayah. 
-- SUM(CASE WHEN s.segment = 'Home Office' THEN od.sales ELSE 0 END) AS Home_Office → Menghitung total penjualan untuk segmen Home Office di setiap wilayah. 
-- JOIN orders dengan customers, segments, dan locations → Menghubungkan pesanan dengan data pelanggan dan wilayah. 
-- GROUP BY l.region → Mengelompokkan hasil berdasarkan wilayah. 
-- ORDER BY region_name → Mengurutkan hasil berdasarkan nama wilayah.

--#47 Mengidentifikasi wilayah yang pengirimannya paling sering terlambat 
-- Mengidentifikasi wilayah dengan jumlah keterlambatan pengiriman lebih dari 5 hari terbanyak di SUPERSTORE
SELECT  
l.c6 AS region_name,  
COUNT(*) AS late_shipments 
FROM orders o 
JOIN customers c  
ON o.customer_id = c.customer_id 
JOIN locations l  
ON c.location_id = TRY_CAST(l.c1 AS NUMBER)
WHERE  
DATEDIFF(day, o.order_date, o.ship_date) > 5 --Menghitung jumlah hari antara waktu pesanan dan pengiriman lebih dari 5 hari
GROUP BY  
l.region 
ORDER BY  
late_shipments DESC;

--#48 Menghitung rata-rata biaya pengiriman per wilayah
SELECT  
l.c6 AS region_name,  
AVG(od.shipping_cost) AS avg_shipping_cost 
FROM order_details od 
JOIN orders o  
ON od.order_id = o.order_id 
JOIN customers c  
ON o.customer_id = c.customer_id 
JOIN locations l  
ON c.location_id = TRY_CAST(l.c1 AS number)
GROUP BY  
l.c6
ORDER BY  
avg_shipping_cost ASC; 

--#49 Mencari wilayah dengan transaksi diskon terbanyak 
SELECT  
l.c6 AS region_name,  
COUNT(DISTINCT o.order_id) AS discount_transactions 
FROM orders o 
JOIN order_details od  
ON o.order_id = od.order_id 
JOIN customers c  
ON o.customer_id = c.customer_id 
JOIN locations l  
ON c.location_id = TRY_CAST(l.c1 AS number)
WHERE  
od.discount > 0 
GROUP BY  
l.c6
ORDER BY  
discount_transactions DESC; 

SELECT  
l.region AS region_name,  
COUNT(DISTINCT o.order_id) AS discount_transactions 
FROM orders o 
JOIN order_details od  
ON o.order_id = od.order_id 
JOIN customers c  
ON o.customer_id = c.customer_id 
JOIN locations l  
ON c.location_id = l.location_id 
WHERE  
od.discount > 0 
GROUP BY  
l.region 
ORDER BY  
discount_transactions DESC; 

--#50. Menganalisis Wilayah dengan Rata-Rata Order Value (AOV) Tertinggi
SELECT  
l.c6 AS region_name,  
COUNT(DISTINCT o.order_id) AS total_orders,  
SUM(od.sales) AS total_sales,  
ROUND(SUM(od.sales) / COUNT(DISTINCT o.order_id), 2) AS 
avg_order_value 
FROM orders o 
JOIN order_details od  
ON o.order_id = od.order_id 
JOIN customers c  
ON o.customer_id = c.customer_id 
JOIN locations l  
ON c.location_id = TRY_CAST(l.c1 AS number)
GROUP BY  
l.c6
ORDER BY  
avg_order_value DESC; 