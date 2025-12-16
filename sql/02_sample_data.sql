USE SalesAnalytics;
GO

-- ==================== SEED DATA ====================

PRINT 'Starting data import...';

-- 1. Categories
INSERT INTO Categories (CategoryName, Description) VALUES
('Electronics', 'Electronic devices and accessories'),
('Clothing', 'Apparel and fashion items'),
('Food & Beverages', 'Food and drink products'),
('Books', 'Books and magazines'),
('Home & Garden', 'Home improvement and garden supplies');

PRINT '✅ Categories: 5';

-- 2. Suppliers
INSERT INTO Suppliers (CompanyName, ContactName, Country, Phone) VALUES
('Tech Wholesale Ltd', 'John Smith', 'Poland', '+48 123 456 789'),
('Fashion Direct', 'Anna Kowalska', 'Poland', '+48 234 567 890'),
('Global Foods', 'Mark Johnson', 'Germany', '+49 567 890 123'),
('Book Distributors', 'Emma Wilson', 'UK', '+44 678 901 234'),
('Garden Supplies Co', 'Robert Brown', 'Netherlands', '+31 789 012 345');

PRINT '✅ Suppliers: 5';

-- 3. Products (30 produktów zamiast 15)
INSERT INTO Products (ProductName, SupplierID, UnitPrice, UnitsInStock, ReorderLevel) VALUES
-- Electronics
('Laptop HP Book', 1, 2999.00, 15, 5),
('Wireless Mouse', 1, 79.99, 50, 10),
('USB-C Cable 2m', 1, 29.99, 100, 20),
('Mechanical Keyboard', 1, 299.99, 30, 8),
('Headphones Pro', 1, 199.99, 40, 10),
('Webcam HD', 1, 149.99, 35, 8),
-- Clothing
('T-Shirt Black', 2, 49.99, 200, 30),
('Jeans Blue', 2, 149.99, 80, 15),
('Sneakers White', 2, 349.99, 40, 10),
('Jacket Winter', 2, 299.99, 25, 8),
('Hat Baseball', 2, 39.99, 100, 20),
('Socks Pack 5', 2, 24.99, 150, 30),
-- Food & Beverages
('Coffee Beans 1kg', 3, 45.00, 120, 25),
('Green Tea 100g', 3, 15.99, 150, 30),
('Orange Juice 1L', 3, 8.99, 200, 40),
('Chocolate Bar', 3, 4.99, 300, 50),
('Mineral Water 6pk', 3, 12.99, 180, 35),
('Energy Drink', 3, 5.99, 250, 45),
-- Books
('Programming Book: Python', 4, 89.99, 40, 10),
('Novel: Best Seller', 4, 39.99, 60, 15),
('Magazine: Tech Monthly', 4, 12.99, 100, 20),
('Cookbook Deluxe', 4, 59.99, 35, 10),
('Comics Collection', 4, 29.99, 75, 18),
('Educational: Math', 4, 44.99, 50, 12),
-- Home & Garden
('Garden Hose 20m', 5, 99.99, 25, 8),
('Flower Pot Large', 5, 29.99, 80, 15),
('BBQ Grill Set', 5, 199.99, 20, 6),
('Lamp LED Desk', 5, 79.99, 60, 12),
('Storage Box 50L', 5, 34.99, 90, 18),
('Cleaning Kit Pro', 5, 49.99, 70, 15);

PRINT '✅ Products: 30';

-- 4. Customers (16 klientów)
INSERT INTO Customers (CompanyName, ContactName, Country, City, PostalCode) VALUES
('ABC Corp', 'Jan Nowak', 'Poland', 'Warsaw', '00-001'),
('XYZ Trading', 'Anna Kowalczyk', 'Poland', 'Krakow', '30-001'),
('Tech Solutions', 'Piotr Wisniewski', 'Poland', 'Gdansk', '80-001'),
('Retail Masters', 'Maria Wojcik', 'Poland', 'Wroclaw', '50-001'),
('Office Supplies Plus', 'Tomasz Kaminski', 'Poland', 'Poznan', '60-001'),
('Euro Distributors', 'Hans Mueller', 'Germany', 'Berlin', '10115'),
('UK Imports Ltd', 'James Smith', 'UK', 'London', 'SW1A 1AA'),
('Nordic Trade AS', 'Lars Olsen', 'Norway', 'Oslo', '0150'),
('FastTech Inc', 'Sarah Johnson', 'Poland', 'Lodz', '90-001'),
('MegaStore Co', 'Robert Brown', 'Poland', 'Szczecin', '70-001'),
('Quality Goods', 'Emma Davis', 'Germany', 'Munich', '80331'),
('Prime Traders', 'Michael Wilson', 'UK', 'Manchester', 'M1 1AA'),
('Smart Buy Ltd', 'Lisa Anderson', 'Poland', 'Lublin', '20-001'),
('Global Trade Hub', 'David Martinez', 'Netherlands', 'Amsterdam', '1012'),
('Elite Commerce', 'Sofia Garcia', 'Spain', 'Madrid', '28001'),
('ProBusiness Group', 'Carlos Rodriguez', 'Poland', 'Bydgoszcz', '85-001');

