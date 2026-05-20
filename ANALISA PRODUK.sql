USE DATABASE superstore;

--1. Menampilkan semua tabel di database.
SELECT
 table_name,
 table_schema
FROM information_schema.tables
WHERE table_schema = 'PUBLIC';

--#17 Mengetahui jumlah produk untuk setiap kategori produk 
SELECT
    c.name AS category_name,
    COUNT (p.product_id) AS total_products
FROM products p 
JOIN categories c
ON c.category_id = p.category_id
GROUP BY category_name
ORDER BY total_products DESC;

--#18 Menghitung total penjualan untuk setiap kategori produk 
SELECT
    c.name AS category_name,
    SUM(od.sales) AS total_sales
FROM products p 
JOIN categories c
ON c.category_id = p.category_id
JOIN order_details od
ON od.product_id = p.product_id
GROUP BY category_name
ORDER BY total_sales DESC;

--#19. Membuat laporan keuntungan per kategori produk setiap tahun 
SELECT
    c.name AS category_name,
    SUM(CASE
            WHEN DATE_PART('YEAR', o.order_date) = 2022
            THEN od.profit
            END
    )AS profit_2022,
    SUM(CASE
            WHEN DATE_PART('YEAR', o.order_date) = 2023
            THEN od.profit
            END
    )AS profit_2023,
    SUM(CASE
            WHEN DATE_PART('YEAR', o.order_date) = 2024
            THEN od.profit
            END
    )AS profit_2024,
FROM products p 
JOIN categories c
ON c.category_id = p.category_id
JOIN order_details od
ON od.product_id = p.product_id
JOIN orders o
ON o.order_id = od.order_id
GROUP BY 
    category_name
ORDER BY  
    profit_2024 DESC;

--#20. Menganalisis kontribusi produk terhadap total profit setiap tahun
 
WITH ProfitPerCategory AS ( -- Menghitung total profit untuk setiap kategori dalam setiap tahun.
 
      SELECT  
        DATE_PART('YEAR', o.order_date) AS year,  
        c.name AS category_name,  
        SUM(od.profit) AS total_profit 
      FROM order_details od 
      JOIN orders o  
        ON od.order_id = o.order_id 
      JOIN products p  
        ON od.product_id = p.product_id 
      JOIN categories c  
        ON p.category_id = c.category_id 
      WHERE  
        DATE_PART('YEAR', o.order_date) IN (2022, 2023, 2024) 
      GROUP BY  
        year,  
        c.name 
         
),  
 
TotalProfitPerYear AS ( -- Menghitung total profit keseluruhan untuk setiap tahun.
 
  SELECT  
    year,  
    SUM(total_profit) AS total_profit_year 
  FROM ProfitPerCategory 
  GROUP BY year 
   
) 

SELECT  
ppc.year,  
ppc.category_name,  
ppc.total_profit,  
ROUND( 
(ppc.total_profit / tpy.total_profit_year) * 100, 2 
) AS contribution_percentage --Menghitung kontribusi setiap kategori terhadap total profit tahunan dalam bentuk persentase. 
FROM ProfitPerCategory ppc 
JOIN TotalProfitPerYear tpy  --Menghubungkan data profit per kategori dengan total profit tahunan untuk menghitung kontribusi persentase. 
ON ppc.year = tpy.year 
ORDER BY  
ppc.year ASC,  
contribution_percentage DESC; 

--#21 Membuat laporan penjualan mingguan per kategori 
SELECT
    DATE_TRUNC('WEEK', o.order_date) AS week_start, --Mengelompokkan data berdasarkan minggu dengan mengambil tanggal awal minggu dari order_date.
    c.name AS category_name,
    SUM(od.sales) AS total_sales
FROM order_details od 
JOIN products p  
    ON od.product_id = p.product_id 
JOIN categories c
    ON p.category_id = c.category_id 
JOIN orders o  
    ON od.order_id = o.order_id 
WHERE  
    o.order_date >= '2024-10-01'::DATE  
    AND o.order_date <= '2024-12-31'::DATE 
GROUP BY  
    week_start,  
    c.name 
ORDER BY  
    week_start ASC,  
    total_sales DESC;

--#22 Menghitung kontribusi produk terhadap total revenue dalam kategori
--Problem : Bagaimana cara mengetahui kontribusi revenue setiap produk dalam kategori tertentu, misalnya dalam tahun 2023?
WITH CategoryRevenue AS( --Menghitung total revenue untuk setiap kategori produk di tahun 2023.
    SELECT  
    c.name AS category_name,  
    SUM(od.sales) AS category_sales 
  FROM order_details od 
  JOIN products p  
    ON od.product_id = p.product_id 
  JOIN categories c  
    ON p.category_id = c.category_id 
  JOIN orders o  
    ON od.order_id = o.order_id 
  WHERE  
    DATE_PART('YEAR', o.order_date) = 2023 
  GROUP BY  
    c.name 
), 
 
