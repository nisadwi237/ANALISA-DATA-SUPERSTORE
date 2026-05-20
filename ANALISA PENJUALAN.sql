USE DATABASE SUPERSTORE;

--6. Menghitung jumlah penjualan, total sales, total diskon, dan total profit
SELECT
 COUNT(DISTINCT orders.order_id) AS total_orders,
 SUM(order_details.sales) AS total_sales,
 SUM(order_details.discount) AS total_discount,
 SUM(order_details.profit) AS total_profit
FROM orders 
JOIN order_details 
 ON orders.order_id = order_details.order_id;

--7. Membuat laporan penjualan per tahun
SELECT
 DATE_PART('YEAR', o.order_date) AS year, --Mengambil bagian tahun pada tanggal transaksi
 COUNT(DISTINCT o.order_id) AS total_orders,
 SUM(od.sales) AS total_sales,
 SUM(od.profit) AS total_profit,
 ROUND(SUM(od.sales) / COUNT(DISTINCT o.order_id), 2) AS avg_sales_per_order
FROM orders o
JOIN order_details od
 ON o.order_id = od.order_id
GROUP BY
 year
ORDER BY
 year ASC;

--Membuat laporan tranksaksi bulanan berdasarkan prioritas order
SELECT
    DATE_TRUNC('MONTH', o.order_date) AS month_start, --Mengubah tanggal menjadi awal bulan pada setiap transaksi
    COUNT(CASE 
            WHEN o.order_priority = 'Critical'
            THEN o.order_id
            END
    ) AS CRITICAL,
    COUNT(CASE
            WHEN o.order_priority = 'High'
            THEN o.order_id
            END
    ) AS HIGH,
    COUNT(CASE
            WHEN o.order_priority = 'Medium'
            THEN o.order_id   
            END
    ) AS MEDIUM,
    COUNT(CASE
            WHEN o.order_priority = 'Low'
            THEN o.order_id
            END
    ) AS LOW,
FROM ORDERS o
--Memfilter data hanya untuk di tahun 2024
WHERE o.order_date >= '2024-01-01'::DATE
 AND o.order_date <= '2024-12-31'::DATE
GROUP BY month_start
ORDER BY month_start ASC;


--9. Membandingkan penjualan bulanan antar tahun.
SELECT
    DATE_PART('MONTH', o.order_date) AS month, --Mengambil bagian bulan pada tanggal transaksi
    SUM(CASE
            WHEN DATE_PART('YEAR', o.order_date) = 2022
            THEN od.sales
            END
    )AS sales_2022,
    SUM(CASE
            WHEN DATE_PART('YEAR', o.order_date) = 2023
            THEN od.sales
            END
    ) AS sales_2023,
    SUM(CASE
            WHEN DATE_PART('YEAR', o.order_date) = 2024
            THEN od.sales
            END
    ) AS sales_2024,
FROM orders o
JOIN order_details od
ON o.order_id = od.order_id
GROUP BY month
ORDER BY month ASC;

-- 10. Menghitung jumlah pesanan per hari selama seminggu terakhir.
--CARA 1 Menggunakan CURRENT_DATE
SELECT 
    o.order_date,
    COUNT(*) AS total_orders
FROM orders o
WHERE o.order_date >= CURRENT_DATE - INTERVAL '7 DAY'
GROUP BY o.order_date
ORDER BY o.order_date ASC;
-- CARA 2 

SELECT  
    o.order_date,  
    COUNT(*) AS total_orders 
FROM orders o 
WHERE o.order_date >= '2024-12-31'::DATE - INTERVAL '7 DAY' 
AND o.order_date <= '2024-12-31'::DATE 
GROUP BY o.order_date 
ORDER BY o.order_date ASC;

--11. Mencari mode pengiriman terhemat. 
SELECT  
    o.ship_mode,  
    AVG(od.shipping_cost) AS avg_shipping_cost 
FROM orders o
JOIN order_details od 
ON od.order_id = o.order_id 
GROUP BY  
o.ship_mode 
ORDER BY  
avg_shipping_cost ASC; 

--12. Menghitung rata-rata waktu pengiriman
SELECT
    o.ship_mode,
    AVG(
        DATEDIFF(day,o.order_date,o.ship_date) --Menghitung jumlah hari antara tanggal pemesanan dan tanggal pengiriman untuk setiap pesanan
    ) AS avg_shipping_days
FROM orders o
GROUP BY o.ship_mode
ORDER BY avg_shipping_days ASC;

--#13 Menghitung total biaya pengiriman selama satu bulan terakhir
SELECT
    o.ship_mode,
    SUM(od.shipping_cost) AS total_shipping_cost
FROM orders o 
JOIN order_details od
ON o.order_id = od.order_id
WHERE o.order_date >= '2024-12-31'::DATE - INTERVAL '1 MONTH' 
AND o.order_date <= '2024-12-31'::DATE 
GROUP BY o.ship_mode
ORDER BY total_shipping_cost ASC;

--#14.Membandingkan margin profit per campaign marketing 
--Periode pelaksanaan campaign di SUPERSTORE
--1. Back to School (15 Juli - 15 Agustus 2024) 
--2. Black Friday (25 - 30 November 2024) 
--3. Holiday Sale (1 - 31 Desember 2024) 

SELECT
    'Back to School' AS campaign_name,  
    '15 Jul - 15 Agu 2024' AS periode, 
    SUM(od.sales) AS total_sales,
    SUM(od.profit) AS total_profit,
    ROUND((SUM(od.profit) / SUM(od.sales)) * 100, 2) AS profit_margin 
FROM orders o
JOIN order_details od
ON o.order_id = od.order_id
WHERE o.order_date BETWEEN '2024-07-15' AND '2024-08-15' 

UNION ALL -- menggabungkan hasil dari beberapa periode campaign yang ditentukan berdasarkan tanggal tertentu. 

SELECT
    'Holiday Sale' AS campaign_name,  
    '1 - 31 Des 2024' AS periode, 
    SUM(od.sales) AS total_sales,
    SUM(od.profit) AS total_profit,
    ROUND((SUM(od.profit) / SUM(od.sales)) * 100, 2) AS profit_margin 
FROM orders o
JOIN order_details od
ON o.order_id = od.order_id
WHERE o.order_date BETWEEN '2024-12-01' AND '2024-12-31' 

UNION ALL

SELECT
    'Black Friday' AS campaign_name,  
    '25 - 30 Nov 2024' AS periode, 
    SUM(od.sales) AS total_sales,
    SUM(od.profit) AS total_profit,
    ROUND((SUM(od.profit) / SUM(od.sales)) * 100, 2) AS profit_margin 
FROM orders o
JOIN order_details od
ON o.order_id = od.order_id
WHERE o.order_date BETWEEN '2024-11-25' AND '2024-11-30' 

ORDER BY profit_margin DESC;

-- 15. Membuat laporan perbandingan penjualan pada campaign antar tahun.
WITH CampaignSales AS (  --CTE 1: CampaignSales >> Menghitung total sales selama periode campaign (Juni - Agustus) untuk setiap tahun.
SELECT 
    DATE_PART('YEAR', o.order_date) AS year,
    'Jun -August' AS campaign_period,
    SUM(od.sales) AS total_sales
FROM orders o
JOIN order_details od
ON o.order_id = od.order_id
WHERE DATE_PART('MONTH', o.order_date) BETWEEN 6 AND 8 
SELECT  
l.region AS region_name,  
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
ON c.location_id = l.location_id 
GROUP BY  
l.region 
ORDER BY  
avg_order_value DESC; 