-- ================================================
-- Sales Analytics Database - Example Queries
-- ================================================
-- Author: [Karol Behrendt]
-- Date: 2025-16-12
-- Description: Example queries showing how to use the views
-- ================================================

USE SalesAnalytics;
GO

-- ================================================
-- QUERY 1: Top Products with Formatting
-- ================================================
SELECT 
    RevenueRank,
    ProductName,
    OrderCount,
    TotalQuantitySold,
    FORMAT(TotalRevenue, 'C', 'en-US') AS Revenue,
    FORMAT(AvgOrderValue, 'C', 'en-US') AS AvgOrderValue,
    QuantityRank,
    FORMAT(RevenuePercentile, 'P2') AS Percentile
FROM vw_TopProducts
ORDER BY RevenueRank;

-- ================================================
-- QUERY 2: Monthly Sales Trend with Formatting
-- ================================================
SELECT 
    FORMAT(MonthStart, 'yyyy-MM') AS Month,
    OrderCount,
    FORMAT(MonthlyRevenue, 'C', 'en-US') AS Revenue,
    FORMAT(MovingAvg3Month, 'C', 'en-US') AS ThreeMonthMA,
    FORMAT(MonthOverMonthChange, 'C', 'en-US') AS MoMChange,
    FORMAT(PercentChange, 'N2') + '%' AS PercentChange
FROM vw_MonthlySalesTrend
ORDER BY MonthStart DESC;

-- ================================================
-- QUERY 3: RFM Segmentation with Formatting
-- ================================================
SELECT 
    CompanyName,
    ContactName,
    DaysSinceLastOrder,
    TotalOrders,
    FORMAT(TotalSpent, 'C', 'en-US') AS TotalSpent,
    R_Score,
    F_Score,
    M_Score,
    CAST(RFM_Score AS DECIMAL(3,1)) AS RFM_Score,
    Segment
FROM vw_RFMSegmentation
ORDER BY RFM_Score DESC;

-- ================================================
-- QUERY 4: Find At-Risk Customers
-- ================================================
SELECT 
    CompanyName,
    FORMAT(TotalSpent, 'C', 'en-US') AS TotalSpent,
    TotalOrders,
    DaysSinceLastOrder,
    Segment
FROM vw_RFMSegmentation
WHERE Segment IN ('At Risk', 'Lost')
ORDER BY TotalSpent DESC;

-- ================================================
-- QUERY 5: Revenue by Month (Last 6 Months)
-- ================================================
SELECT TOP 6
    FORMAT(MonthStart, 'MMMM yyyy') AS Month,
    FORMAT(MonthlyRevenue, 'C', 'en-US') AS Revenue,
    FORMAT(MovingAvg3Month, 'C', 'en-US') AS ThreeMonthAvg
FROM vw_MonthlySalesTrend
ORDER BY MonthStart DESC;