ProductRevenue AS ( 
 
  SELECT  
    c.name AS category_name,  
    p.product_name,  
    SUM(od.sales) AS total_sales 
  FROM order_details od 
  JOIN products p  
    ON od.product_id = p.product_id 
  JOIN categories c  
    ON p.category_id = c.category_id 
  JOIN orders o  
    ON od.order_id = o.order_id 
  WHERE  
    DATE_PART('YEAR', o.order_date) = 2023 
  GROUP BY  
    c.name, 
    p.product_name 
     
) 
 
SELECT  
    pr.category_name,  
    pr.product_name,  
    pr.total_sales,  
    cr.category_sales,  
    ROUND((pr.total_sales::DECIMAL / cr.category_sales) * 100, 2) 
AS contribution_percentage 
FROM ProductRevenue pr 
JOIN CategoryRevenue cr  
    ON pr.category_name = cr.category_name 
ORDER BY  
    pr.category_name,  
    contribution_percentage DESC; 


--#23 Menganalisis penjualan berdasarkan sub kategori produk 
-- Menghitung total penjualan berdasarkan kategori dan subkategori produk di SUPERSTORE
SELECT  
    c.name AS category_name,  
    sc.sub_category AS sub_category_name,  
    SUM(od.sales) AS total_sales 
FROM order_details od 
JOIN products p  
ON od.product_id = p.product_id 
JOIN sub_categories sc  
ON p.sub_category_id = sc.sub_category_id 
JOIN categories c  
ON p.category_id = c.category_id 
GROUP BY  
    c.name, 
    sc.sub_category 
ORDER BY  
    total_sales DESC; 

--#24 Mencari produk dengan 10 penjualan tertinggi dalam 30 hari terakhir 
SELECT
    p.product_name,
    SUM(od.sales) AS total_sales
FROM order_details od 
JOIN products p
ON p.product_id = od.product_id
JOIN orders o
ON o.order_id = od.order_id
WHERE o.order_date >= '2024-12-31'::DATE - INTERVAL '30 DAY' 
AND o.order_date <= '2024-12-31'::DATE 
GROUP BY p.product_name
ORDER BY total_sales DESC
LIMIT 10;

---#25 Mencari produk dengan 10 penjualan tertinggi dalam 30 hari terakhir
-- Problem : Menghitung margin profit dan mengidentifikasi produk dengan profitabilitas tertinggi di SUPERSTORE
SELECT
    p.product_name,
    SUM(od.sales) AS total_sales,
    SUM(od.profit) AS total_profit,
    (SUM(od.profit) / SUM(od.sales)) * 100 AS profit_margin
FROM order_details od 
JOIN products p
ON p.product_id = od.product_id
JOIN orders o
ON o.order_id = od.order_id
GROUP BY p.product_name
ORDER BY profit_margin DESC
LIMIT 10;

--#26 Mencari produk yang sudah lama tidak ada transaksi 
SELECT
    p.product_name AS product_name,
    MAX(order_date) AS last_transaction --Mengambil tanggal terakhir kali produk tersebut terjual. 
FROM order_details order_details_id
JOIN products p
ON  od.product_id = p.product_id 
JOIN orders o  
ON od.order_id = o.order_id 
GROUP BY  
p.product_name 
ORDER BY  
last_transaction ASC 
LIMIT 10;

--#27 Mencari produk yang paling sering diberikan diskon 
SELECT  
    p.product_name,  
    COUNT(*) AS discount_count 
FROM order_details od 
JOIN products p  
ON od.product_id = p.product_id 
WHERE  
od.discount > 0 
GROUP BY  
p.product_name 
ORDER BY  
discount_count DESC; 

--#28. Mencari 3 produk dengan profit Tertinggi dan 3 produk dengan profit terendah 
(
SELECT 
    p.product_name,
    SUM(od.profit) AS total_profit
FROM products p
JOIN order_details od
ON p.product_id = od.product_id
GROUP BY product_name
ORDER BY total_profit DESC
LIMIT 3
)
UNION ALL
(
SELECT 
    p.product_name,
    SUM(od.profit) AS total_profit
FROM products p
JOIN order_details od
ON p.product_id = od.product_id
GROUP BY product_name
ORDER BY total_profit ASC
LIMIT 3
);