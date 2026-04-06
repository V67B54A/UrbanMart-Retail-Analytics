CREATE DATABASE UMDB;
USE UMDB;

ALTER TABLE urbanmart
  RENAME COLUMN `Profit_Margin_%`  TO Profit_Margin_percent,
  RENAME COLUMN `Discount_%`     TO Discount_percent;
  
-- 1. View all data
SELECT * FROM urbanmart LIMIT 10;

-- 2. Total Revenue & Profit
SELECT 
  SUM(Final_Revenue) AS Total_Revenue,
  SUM(Net_Profit)    AS Total_Profit,
  COUNT(*)           AS Total_Orders
FROM urbanmart;

-- 3. Revenue by Category
SELECT Category, SUM(Final_Revenue) AS Revenue
FROM urbanmart
GROUP BY Category
ORDER BY Revenue DESC;

-- 4. Revenue by City
SELECT City, SUM(Final_Revenue) AS Revenue
FROM urbanmart
GROUP BY City
ORDER BY Revenue DESC;

-- 5. Total returned orders
SELECT COUNT(*) AS Returned_Orders
FROM urbanmart
WHERE Is_Returned = 'Yes';

-- 6. Monthly Revenue Trend
SELECT 
  Month,
  SUM(Final_Revenue)                    AS Revenue,
  SUM(Net_Profit)                       AS Profit,
  ROUND(AVG(Profit_Margin_percent), 2)  AS Avg_Margin,
  COUNT(*)                              AS Orders
FROM urbanmart
GROUP BY Month
ORDER BY MIN(Date);

-- 7. Return Rate by Category
SELECT 
  Category,
  COUNT(*)                                           AS Total_Orders,
  SUM(CASE WHEN Is_Returned='Yes' THEN 1 END)        AS Returns,
  ROUND(SUM(CASE WHEN Is_Returned='Yes' THEN 1 END) 
    * 100.0 / COUNT(*), 1)                           AS Return_Rate_percent
FROM urbanmart
GROUP BY Category
ORDER BY Return_Rate_percent DESC;

-- 8. Customer Segment Analysis
SELECT
  Customer_Segment,
  COUNT(*)                                   AS Orders,
  SUM(Final_Revenue)                         AS Revenue,
  ROUND(AVG(Final_Revenue), 0)               AS Avg_Order_Value,
  ROUND(AVG(Profit_Margin_percent), 1)       AS Avg_Margin
FROM urbanmart
GROUP BY Customer_Segment
ORDER BY Revenue DESC;

-- 9. Top 10 Products by Revenue
SELECT
  Product_Name, Category,
  SUM(Final_Revenue)                   AS Revenue,
  SUM(Quantity)                        AS Units_Sold,
  ROUND(AVG(Profit_Margin_percent), 1) AS Avg_Margin
FROM urbanmart
GROUP BY Product_Name, Category
ORDER BY Revenue DESC
LIMIT 10;

-- 10. Payment Method Performance
SELECT
  Payment_Method,
  SUM(Final_Revenue)              AS Revenue,
  SUM(Net_Profit)                 AS Net_Profit,
  COUNT(*)                        AS Orders,
  ROUND(AVG(Discount_percent), 1) AS Avg_Discount
FROM urbanmart
GROUP BY Payment_Method
ORDER BY Net_Profit DESC;

-- 11. MoM Revenue Growth
SELECT
  Month,
  SUM(Final_Revenue) AS Revenue,
  ROUND(
    (SUM(Final_Revenue) - LAG(SUM(Final_Revenue)) 
      OVER (ORDER BY MIN(Date))) * 100.0
    / LAG(SUM(Final_Revenue)) OVER (ORDER BY MIN(Date)), 1
  ) AS MoM_Growth_percent
FROM urbanmart
GROUP BY Month
ORDER BY MIN(Date);

-- 12. Revenue Share by Category
SELECT
  Category,
  SUM(Final_Revenue) AS Revenue,
  ROUND(SUM(Final_Revenue) * 100.0 
    / SUM(SUM(Final_Revenue)) OVER(), 1) AS Revenue_Share_percent
FROM urbanmart
GROUP BY Category
ORDER BY Revenue DESC;

-- 13. Region x Category Breakdown
SELECT
  Region, Category,
  SUM(Final_Revenue) AS Revenue,
  COUNT(*)           AS Orders
FROM urbanmart
GROUP BY Region, Category
ORDER BY Region, Revenue DESC;

-- 14. Discount Impact on Profit
SELECT
  CASE 
    WHEN Discount_percent = 0                    THEN 'No Discount'
    WHEN Discount_percent BETWEEN 1  AND 5       THEN '1-5 percent'
    WHEN Discount_percent BETWEEN 6  AND 10      THEN '6-10 percent'
    WHEN Discount_percent BETWEEN 11 AND 15      THEN '11-15 percent'
    ELSE '15 percent plus'
  END                                            AS Discount_Band,
  COUNT(*)                                       AS Orders,
  ROUND(AVG(Final_Revenue), 0)                   AS Avg_Revenue,
  ROUND(AVG(Net_Profit), 0)                      AS Avg_Profit,
  ROUND(AVG(Profit_Margin_percent), 1)           AS Avg_Margin
FROM urbanmart
GROUP BY Discount_Band
ORDER BY MIN(Discount_percent);

-- 15. Product Return Risk
SELECT
  Product_Name, Category,
  SUM(Final_Revenue)                                     AS Revenue,
  COUNT(*)                                               AS Orders,
  SUM(CASE WHEN Is_Returned='Yes' THEN 1 END)            AS Returns,
  ROUND(SUM(CASE WHEN Is_Returned='Yes' THEN 1 END)
    * 100.0 / COUNT(*), 1)                               AS Return_Rate_percent,
  SUM(CASE WHEN Is_Returned='Yes' 
    THEN Final_Revenue END)                              AS Revenue_At_Risk
FROM urbanmart
GROUP BY Product_Name, Category
HAVING COUNT(*) > 5
ORDER BY Return_Rate_percent DESC
LIMIT 10;

-- 16. High Value Orders
SELECT
  Order_ID, Product_Name, Category,
  City, Customer_Segment,
  Final_Revenue, Net_Profit,
  Profit_Margin_percent
FROM urbanmart
WHERE Final_Revenue > (
  SELECT AVG(Final_Revenue) + 2 * STDEV(Final_Revenue)
  FROM Transactions
)
ORDER BY Final_Revenue DESC;

-- 17. Weekday Revenue Pattern
SELECT
  DAYNAME(Date)                        AS Weekday,
  COUNT(*)                             AS Orders,
  SUM(Final_Revenue)                   AS Total_Revenue,
  ROUND(AVG(Final_Revenue), 0)         AS Avg_Order_Value
FROM urbanmart
GROUP BY DAYNAME(Date), DAYOFWEEK(Date)
ORDER BY DAYOFWEEK(Date);

-- 18. Loyal vs New Customer Comparison
SELECT
  Customer_Segment,
  ROUND(AVG(Final_Revenue), 0)            AS Avg_Order_Value,
  ROUND(AVG(Profit_Margin_percent), 1)    AS Avg_Margin,
  ROUND(AVG(Discount_percent), 1)         AS Avg_Discount,
  ROUND(SUM(CASE WHEN Is_Returned='Yes' THEN 1 END)
    * 100.0 / COUNT(*), 1)                AS Return_Rate_percent
FROM urbanmart
WHERE Customer_Segment IN ('Loyal', 'New')
GROUP BY Customer_Segment;