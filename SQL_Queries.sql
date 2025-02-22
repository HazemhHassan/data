/*
-- a)	Sales and Revenue Analysis:
*/
-- 1•	What is the total revenue generated by different product categories?
SELECT PC.name AS productcategory, SUM(OrderQty*UnitPrice) AS TotalRevenue
FROM Production.Product PD 
INNER JOIN Production.ProductSubcategory PS ON PD.ProductSubcategoryID = PS.ProductSubcategoryID 
INNER JOIN Production.ProductCategory PC ON PS.ProductCategoryID = PC.ProductCategoryID
INNER JOIN Sales.SalesOrderDetail SOD ON PD.ProductID = SOD.ProductID
GROUP BY PC.name
ORDER BY TotalRevenue desc
;

-- 2•	What is the trend of sales orders over the last year?
SELECT YEAR(soh.OrderDate) AS Year, MONTH(soh.OrderDate) AS Month, COUNT(soh.SalesOrderID) AS TotalOrders
FROM Sales.SalesOrderHeader SOH
WHERE YEAR(soh.OrderDate) = 2014
GROUP BY YEAR(soh.OrderDate), MONTH(soh.OrderDate)
ORDER BY Year, Month
;

-- 3•	What is the trend of sales orders over 2 years?
SELECT MIN(OrderDate), MAX(OrderDate)
FROM Sales.SalesOrderHeader
;

WITH TopProducts AS (
    SELECT TOP 3 SOD.ProductID, SUM(sod.LineTotal) AS TotalSales
    FROM Sales.SalesOrderDetail SOD
    JOIN Sales.SalesOrderHeader SOH ON SOD.SalesOrderID = SOH.SalesOrderID
    WHERE YEAR(SOH.OrderDate) BETWEEN 2012 AND 2013
    GROUP BY SOD.ProductID
    ORDER BY TotalSales DESC

)
SELECT PD.Name AS ProductName, YEAR(SOH.OrderDate) AS SalesYear, MONTH(SOH.OrderDate) AS SalesMonth, SUM(SOD.LineTotal) AS MonthlySales
FROM Sales.SalesOrderDetail SOD
JOIN Sales.SalesOrderHeader SOH ON SOD.SalesOrderID = SOH.SalesOrderID
JOIN Production.Product PD ON SOD.ProductID = PD.ProductID
JOIN TopProducts TP ON SOD.ProductID = TP.ProductID
WHERE YEAR(SOH.OrderDate) BETWEEN 2012 AND 2013
GROUP BY PD.Name, YEAR(SOH.OrderDate), MONTH(SOH.OrderDate)
ORDER BY PD.Name, SalesYear, SalesMonth
; 

-- 4•	Which months or quarters see the highest sales activity?
SELECT 
    YEAR(soh.OrderDate) AS Year, DATEPART(QUARTER, soh.OrderDate) AS Quarter, 
    SUM(sod.LineTotal) AS TotalRevenue
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY YEAR(soh.OrderDate), DATEPART(QUARTER, soh.OrderDate)
ORDER BY TotalRevenue DESC
;

-- 5•	Sales performance difference from online and instore.
SELECT
    CASE
        WHEN OnlineOrderFlag = 1 THEN 'Online Store'
        ELSE 'Physical Store'
    END AS StoreType, 
	COUNT(SalesOrderID) AS TotalOrders, SUM(TotalDue) AS TotalSales, AVG(TotalDue) AS AverageOrderValue
FROM Sales.SalesOrderHeader
GROUP BY OnlineOrderFlag
;

-- 6•	Discount or offers relation to sales.
SELECT 
    CASE 
        WHEN SOD.UnitPriceDiscount > 0 THEN 'Discounted'
        ELSE 'Non-Discounted'
    END AS DiscountType,
    SUM(SOD.LineTotal) AS TotalSales, COUNT(SOH.SalesOrderID) AS TotalOrders, AVG(SOD.LineTotal) AS AverageOrderValue
FROM Sales.SalesOrderDetail SOD
JOIN Sales.SalesOrderHeader SOH ON SOD.SalesOrderID = SOH.SalesOrderID
GROUP BY CASE 
			WHEN SOD.UnitPriceDiscount > 0 THEN 'Discounted'
			ELSE 'Non-Discounted'
		 END
ORDER BY  DiscountType
;

/*
-- b)	 Customer Insights:
*/
-- 1•	How does customer spending vary by region or country?
SELECT st.Name AS TerritoryName, SUM(sod.LineTotal) AS TotalSpent
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
GROUP BY st.Name
ORDER BY TotalSpent DESC
;

-- 2•	What is the average revenue per customer?
SELECT AVG(CustomerRevenue.TotalSpent) AS AvgRevenuePerCustomer
FROM (
    SELECT soh.CustomerID, SUM(sod.LineTotal) AS TotalSpent
    FROM Sales.SalesOrderHeader soh
    JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
    GROUP BY soh.CustomerID
) AS CustomerRevenue
;

