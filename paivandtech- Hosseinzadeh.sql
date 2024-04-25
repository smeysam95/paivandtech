USE AdventureWorksDW2022

----------------------Question1-------------------------
SELECT 
       DG.CountryRegionCode AS CountryCode, DG.EnglishCountryRegionName,
       SUM(FIS.SalesAmount) AS TotalSales 
  FROM FactInternetSales AS FIS inner JOIN DimGeography AS DG 
	ON FIS.SalesTerritoryKey = DG.SalesTerritoryKey 
  GROUP BY DG.CountryRegionCode, DG.EnglishCountryRegionName;

----------------------Question2-------------------------

WITH RankedCustomers AS (
    SELECT
        CustomerKey,
        SUM(SalesAmount) AS TotalPurchase,
        ROW_NUMBER() OVER (ORDER BY SUM(SalesAmount) DESC) AS PurchaseRank
    FROM
        FactInternetSales
    GROUP BY
        CustomerKey
)
SELECT
    RC.CustomerKey,
	DC.FirstName + ' - ' + DC.LastName AS Fullname,
	TotalPurchase
FROM
    RankedCustomers RC inner join DimCustomer DC
	on RC.CustomerKey = DC.CustomerKey
WHERE
    PurchaseRank = 2;

----------------------Question3-------------------------

WITH SubcategorySales AS (
    SELECT 
        PC.EnglishProductCategoryName,
        PS.EnglishProductSubcategoryName,
        SUM(FIS.SalesAmount) AS TotalSales,
        ROW_NUMBER() OVER (PARTITION BY PC.EnglishProductCategoryName ORDER BY SUM(FIS.SalesAmount) DESC) AS Rank
    FROM 
        FactInternetSales AS FIS
    JOIN 
        DimProduct AS DP ON FIS.ProductKey = DP.ProductKey
    JOIN 
        DimProductSubcategory AS PS ON DP.ProductSubcategoryKey = PS.ProductSubcategoryKey
    JOIN 
        DimProductCategory AS PC ON PS.ProductCategoryKey = PC.ProductCategoryKey
    GROUP BY 
        PC.EnglishProductCategoryName, PS.EnglishProductSubcategoryName
)
SELECT 
    EnglishProductCategoryName,
    EnglishProductSubcategoryName,
    TotalSales,
    Rank
FROM 
    SubcategorySales
ORDER BY 
    EnglishProductCategoryName, Rank;

----------------------Question4-------------------------

CREATE PROCEDURE GetInternetSalesInvoiceCountByProductID
    @ProductID INT
AS
BEGIN
    SELECT 
        COUNT(DISTINCT SalesOrderNumber) AS InvoiceCount
    FROM 
        FactInternetSales
    WHERE 
        ProductKey = @ProductID;
END;



EXEC GetInternetSalesInvoiceCountByProductID @ProductID = 477;

----------------------Question5-------------------------

CREATE PROCEDURE GetInternetSalesGrowthByYear
    @Year INT
AS
BEGIN
    IF @Year BETWEEN 2010 AND 2014
    BEGIN
        SELECT
            DATEPART(MONTH, OrderDate) AS Month,
            SUM(SalesAmount) AS TotalSales,
            (SUM(SalesAmount) - LAG(SUM(SalesAmount)) OVER (ORDER BY DATEPART(MONTH, OrderDate))) / LAG(SUM(SalesAmount)) OVER (ORDER BY DATEPART(MONTH, OrderDate)) AS SalesGrowth
        FROM
            FactInternetSales
        WHERE
            YEAR(OrderDate) = @Year
        GROUP BY
            DATEPART(MONTH, OrderDate)
        ORDER BY
            Month;
    END
    ELSE
    BEGIN
        PRINT 'Error: The year must be between 2010 and 2014.';
    END
END;

EXEC GetInternetSalesGrowthByYear @Year = 2013;
