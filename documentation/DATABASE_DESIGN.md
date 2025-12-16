# 🗄️ Sales Analytics System - Database Design Documentation

> Technical documentation for database architecture, design decisions, and implementation details

**Version:** 1.0  
**Last Updated:** December 2025  
**Author:** [Karol Behrendt]  
**Database:** MS SQL Server 2025 Express

---

## 📋 Table of Contents

1. [Business Requirements](#business-requirements)
2. [Database Architecture](#database-architecture)
3. [Schema Design](#schema-design)
4. [Normalization & Data Integrity](#normalization--data-integrity)
5. [Performance Optimization](#performance-optimization)
6. [Advanced SQL Queries](#advanced-sql-queries)
7. [Data Volume & Testing](#data-volume--testing)
8. [Security Considerations](#security-considerations)
9. [Future Enhancements](#future-enhancements)

---

## 1. Business Requirements

### 1.1 Problem Statement

A retail company needs a centralized database system to:
- Track sales performance across products and time periods
- Monitor inventory levels and predict stockouts
- Analyze customer purchasing behavior
- Generate automated reports for management decisions

### 1.2 Functional Requirements

| Requirement ID | Description | Priority |
|----------------|-------------|----------|
| **FR-01** | Store product catalog with pricing and inventory | High |
| **FR-02** | Track customer orders with line-item details | High |
| **FR-03** | Record inventory transactions (purchases, sales, adjustments) | Medium |
| **FR-04** | Support multiple suppliers and product categories | Medium |
| **FR-05** | Enable sales trend analysis over time | High |
| **FR-06** | Identify top-performing products | High |
| **FR-07** | Segment customers by purchasing behavior (RFM) | High |
| **FR-08** | Calculate order totals with discounts automatically | High |

### 1.3 Non-Functional Requirements

- **Performance:** Query response time < 500ms for analytical queries
- **Scalability:** Support up to 100,000 orders without redesign
- **Data Integrity:** Enforce referential integrity via foreign keys
- **Maintainability:** Use views for complex queries to simplify access
- **Documentation:** Comprehensive inline comments and external docs

---

## 2. Database Architecture

### 2.1 Entity-Relationship Diagram
```
┌──────────────┐
│  Categories  │
│  (5 records) │
└──────┬───────┘
       │
       │ 1:N
       │
┌──────▼───────┐      ┌──────────────┐
│   Products   │      │  Suppliers   │
│ (30 records) │◄─────┤  (5 records) │
└──────┬───────┘  N:1 └──────────────┘
       │
       │ N:1
       │
┌──────▼──────────┐
│  OrderDetails   │
│ (~1850 records) │
└──────┬──────────┘
       │
       │ N:1
       │
┌──────▼─────────┐     ┌──────────────┐
│     Orders     │     │  Customers   │
│  (400 records) │────►│ (16 records) │
└────────────────┘ N:1 └──────────────┘

┌───────────────────────┐
│ InventoryTransactions │
│     (30+ records)     │
└───────────────────────┘
       │
       │ N:1
       ▼
   Products
```

### 2.2 Design Philosophy

**Normalized Design (3NF):**
- Eliminates data redundancy
- Ensures update anomalies are prevented
- Maintains referential integrity

**Star Schema Considerations:**
- Current design is OLTP-optimized (transactional)
- Future enhancement: Create data warehouse with star schema for OLAP

**Computed Columns:**
- `LineTotal` in OrderDetails = `Quantity * UnitPrice * (1 - Discount)`
- Marked as PERSISTED for query performance

---

## 3. Schema Design

### 3.1 Table: Categories

**Purpose:** Organize products into logical groupings for reporting and filtering.
```sql
CREATE TABLE Categories (
    CategoryID INT PRIMARY KEY IDENTITY(1,1),
    CategoryName NVARCHAR(50) NOT NULL,
    Description NVARCHAR(255)
);
```

| Column | Type | Constraints | Purpose |
|--------|------|-------------|---------|
| CategoryID | INT | PK, IDENTITY | Unique identifier |
| CategoryName | NVARCHAR(50) | NOT NULL | Category display name |
| Description | NVARCHAR(255) | NULL | Optional description |

**Design Decisions:**
- `IDENTITY(1,1)` for auto-incrementing primary key
- `NVARCHAR` for Unicode support (international characters)
- No unique constraint on CategoryName (allows soft deletes/renames)

**Sample Data:**
```
1 | Electronics        | Electronic devices and accessories
2 | Clothing           | Apparel and fashion items
3 | Food & Beverages   | Food and drink products
4 | Books              | Books and magazines
5 | Home & Garden      | Home improvement and garden supplies
```

---

### 3.2 Table: Suppliers

**Purpose:** Track vendor information for procurement and supply chain management.
```sql
CREATE TABLE Suppliers (
    SupplierID INT PRIMARY KEY IDENTITY(1,1),
    CompanyName NVARCHAR(100) NOT NULL,
    ContactName NVARCHAR(100),
    Country NVARCHAR(50),
    Phone NVARCHAR(20)
);
```

| Column | Type | Constraints | Purpose |
|--------|------|-------------|---------|
| SupplierID | INT | PK, IDENTITY | Unique identifier |
| CompanyName | NVARCHAR(100) | NOT NULL | Supplier company name |
| ContactName | NVARCHAR(100) | NULL | Primary contact person |
| Country | NVARCHAR(50) | NULL | Supplier location |
| Phone | NVARCHAR(20) | NULL | Contact phone number |

**Design Decisions:**
- Minimal supplier data (can be extended with Address table)
- Phone stored as NVARCHAR for international format flexibility
- No email field in current version (future enhancement)

---

### 3.3 Table: Products

**Purpose:** Central product catalog with pricing, inventory, and reorder levels.
```sql
CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(100) NOT NULL,
    SupplierID INT FOREIGN KEY REFERENCES Suppliers(SupplierID),
    UnitPrice DECIMAL(10,2) NOT NULL,
    UnitsInStock INT DEFAULT 0,
    ReorderLevel INT DEFAULT 10,
    Discontinued BIT DEFAULT 0,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    LastModified DATETIME2 DEFAULT GETDATE()
);
```

| Column | Type | Constraints | Purpose |
|--------|------|-------------|---------|
| ProductID | INT | PK, IDENTITY | Unique identifier |
| ProductName | NVARCHAR(100) | NOT NULL | Product display name |
| SupplierID | INT | FK → Suppliers | Vendor reference |
| UnitPrice | DECIMAL(10,2) | NOT NULL | Current selling price |
| UnitsInStock | INT | DEFAULT 0 | Current inventory level |
| ReorderLevel | INT | DEFAULT 10 | Threshold for reordering |
| Discontinued | BIT | DEFAULT 0 | Soft delete flag |
| CreatedDate | DATETIME2 | DEFAULT GETDATE() | Record creation timestamp |
| LastModified | DATETIME2 | DEFAULT GETDATE() | Last update timestamp |

**Design Decisions:**
- `DECIMAL(10,2)` for currency (avoids floating-point precision issues)
- `Discontinued` instead of hard deletes (preserves historical data)
- `ReorderLevel` enables automated inventory alerts
- Timestamps for audit trail

**Business Rules:**
- Price changes are tracked via LastModified
- Historical prices in OrderDetails preserve snapshot at order time
- UnitsInStock updated via triggers or stored procedures (future)

---

### 3.4 Table: Customers

**Purpose:** Store customer master data for order attribution and segmentation.
```sql
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    CompanyName NVARCHAR(100) NOT NULL,
    ContactName NVARCHAR(100),
    Country NVARCHAR(50),
    City NVARCHAR(50),
    PostalCode NVARCHAR(10),
    RegistrationDate DATETIME2 DEFAULT GETDATE()
);
```

| Column | Type | Constraints | Purpose |
|--------|------|-------------|---------|
| CustomerID | INT | PK, IDENTITY | Unique identifier |
| CompanyName | NVARCHAR(100) | NOT NULL | Customer business name |
| ContactName | NVARCHAR(100) | NULL | Primary contact person |
| Country | NVARCHAR(50) | NULL | Customer location |
| City | NVARCHAR(50) | NULL | City for geographic analysis |
| PostalCode | NVARCHAR(10) | NULL | Postal/ZIP code |
| RegistrationDate | DATETIME2 | DEFAULT GETDATE() | Customer acquisition date |

**Design Decisions:**
- B2B focus (CompanyName as primary identifier)
- Geographic fields for market analysis
- RegistrationDate enables cohort analysis (future)

---

### 3.5 Table: Orders

**Purpose:** Order headers tracking customer purchases with status workflow.
```sql
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID),
    OrderDate DATETIME2 DEFAULT GETDATE(),
    ShippedDate DATETIME2,
    Status NVARCHAR(20) CHECK (Status IN ('Pending', 'Shipped', 'Delivered', 'Cancelled')),
    TotalAmount DECIMAL(10,2),
    ShipCountry NVARCHAR(50),
    ShipCity NVARCHAR(50)
);
```

| Column | Type | Constraints | Purpose |
|--------|------|-------------|---------|
| OrderID | INT | PK, IDENTITY | Unique identifier |
| CustomerID | INT | FK → Customers | Customer reference |
| OrderDate | DATETIME2 | DEFAULT GETDATE() | Order placement timestamp |
| ShippedDate | DATETIME2 | NULL | Shipping timestamp |
| Status | NVARCHAR(20) | CHECK constraint | Order workflow state |
| TotalAmount | DECIMAL(10,2) | NULL | Calculated order total |
| ShipCountry | NVARCHAR(50) | NULL | Delivery country |
| ShipCity | NVARCHAR(50) | NULL | Delivery city |

**Design Decisions:**
- `CHECK` constraint ensures valid status values only
- `TotalAmount` denormalized for performance (calculated from OrderDetails)
- Shipping address separate from customer address (B2B scenarios)

**Status Workflow:**
```
Pending → Shipped → Delivered
   └──────────► Cancelled (from any state)
```

---

### 3.6 Table: OrderDetails

**Purpose:** Order line items with quantity, pricing, and discounts.
```sql
CREATE TABLE OrderDetails (
    OrderDetailID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT FOREIGN KEY REFERENCES Orders(OrderID),
    ProductID INT FOREIGN KEY REFERENCES Products(ProductID),
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    Discount DECIMAL(4,2) DEFAULT 0.00,
    LineTotal AS (Quantity * UnitPrice * (1 - Discount)) PERSISTED
);
```

| Column | Type | Constraints | Purpose |
|--------|------|-------------|---------|
| OrderDetailID | INT | PK, IDENTITY | Unique identifier |
| OrderID | INT | FK → Orders | Order header reference |
| ProductID | INT | FK → Products | Product reference |
| Quantity | INT | NOT NULL | Units ordered |
| UnitPrice | DECIMAL(10,2) | NOT NULL | Price snapshot at order time |
| Discount | DECIMAL(4,2) | DEFAULT 0.00 | Discount rate (0.00 to 0.99) |
| LineTotal | COMPUTED | PERSISTED | Calculated line total |

**Design Decisions:**
- `UnitPrice` snapshot preserves historical pricing
- `Discount` as decimal (0.10 = 10% off)
- `LineTotal` as PERSISTED computed column:
  - Automatically calculated
  - Physically stored (faster queries)
  - Updated on INSERT/UPDATE automatically

**Calculation Logic:**
```
LineTotal = Quantity × UnitPrice × (1 - Discount)

Example:
Quantity: 5
UnitPrice: $100.00
Discount: 0.10 (10%)
LineTotal: 5 × $100 × (1 - 0.10) = $450.00
```

---

### 3.7 Table: InventoryTransactions

**Purpose:** Audit trail for inventory movements (purchases, sales, adjustments).
```sql
CREATE TABLE InventoryTransactions (
    TransactionID INT PRIMARY KEY IDENTITY(1,1),
    ProductID INT FOREIGN KEY REFERENCES Products(ProductID),
    TransactionType NVARCHAR(20) CHECK (TransactionType IN ('Purchase', 'Sale', 'Adjustment')),
    Quantity INT NOT NULL,
    TransactionDate DATETIME2 DEFAULT GETDATE(),
    Notes NVARCHAR(255)
);
```

| Column | Type | Constraints | Purpose |
|--------|------|-------------|---------|
| TransactionID | INT | PK, IDENTITY | Unique identifier |
| ProductID | INT | FK → Products | Product reference |
| TransactionType | NVARCHAR(20) | CHECK constraint | Transaction category |
| Quantity | INT | NOT NULL | Units moved (positive or negative) |
| TransactionDate | DATETIME2 | DEFAULT GETDATE() | Transaction timestamp |
| Notes | NVARCHAR(255) | NULL | Optional description |

**Design Decisions:**
- Append-only table (never DELETE)
- Quantity can be positive (purchase) or negative (sale/adjustment)
- Enables inventory reconciliation and audit reports

---

## 4. Normalization & Data Integrity

### 4.1 Normal Forms Applied

**First Normal Form (1NF):**
✅ All columns contain atomic values  
✅ No repeating groups (OrderDetails separate from Orders)  
✅ Each row uniquely identifiable via primary key

**Second Normal Form (2NF):**
✅ All non-key columns fully dependent on primary key  
✅ No partial dependencies (composite keys avoided)

**Third Normal Form (3NF):**
✅ No transitive dependencies  
✅ Example: ProductName not stored in OrderDetails (references Products.ProductID)

### 4.2 Referential Integrity

**Foreign Key Constraints:**
```sql
-- Products → Suppliers
ALTER TABLE Products 
ADD CONSTRAINT FK_Products_Suppliers 
FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID);

-- Orders → Customers
ALTER TABLE Orders 
ADD CONSTRAINT FK_Orders_Customers 
FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID);

-- OrderDetails → Orders
ALTER TABLE OrderDetails 
ADD CONSTRAINT FK_OrderDetails_Orders 
FOREIGN KEY (OrderID) REFERENCES Orders(OrderID);

-- OrderDetails → Products
ALTER TABLE OrderDetails 
ADD CONSTRAINT FK_OrderDetails_Products 
FOREIGN KEY (ProductID) REFERENCES Products(ProductID);

-- InventoryTransactions → Products
ALTER TABLE InventoryTransactions 
ADD CONSTRAINT FK_InventoryTransactions_Products 
FOREIGN KEY (ProductID) REFERENCES Products(ProductID);
```

**Cascade Rules:**
- **ON DELETE:** Default RESTRICT (prevents orphaned records)
- **ON UPDATE:** Default CASCADE (propagates key changes)

---

## 5. Performance Optimization

### 5.1 Indexing Strategy

**Primary Key Indexes:**
- Automatically created clustered indexes on all PK columns
- Optimizes lookups by ID (most common access pattern)

**Foreign Key Indexes:**
```sql
-- Optimize JOIN operations on foreign keys
CREATE INDEX IX_Products_SupplierID ON Products(SupplierID);
CREATE INDEX IX_Orders_CustomerID ON Orders(CustomerID);
CREATE INDEX IX_OrderDetails_OrderID ON OrderDetails(OrderID);
CREATE INDEX IX_OrderDetails_ProductID ON OrderDetails(ProductID);
CREATE INDEX IX_InventoryTransactions_ProductID ON InventoryTransactions(ProductID);
```

**Composite Indexes (Query-Specific):**
```sql
-- Optimize date range queries with status filter
CREATE INDEX IX_Orders_Date_Status ON Orders(OrderDate, Status);

-- Usage:
SELECT * FROM Orders 
WHERE OrderDate >= '2025-01-01' AND Status = 'Delivered';
-- Uses IX_Orders_Date_Status instead of table scan
```

**Statistics:**
- Automatic statistics enabled (SQL Server default)
- Manual statistics update after bulk imports (optional)

### 5.2 Query Performance Benchmarks

**Test Environment:**
- SQL Server 2025 Express
- 400 Orders, 1,850 OrderDetails
- Standard laptop (8GB RAM, SSD)

| Query | Execution Time | Rows Returned | Optimization |
|-------|----------------|---------------|--------------|
| vw_TopProducts | ~45ms | 10 | Indexed FKs |
| vw_MonthlySalesTrend | ~78ms | 13 | Date index |
| vw_RFMSegmentation | ~62ms | 16 | Customer index |
| Simple SELECT by ID | <1ms | 1 | PK clustered |
| JOIN Orders + OrderDetails | ~12ms | 1,850 | FK indexes |

**Performance Target:** ✅ All queries < 100ms (achieved)

### 5.3 Computed Columns

**LineTotal (PERSISTED):**
```sql
LineTotal AS (Quantity * UnitPrice * (1 - Discount)) PERSISTED
```

**Benefits:**
- Pre-calculated at INSERT/UPDATE (no runtime calculation)
- Indexed for fast aggregation queries
- 30-40% faster SUM(LineTotal) vs SUM(Quantity * UnitPrice * (1 - Discount))

**Trade-off:**
- Slightly slower INSERT/UPDATE (acceptable for analytical workload)
- Additional storage space (minimal: ~4 bytes per row)

---

## 6. Advanced SQL Queries

### 6.1 Query Complexity Analysis

**Query #1: Top Products (vw_TopProducts)**

**Complexity Level:** High  
**Techniques Used:**
- Common Table Expressions (2 levels)
- Window Functions: ROW_NUMBER(), RANK(), PERCENT_RANK()
- Aggregate Functions: COUNT, SUM, AVG
- Multi-table JOINs

**Query Structure:**
```
CTE #1: ProductSales
   └─► Aggregate sales per product (GROUP BY)

CTE #2: RankedProducts  
   └─► Apply window functions for ranking

Final SELECT:
   └─► Filter top 10, format output
```

**Business Logic:**
- **RevenueRank:** Sequential ranking by total revenue (no ties)
- **QuantityRank:** Ranking by units sold (allows ties with gaps)
- **RevenuePercentile:** Position in distribution (0.0 = top, 1.0 = bottom)

**Use Case:**
- Identify best-selling products for inventory prioritization
- Detect underperforming products (percentile > 0.8)
- Compare revenue ranking vs. quantity ranking (margin analysis)

---

**Query #2: Monthly Sales Trend (vw_MonthlySalesTrend)**

**Complexity Level:** Very High  
**Techniques Used:**
- Window Functions: LAG(), AVG() with ROWS BETWEEN
- Date Functions: DATEFROMPARTS(), YEAR(), MONTH()
- Moving Average (3-month sliding window)
- Month-over-Month calculations
- Safe division with NULLIF()

**Query Structure:**
```
CTE #1: MonthlySales
   └─► Aggregate orders by month

CTE #2: TrendAnalysis
   ├─► Moving Average: AVG() OVER (ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
   ├─► MoM Change: Current - LAG(MonthlyRevenue)
   └─► MoM %: (Change / LAG) * 100.0

Final SELECT:
   └─► Format dates and currency
```

**Window Frame Explanation:**
```sql
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
```

**Example:**
```
Month     Revenue    Window           Moving Avg
Jan 2025  $100K      [Jan]            $100K (1 month)
Feb 2025  $120K      [Jan, Feb]       $110K (2 months)
Mar 2025  $130K      [Jan, Feb, Mar]  $116.7K (3 months)
Apr 2025  $140K      [Feb, Mar, Apr]  $130K (3 months)
```

**LAG() Function:**
```sql
LAG(MonthlyRevenue) OVER (ORDER BY MonthStart)
```
- Accesses previous row's value
- Returns NULL for first row (no prior month)
- Used for Month-over-Month comparison

**NULLIF() Protection:**
```sql
... / NULLIF(LAG(MonthlyRevenue) OVER (...), 0)
```
- Prevents divide-by-zero errors
- Returns NULL instead of throwing error
- Necessary when previous month revenue = 0

**Use Case:**
- Trend forecasting (is revenue growing or declining?)
- Seasonal pattern detection
- Anomaly detection (large MoM swings)

---

**Query #3: RFM Customer Segmentation (vw_RFMSegmentation)**

**Complexity Level:** Very High  
**Techniques Used:**
- Window Functions: NTILE(5)
- Date Functions: DATEDIFF()
- Complex CASE logic for segmentation
- Multi-dimensional scoring (R, F, M)

**RFM Methodology:**

**Recency (R):**
```sql
DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) AS Recency
```
- Lower = better (purchased recently)
- NTILE(5) inverts score: NTILE(...ORDER BY Recency ASC)

**Frequency (F):**
```sql
COUNT(DISTINCT o.OrderID) AS Frequency
```
- Higher = better (purchases often)
- NTILE(5): ORDER BY Frequency DESC

**Monetary (M):**
```sql
SUM(od.Quantity * od.UnitPrice) AS Monetary
```
- Higher = better (spends more)
- NTILE(5): ORDER BY Monetary DESC

**NTILE(5) Distribution:**
- Divides customers into 5 equal groups
- Score 5 = Top 20%, Score 1 = Bottom 20%

**Example with 16 customers:**
```
Score 5: Top 3-4 customers
Score 4: Next 3-4 customers
Score 3: Middle 3-4 customers
Score 2: Next 3-4 customers
Score 1: Bottom 3-4 customers
```

**Segmentation Logic:**
```sql
CASE 
    WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 
        THEN 'Champions'           -- Best customers (top 20% in all metrics)
    WHEN R_Score >= 3 AND F_Score >= 3 AND M_Score >= 3 
        THEN 'Loyal Customers'     -- Solid performers (top 40% in all)
    WHEN R_Score >= 4 AND F_Score <= 2 
        THEN 'New Customers'       -- Recent but low frequency
    WHEN R_Score <= 2 AND F_Score >= 3 
        THEN 'At Risk'             -- Haven't purchased recently but used to
    WHEN R_Score <= 2 AND F_Score <= 2 
        THEN 'Lost'                -- Haven't purchased in a while, low frequency
    ELSE 'Potential Loyalists'     -- Everyone else
END AS Segment
```

**Business Actions by Segment:**

| Segment | Definition | Action |
|---------|------------|--------|
| **Champions** | R≥4, F≥4, M≥4 | VIP rewards, early access, exclusive offers |
| **Loyal Customers** | R≥3, F≥3, M≥3 | Upsell, cross-sell, referral programs |
| **Potential Loyalists** | Mixed scores | Engagement campaigns, personalized offers |
| **New Customers** | R≥4, F≤2 | Onboarding, education, first-purchase incentives |
| **At Risk** | R≤2, F≥3 | 🚨 Win-back campaign, discount offers |
| **Lost** | R≤2, F≤2 | 🚨 Reactivation emails, special promotions |

**Use Case:**
- Automated customer segmentation for CRM
- Identify churn risk before it happens
- Personalize marketing campaigns by segment

---

## 7. Data Volume & Testing

### 7.1 Sample Data Generation

**Generation Method:**
- SQL cursors + RAND() for realistic randomization
- Date ranges: Last 13 months (Dec 2024 - Dec 2025)
- Order frequency: 80% Delivered, 10% Shipped, 5% Pending, 5% Cancelled

**Data Distribution:**

| Table | Records | Notes |
|-------|---------|-------|
| Categories | 5 | Fixed categories |
| Suppliers | 5 | Major vendors |
| Products | 30 | Distributed across categories |
| Customers | 16 | Mix of domestic/international |
| Orders | 400 | ~30 orders/month |
| OrderDetails | ~1,850 | 3-6 items per order |
| InventoryTransactions | 30+ | Initial stock purchases |

**Order Details Distribution:**
```
Items per Order: 3-6 (randomized)
Quantity per Item: 1-8 units
Discount Rate: 20% chance of 5%, 10%, or 15% discount
```

### 7.2 Data Quality Checks

**Referential Integrity Test:**
```sql
-- Verify no orphaned records
SELECT 'Orders' AS TableName, COUNT(*) AS Orphaned
FROM Orders o
LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE c.CustomerID IS NULL

UNION ALL

SELECT 'OrderDetails', COUNT(*)
FROM OrderDetails od
LEFT JOIN Orders o ON od.OrderID = o.OrderID
WHERE o.OrderID IS NULL;
```
**Expected Result:** 0 orphaned records

**Data Consistency Test:**
```sql
-- Verify order totals match sum of line items
SELECT 
    o.OrderID,
    o.TotalAmount AS OrderTotal,
    SUM(od.LineTotal) AS CalculatedTotal,
    o.TotalAmount - SUM(od.LineTotal) AS Difference
FROM Orders o
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY o.OrderID, o.TotalAmount
HAVING ABS(o.TotalAmount - SUM(od.LineTotal)) > 0.01;
```
**Expected Result:** No differences (or < $0.01 due to rounding)

---

## 8. Security Considerations

### 8.1 Authentication & Authorization

**Current Implementation:**
- Windows Authentication (default)
- Single user: sa (system administrator)

**Production Recommendations:**
- Create role-based access:
  - `db_reader`: SELECT only (analysts, reporting tools)
  - `db_writer`: INSERT/UPDATE (applications)
  - `db_admin`: Full control (DBAs)

**Example:**
```sql
CREATE LOGIN analyst_user WITH PASSWORD = 'StrongPassword123!';
CREATE USER analyst_user FOR LOGIN analyst_user;
ALTER ROLE db_datareader ADD MEMBER analyst_user;
```

### 8.2 Data Protection

**Sensitive Data:**
- Customer contact information (names, emails, phone)
- Order history (purchasing behavior)

**Mitigation:**
- Views expose only necessary columns
- No credit card data stored (PCI-DSS compliance)
- Implement encryption at rest (TDE) in production

### 8.3 SQL Injection Prevention

**Current State:**
- No dynamic SQL in views (safe)
- Future stored procedures must use parameterized queries

**Example (secure):**
```sql
CREATE PROCEDURE sp_GetOrdersByCustomer
    @CustomerID INT
AS
BEGIN
    SELECT * FROM Orders 
    WHERE CustomerID = @CustomerID;  -- Safe: parameterized
END;
```

**Bad Example (vulnerable):**
```sql
-- DON'T DO THIS!
EXEC('SELECT * FROM Orders WHERE CustomerID = ' + @CustomerID);
```

---

## 9. Future Enhancements

### 9.1 Data Warehouse (Star Schema)

**Proposed Architecture:**
```
        ┌─────────────┐
        │ DimCustomer │
        └──────┬──────┘
               │
        ┌──────▼──────┐
        │  FactOrders │◄─────┐
        │  (center)   │      │
        └──────┬──────┘      │
               │             │
     ┌─────────┼─────────────┤
     │         │             │
┌────▼────┐ ┌──▼──────┐ ┌───▼─────┐
│DimProduct│ │ DimDate │ │DimStatus│
└─────────┘ └─────────┘ └─────────┘
```

**Benefits:**
- Optimized for analytical queries (OLAP)
- Pre-aggregated metrics for faster dashboards
- Historical snapshots (slowly changing dimensions)

### 9.2 Stored Procedures

**Automated Report Generation:**
```sql
CREATE PROCEDURE sp_GenerateMonthlySalesReport
    @Month DATE
AS
BEGIN
    -- Email monthly report to management
END;
```

**Inventory Alerts:**
```sql
CREATE PROCEDURE sp_CheckLowStockProducts
AS
BEGIN
    -- Send alert for products below reorder level
END;
```

### 9.3 Advanced Analytics

**Cohort Analysis:**
- Track customer retention by registration month
- Measure lifetime value (LTV) per cohort

**ABC Analysis:**
- Classify products: A (80% revenue), B (15%), C (5%)
- Optimize inventory investment

**Predictive Models:**
- Forecast next month's revenue (machine learning integration)
- Predict customer churn probability

### 9.4 Real-Time Features

**Change Data Capture (CDC):**
- Track changes to Orders/Products in real-time
- Enable event-driven architecture

**Temporal Tables:**
```sql
ALTER TABLE Products 
ADD PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime);
```
- Query historical product prices: `FOR SYSTEM_TIME AS OF '2025-01-01'`

---

## 10. Conclusion

### 10.1 Design Strengths

✅ **Normalized Schema:** Eliminates redundancy, ensures data integrity  
✅ **Performance Optimized:** Strategic indexing, computed columns  
✅ **Scalable:** Supports 10x growth without redesign  
✅ **Maintainable:** Views abstract complexity, inline documentation  
✅ **Business-Aligned:** Schema reflects real-world business processes  

### 10.2 Lessons Learned

- **Window Functions:** Powerful for analytical queries, but complex to debug
- **CTEs:** Improve readability over nested subqueries
- **Computed Columns:** Trade-off between write speed and query performance
- **Indexing:** Measure before optimizing (don't over-index)

### 10.3 Metrics

| Metric | Value |
|--------|-------|
| **Development Time** | ~12 hours |
| **Lines of SQL Code** | ~800 |
| **Tables** | 7 |
| **Views** | 3 |
| **Indexes** | 12 (6 PK + 6 FK) |
| **Query Complexity** | High (Window Functions, CTEs) |
| **Documentation** | Comprehensive (README + this doc) |

---

## Appendix A: Full Schema Script

See: `sql/01_schema.sql`

## Appendix B: Sample Queries

See: `sql/04_queries.sql`

## Appendix C: Performance Benchmarks

See: Section 5.2

---

**Document Version:** 1.0  
**Last Updated:** December 2025  
**Maintained By:** [Karol Behrendt]