-- 3•	Type of Customers and their orders value and volume.
WITH CustomerOrders AS (
    SELECT soh.CustomerID, COUNT(soh.SalesOrderID) AS OrderCount
    FROM Sales.SalesOrderHeader soh
    GROUP BY soh.CustomerID
)
SELECT 
    CASE 
        WHEN co.OrderCount = 1 THEN 'One-Time Customer'
		WHEN co.OrderCount > 1 AND co.OrderCount<= 10 THEN 'Occasional Customer'
        ELSE 'Frequent Customer'
    END AS CustomerType,
    COUNT(co.CustomerID) AS CustomerVolume, SUM(co.OrderCount) AS OrderVolume
FROM CustomerOrders co
GROUP BY CASE 
        WHEN co.OrderCount = 1 THEN 'One-Time Customer'
		WHEN co.OrderCount > 1 AND co.OrderCount<= 10 THEN 'Occasional Customer'
        ELSE 'Frequent Customer'
    END
ORDER BY OrderVolume DESC
;

/*
-- c)	 Product Analysis:
*/
-- 1•	Which products have the highest sales volume?
SELECT TOP 10 p.Name AS ProductName, SUM(sod.OrderQty) AS TotalQuantitySold
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
GROUP BY p.Name
ORDER BY TotalQuantitySold DESC
;

-- 2•	What is the relationship between product price and sales quantity?
SELECT p.Name AS ProductName, p.ListPrice AS UnitPrice, SUM(sod.OrderQty) AS TotalQuantitySold
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
GROUP BY p.Name, p.ListPrice
ORDER BY UnitPrice
;

-- 3•	Average order size for each category.
SELECT PC.Name, AVG(SOD.OrderQty) as Average_Order_Size
FROM Sales.SalesOrderDetail SOD
JOIN Production.Product P ON SOD.ProductID = P.ProductID
JOIN Production.ProductSubcategory PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
JOIN Production.ProductCategory PC ON PS.ProductCategoryID = PC.ProductCategoryID
GROUP BY Pc.Name
ORDER BY Average_Order_Size DESC
;

-- 4•	Which products which people often purchase together?
WITH OrderProducts AS (
    SELECT sod.SalesOrderID, sod.ProductID
    FROM Sales.SalesOrderDetail sod
)

SELECT TOP 10 p1.Name AS Product1, p2.Name AS Product2, COUNT(*) AS PairCount
FROM OrderProducts op1
JOIN OrderProducts op2 ON op1.SalesOrderID = op2.SalesOrderID
JOIN Production.Product p1 ON op1.ProductID = p1.ProductID
JOIN Production.Product p2 ON op2.ProductID = p2.ProductID
WHERE op1.ProductID < op2.ProductID  -- Avoid duplicate and self-pairing
GROUP BY p1.Name, p2.Name
ORDER BY PairCount DESC
;

/*
-- d)	 Salesperson Performance:
*/
-- 1•	Who are the top-performing salespeople based on revenue?
SELECT TOP 3 sp.BusinessEntityID AS SalespersonID, p.FirstName, p.LastName, SUM(sod.LineTotal) AS TotalRevenue
FROM Sales.SalesPerson sp
JOIN HumanResources.Employee e ON sp.BusinessEntityID = e.BusinessEntityID
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
JOIN Sales.SalesOrderHeader soh ON sp.BusinessEntityID = soh.SalesPersonID
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY sp.BusinessEntityID, p.FirstName, p.LastName
ORDER BY TotalRevenue DESC
;

-- 2•	What is the average sales performance per region by sales team?
SELECT st.Name AS TerritoryName, AVG(sod.LineTotal) AS AvgRevenuePerTerritory
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
GROUP BY st.Name
ORDER BY AvgRevenuePerTerritory DESC
;

-- 3•	Top performing sales person in each area.
SELECT TOP 5 SP.BusinessEntityID, P.FirstName, P.LastName, ST.Name AS Territory_Name, SUM(sod.LineTotal) AS Total_Sales
FROM Sales.SalesOrderHeader SOH
JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
JOIN Sales.SalesPerson SP ON SP.BusinessEntityID = SOH.SalesPersonID
JOIN Sales.SalesTerritory ST ON SOH.TerritoryID = ST.TerritoryID
JOIN Person.Person p ON SP.BusinessEntityID = P.BusinessEntityID
GROUP BY SP.BusinessEntityID, P.FirstName, P.LastName, ST.Name
ORDER BY Total_Sales DESC
;

/*
-- e)	 Regional/Geographical Insights:
*/
-- 1•	What are the sales figures for each region/country?
SELECT st.Name AS TerritoryName, SUM(sod.LineTotal) AS TotalSales
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
GROUP BY st.Name
ORDER BY TotalSales DESC
;
