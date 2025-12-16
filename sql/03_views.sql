-- ================================================
-- Sales Analytics Database - Views
-- ================================================
-- Author: [Karol Behrendt]
-- Date: 2025-16-12
-- Description: Advanced analytical views with CTEs and Window Functions
-- ================================================

USE SalesAnalytics;
GO

-- ================================================
-- VIEW 1: Top Products Analysis
-- ================================================
IF OBJECT_ID('vw_TopProducts', 'V') IS NOT NULL
    DROP VIEW vw_TopProducts;
GO

CREATE VIEW vw_TopProducts AS
WITH ProductSales AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        COUNT(DISTINCT od.OrderID) AS OrderCount,
        SUM(od.Quantity) AS TotalQuantitySold,
        SUM(od.Quantity * od.UnitPrice) AS TotalRevenue, 
        AVG(od.Quantity * od.UnitPrice) AS AvgOrderValue
    FROM Products p
    INNER JOIN OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY p.ProductID, p.ProductName
),
RankedProducts AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY TotalRevenue DESC) AS RevenueRank,
        RANK() OVER (ORDER BY TotalQuantitySold DESC) AS QuantityRank,
        PERCENT_RANK() OVER (ORDER BY TotalRevenue DESC) AS RevenuePercentile
    FROM ProductSales
)
SELECT 
    RevenueRank,
    ProductName,
    OrderCount,
    TotalQuantitySold,
    TotalRevenue,
    AvgOrderValue,
    QuantityRank,
    RevenuePercentile
FROM RankedProducts
WHERE RevenueRank <= 10;
GO

-- ================================================
-- VIEW 2: Monthly Sales Trend
-- ================================================
IF OBJECT_ID('vw_MonthlySalesTrend', 'V') IS NOT NULL
    DROP VIEW vw_MonthlySalesTrend;
GO

CREATE VIEW vw_MonthlySalesTrend AS
WITH MonthlySales AS (
    SELECT 
        YEAR(o.OrderDate) AS Year,
        MONTH(o.OrderDate) AS Month,
        DATEFROMPARTS(YEAR(o.OrderDate), MONTH(o.OrderDate), 1) AS MonthStart,
        COUNT(DISTINCT o.OrderID) AS OrderCount,
        SUM(od.Quantity * od.UnitPrice) AS MonthlyRevenue
    FROM Orders o
    INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
    GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
),
TrendAnalysis AS (
    SELECT 
        MonthStart,
        OrderCount,
        MonthlyRevenue,
        AVG(MonthlyRevenue) OVER (
            ORDER BY MonthStart 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS MovingAvg3Month,
        MonthlyRevenue - LAG(MonthlyRevenue) OVER (ORDER BY MonthStart) AS MonthOverMonthChange,
        (MonthlyRevenue - LAG(MonthlyRevenue) OVER (ORDER BY MonthStart)) * 100.0 / 
            NULLIF(LAG(MonthlyRevenue) OVER (ORDER BY MonthStart), 0) AS PercentChange
    FROM MonthlySales
)
SELECT 
    MonthStart,
    OrderCount,
    MonthlyRevenue,
    MovingAvg3Month,
    MonthOverMonthChange,
    PercentChange
FROM TrendAnalysis;
GO

-- ================================================
-- VIEW 3: RFM Customer Segmentation
-- ================================================
IF OBJECT_ID('vw_RFMSegmentation', 'V') IS NOT NULL
    DROP VIEW vw_RFMSegmentation;
GO

CREATE VIEW vw_RFMSegmentation AS
WITH CustomerMetrics AS (
    SELECT 
        c.CustomerID,
        c.CompanyName,
        c.ContactName,
        DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) AS Recency,
        COUNT(DISTINCT o.OrderID) AS Frequency,
        SUM(od.Quantity * od.UnitPrice) AS Monetary
    FROM Customers c
    INNER JOIN Orders o ON c.CustomerID = o.CustomerID
    INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
    GROUP BY c.CustomerID, c.CompanyName, c.ContactName
),
RFMScores AS (
    SELECT 
        *,
        NTILE(5) OVER (ORDER BY Recency ASC) AS R_Score,
        NTILE(5) OVER (ORDER BY Frequency DESC) AS F_Score,
        NTILE(5) OVER (ORDER BY Monetary DESC) AS M_Score
    FROM CustomerMetrics
),
RFMSegments AS (
    SELECT 
        *,
        (R_Score + F_Score + M_Score) / 3.0 AS RFM_Score,
        CASE 
            WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 THEN 'Champions'
            WHEN R_Score >= 3 AND F_Score >= 3 AND M_Score >= 3 THEN 'Loyal Customers'
            WHEN R_Score >= 4 AND F_Score <= 2 THEN 'New Customers'
            WHEN R_Score <= 2 AND F_Score >= 3 THEN 'At Risk'
            WHEN R_Score <= 2 AND F_Score <= 2 THEN 'Lost'
            ELSE 'Potential Loyalists'
        END AS Segment
    FROM RFMScores
)
SELECT 
    CompanyName,
    ContactName,
    Recency AS DaysSinceLastOrder,
    Frequency AS TotalOrders,
    Monetary AS TotalSpent,
    R_Score,
    F_Score,
    M_Score,
    RFM_Score,
    Segment
FROM RFMSegments;
GO

-- ================================================
-- End of Views
-- ================================================