PRINT '✅ Customers: 16';

-- 5. Orders (400 zamówień w ostatnich 13 miesiącach)
DECLARE @i INT = 0;
DECLARE @CustomerID INT;
DECLARE @OrderDate DATETIME2;
DECLARE @Status NVARCHAR(20);

WHILE @i < 400
BEGIN
    SET @CustomerID = (FLOOR(RAND() * 16) + 1);  -- 16 klientów
    SET @OrderDate = DATEADD(DAY, -FLOOR(RAND() * 395), GETDATE());  -- ~13 miesięcy
    
    -- 80% Delivered, 10% Shipped, 5% Pending, 5% Cancelled
    DECLARE @StatusRand FLOAT = RAND();
    IF @StatusRand < 0.05 SET @Status = 'Cancelled'
    ELSE IF @StatusRand < 0.10 SET @Status = 'Pending'
    ELSE IF @StatusRand < 0.20 SET @Status = 'Shipped'
    ELSE SET @Status = 'Delivered';
    
    INSERT INTO Orders (CustomerID, OrderDate, Status, ShipCountry, ShipCity)
    VALUES (
        @CustomerID,
        @OrderDate,
        @Status,
        'Poland',
        'Warsaw'
    );
    
    SET @i = @i + 1;
END;

PRINT '✅ Orders: 400';

-- 6. OrderDetails (3-6 produktów per zamówienie)
DECLARE @OrderID INT;
DECLARE @ProductID INT;
DECLARE @Quantity INT;
DECLARE @Discount DECIMAL(4,2);

DECLARE order_cursor CURSOR FOR 
    SELECT OrderID FROM Orders WHERE Status != 'Cancelled';

OPEN order_cursor;
FETCH NEXT FROM order_cursor INTO @OrderID;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @ItemCount INT = FLOOR(RAND() * 4) + 3; -- 3-6 items
    DECLARE @j INT = 0;
    
    WHILE @j < @ItemCount
    BEGIN
        SET @ProductID = FLOOR(RAND() * 30) + 1;  -- 30 produktów
        SET @Quantity = FLOOR(RAND() * 8) + 1; -- 1-8 quantity
        
        -- 20% szansa na discount
        IF RAND() > 0.8
            SET @Discount = CASE FLOOR(RAND() * 3)
                WHEN 0 THEN 0.05
                WHEN 1 THEN 0.10
                ELSE 0.15
            END
        ELSE
            SET @Discount = 0.00;
        
        -- Sprawdź czy produkt już nie jest w tym zamówieniu
        IF NOT EXISTS (
            SELECT 1 FROM OrderDetails 
            WHERE OrderID = @OrderID AND ProductID = @ProductID
        )
        BEGIN
            INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice, Discount)
            SELECT 
                @OrderID,
                @ProductID,
                @Quantity,
                UnitPrice,
                @Discount
            FROM Products
            WHERE ProductID = @ProductID;
        END
        
        SET @j = @j + 1;
    END;
    
    FETCH NEXT FROM order_cursor INTO @OrderID;
END;

CLOSE order_cursor;
DEALLOCATE order_cursor;

PRINT '✅ OrderDetails created';

-- 7. Update TotalAmount in Orders
UPDATE Orders
SET TotalAmount = (
    SELECT ISNULL(SUM(LineTotal), 0)
    FROM OrderDetails
    WHERE OrderDetails.OrderID = Orders.OrderID
);

PRINT '✅ Order totals calculated';

-- 8. Update ShippedDate dla zamówień Shipped i Delivered
UPDATE Orders
SET ShippedDate = DATEADD(DAY, FLOOR(RAND(CHECKSUM(NEWID())) * 5) + 1, OrderDate)
WHERE Status IN ('Shipped', 'Delivered');

PRINT '✅ Shipped dates updated';

-- 9. Inventory Transactions
INSERT INTO InventoryTransactions (ProductID, TransactionType, Quantity, TransactionDate, Notes)
SELECT 
    ProductID,
    'Purchase',
    UnitsInStock,
    DATEADD(DAY, -30, GETDATE()),
    'Initial stock'
FROM Products;

PRINT '✅ Inventory transactions created';

-- ==================== SUMMARY ====================
PRINT '';
PRINT '========================================';
PRINT '     DATA IMPORT SUMMARY';
PRINT '========================================';
PRINT 'Categories:           5';
PRINT 'Suppliers:            5';
PRINT 'Products:            30';
PRINT 'Customers:           16';
PRINT 'Orders:             400';

SELECT @i = COUNT(*) FROM OrderDetails;
PRINT 'OrderDetails:     ~' + CAST(@i AS NVARCHAR(10));

PRINT '';
PRINT '✅ Sample data inserted successfully!';
PRINT '========================================';
GO