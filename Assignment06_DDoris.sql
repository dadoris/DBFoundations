--*************************************************************************--
-- Title: Assignment06
-- Author: David Doris
-- Desc: This file demonstrates how to use Views
-- Change Log: 2022-05-22,David Doris, Created File
--**************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment06DB_DDoris')
	 Begin 
	  Alter Database [Assignment06DB_DDoris] set Single_user With Rollback Immediate;
	  Drop Database Assignment06DB_DDoris;
	 End
	Create Database Assignment06DB_DDoris;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment06DB_DDoris;

-- Create Tables (Module 01)-- 
Create Table Categories
([CategoryID] [int] IDENTITY(1,1) NOT NULL 
,[CategoryName] [nvarchar](100) NOT NULL
);
go

Create Table Products
([ProductID] [int] IDENTITY(1,1) NOT NULL 
,[ProductName] [nvarchar](100) NOT NULL 
,[CategoryID] [int] NULL  
,[UnitPrice] [mOney] NOT NULL
);
go

Create Table Employees -- New Table
([EmployeeID] [int] IDENTITY(1,1) NOT NULL 
,[EmployeeFirstName] [nvarchar](100) NOT NULL
,[EmployeeLastName] [nvarchar](100) NOT NULL 
,[ManagerID] [int] NULL  
);
go

Create Table Inventories
([InventoryID] [int] IDENTITY(1,1) NOT NULL
,[InventoryDate] [Date] NOT NULL
,[EmployeeID] [int] NOT NULL -- New Column
,[ProductID] [int] NOT NULL
,[Count] [int] NOT NULL
);
go

-- Add Constraints (Module 02) -- 
Begin  -- Categories
	Alter Table Categories 
	 Add Constraint pkCategories 
	  Primary Key (CategoryId);

	Alter Table Categories 
	 Add Constraint ukCategories 
	  Unique (CategoryName);
End
go 

Begin -- Products
	Alter Table Products 
	 Add Constraint pkProducts 
	  Primary Key (ProductId);

	Alter Table Products 
	 Add Constraint ukProducts 
	  Unique (ProductName);

	Alter Table Products 
	 Add Constraint fkProductsToCategories 
	  Foreign Key (CategoryId) References Categories(CategoryId);

	Alter Table Products 
	 Add Constraint ckProductUnitPriceZeroOrHigher 
	  Check (UnitPrice >= 0);
End
go

Begin -- Employees
	Alter Table Employees
	 Add Constraint pkEmployees 
	  Primary Key (EmployeeId);

	Alter Table Employees 
	 Add Constraint fkEmployeesToEmployeesManager 
	  Foreign Key (ManagerId) References Employees(EmployeeId);
End
go

Begin -- Inventories
	Alter Table Inventories 
	 Add Constraint pkInventories 
	  Primary Key (InventoryId);

	Alter Table Inventories
	 Add Constraint dfInventoryDate
	  Default GetDate() For InventoryDate;

	Alter Table Inventories
	 Add Constraint fkInventoriesToProducts
	  Foreign Key (ProductId) References Products(ProductId);

	Alter Table Inventories 
	 Add Constraint ckInventoryCountZeroOrHigher 
	  Check ([Count] >= 0);

	Alter Table Inventories
	 Add Constraint fkInventoriesToEmployees
	  Foreign Key (EmployeeId) References Employees(EmployeeId);
End 
go

-- Adding Data (Module 04) -- 
Insert Into Categories 
(CategoryName)
Select CategoryName 
 From Northwind.dbo.Categories
 Order By CategoryID;
go

Insert Into Products
(ProductName, CategoryID, UnitPrice)
Select ProductName,CategoryID, UnitPrice 
 From Northwind.dbo.Products
  Order By ProductID;
go

Insert Into Employees
(EmployeeFirstName, EmployeeLastName, ManagerID)
Select E.FirstName, E.LastName, IsNull(E.ReportsTo, E.EmployeeID) 
 From Northwind.dbo.Employees as E
  Order By E.EmployeeID;
go

Insert Into Inventories
(InventoryDate, EmployeeID, ProductID, [Count])
Select '20170101' as InventoryDate, 5 as EmployeeID, ProductID, UnitsInStock
From Northwind.dbo.Products
UNIOn
Select '20170201' as InventoryDate, 7 as EmployeeID, ProductID, UnitsInStock + 10 -- Using this is to create a made up value
From Northwind.dbo.Products
UNIOn
Select '20170301' as InventoryDate, 9 as EmployeeID, ProductID, UnitsInStock + 20 -- Using this is to create a made up value
From Northwind.dbo.Products
Order By 1, 2
go

-- Show the Current data in the Categories, Products, and Inventories Tables
Select * From Categories;
go
Select * From Products;
go
Select * From Employees;
go
Select * From Inventories;
go

/********************************* Questions and Answers *********************************/
--print 
--'NOTES------------------------------------------------------------------------------------ 
-- 1) You can use any name you like for you views, but be descriptive and consistent
-- 2) You can use your working code from assignment 5 for much of this assignment
-- 3) You must use the BASIC views for each table after they are created in Question 1
--------------------------------------------------------------------------------------------'

-- Question 1 (5% pts): How can you create BASIC views to show data from each table in the database.
-- NOTES: 1) Do not use a *, list out each column!
--        2) Create one view per table!
--		  3) Use SchemaBinding to protect the views from being orphaned!


CREATE OR ALTER VIEW 
	vCategories
AS 
SELECT 
	c.CategoryID
  , c.CategoryName 
FROM 
	Categories c  ;

GO

CREATE OR ALTER VIEW
	vProducts
AS SELECT 
	p.CategoryID
  , p.ProductID
  , p.ProductName
  , p.UnitPrice
FROM 
	Products p  ;

GO 

CREATE OR ALTER VIEW
    vEmployees
AS SELECT
	e.EmployeeID
  , e.EmployeeFirstName
  , e.EmployeeLastName
  , e.ManagerID
FROM 
    Employees e  ;

GO 

CREATE OR ALTER VIEW
    vInventories
AS
SELECT 
    i.InventoryID
  , i.InventoryDate
  , i.[Count]
  , i.EmployeeID
  , i.ProductID
FROM 
    Inventories i ;

GO

-- Question 2 (5% pts): How can you set permissions, so that the public group CANNOT select data 
-- from each table, but can select data from each view?


-- I would execute the following commands to prevent accessing the base tables
-- while allowing access to the views:
Deny Select On Categories to Public;
Grant Select On vCategories to Public;

Deny Select On Products to Public;
Grant Select On vProducts to Public;

Deny Select On Employees to Public;
Grant Select On vEmployees to Public;

Deny Select On Inventories to Public;
Grant Select On vInventories to Public;


GO

--All users are members of the Public group, and usually the public group has 
--permission to very little if anything in the database and what they can access is
--explicitly granted by a database administrator. 




-- Question 3 (10% pts): How can you create a view to show a list of Category and Product names, 
-- and the price of each product?
-- Order the result by the Category and Product!

-- Here is an example of some rows selected from the view:
-- CategoryName ProductName       UnitPrice
-- Beverages    Chai              18.00
-- Beverages    Chang             19.00
-- Beverages    Chartreuse verte  18.00

CREATE OR ALTER VIEW
    vCategoryProductReport
AS SELECT TOP 1000000000 
    c.CategoryName
  , p.ProductName
  , p.UnitPrice
FROM 
    Categories c
JOIN 
    Products p
ON 
   c.CategoryID = p.CategoryID
ORDER BY 
   c.CategoryName, p.ProductName
GO
--select * from vCategoryProductReport;

-- Question 4 (10% pts): How can you create a view to show a list of Product names 
-- and Inventory Counts on each Inventory Date?
-- Order the results by the Product, Date, and Count!

-- Here is an example of some rows selected from the view:
-- ProductName	  InventoryDate	Count
-- Alice Mutton	  2017-01-01	  0
-- Alice Mutton	  2017-02-01	  10
-- Alice Mutton	  2017-03-01	  20
-- Aniseed Syrup	2017-01-01	  13
-- Aniseed Syrup	2017-02-01	  23
-- Aniseed Syrup	2017-03-01	  33


CREATE OR ALTER VIEW
    vProductName_InventoryCount_ByDate
AS SELECT TOP 100000000
    p.ProductName
  , i.InventoryDate
  , i.[Count]
FROM 
    Products p
JOIN 
    Inventories i
ON 
    p.ProductID = i.ProductID
ORDER BY 
    p.ProductName
  , i.InventoryDate
  , i.[Count] ; 

GO 
--select top 10 * from     vProductName_InventoryCount_ByDate




-- Question 5 (10% pts): How can you create a view to show a list of Inventory Dates 
-- and the Employee that took the count?
-- Order the results by the Date and return only one row per date!

-- Here is are the rows selected from the view:

-- InventoryDate	EmployeeName
-- 2017-01-01	    Steven Buchanan
-- 2017-02-01	    Robert King
-- 2017-03-01	    Anne Dodsworth

CREATE OR ALTER VIEW
    vInventoryDate_byEmployeeName
AS SELECT TOP 10000000
    i.InventoryDate
  , e.EmployeeFirstName + ' ' + e.EmployeeLastName as [employee name]
FROM 
    Inventories i
JOIN 
    Employees e
ON 
    i.EmployeeID = e.EmployeeID
GROUP BY 
    i.inventorydate
  , e.EmployeeFirstName + ' ' + e.EmployeeLastName ;

GO
--SELECT  * FROM vInventoryDate_byEmployeeName



-- Question 6 (10% pts): How can you create a view show a list of Categories, Products, 
-- and the Inventory Date and Count of each product?
-- Order the results by the Category, Product, Date, and Count!

-- Here is an example of some rows selected from the view:
-- CategoryName,ProductName,InventoryDate,Count
-- CategoryName	ProductName	InventoryDate	Count
-- Beverages	  Chai	      2017-01-01	  39
-- Beverages	  Chai	      2017-02-01	  49
-- Beverages	  Chai	      2017-03-01	  59
-- Beverages	  Chang	      2017-01-01	  17
-- Beverages	  Chang	      2017-02-01	  27
-- Beverages	  Chang	      2017-03-01	  37

CREATE OR ALTER VIEW
    vInventoriesByProductsByCategories
AS SELECT  TOP 10000000
    c.CategoryName
	, p.ProductName
	, i.InventoryDate
	, i.[Count]	 as [Inventory Count]
FROM 
	Products p
JOIN 
	Inventories i
ON 
	p.ProductID = i.ProductID
JOIN
	Categories c
ON 
	p.CategoryID = c.CategoryID
ORDER BY
	 c.CategoryName
   , p.ProductName
   , i.InventoryDate
   , i.[Count];
GO
--SELECT * FROM vInventoriesByProductsByCategories;


-- Question 7 (10% pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the EMPLOYEE who took the count?
-- Order the results by the Inventory Date, Category, Product and Employee!

-- Here is an example of some rows selected from the view:
-- CategoryName	ProductName	        InventoryDate	Count	EmployeeName
-- Beverages	  Chai	              2017-01-01	  39	  Steven Buchanan
-- Beverages	  Chang	              2017-01-01	  17	  Steven Buchanan
-- Beverages	  Chartreuse verte	  2017-01-01	  69	  Steven Buchanan
-- Beverages	  Côte de Blaye	      2017-01-01	  17	  Steven Buchanan
-- Beverages	  Guaraná Fantástica	2017-01-01	  20	  Steven Buchanan
-- Beverages	  Ipoh Coffee	        2017-01-01	  17	  Steven Buchanan
-- Beverages	  Lakkalikööri	      2017-01-01	  57	  Steven Buchanan



CREATE OR ALTER VIEW
    vInventoriesByProductsByEmployees
AS SELECT  TOP 1000000
    c.CategoryName
  , p.ProductName
  , i.InventoryDate
  , i.[Count]	 as [Inventory Count]
  , e.EmployeeFirstName + ' ' + e.EmployeeLastName as [Employee Name]
FROM 
	Products p
JOIN 
	Inventories i
ON 
	p.ProductID = i.ProductID
JOIN
	Categories c
ON 
	p.CategoryID = c.CategoryID
JOIN
	Employees e
on
	i.EmployeeID = e.EmployeeID
ORDER BY
    i.InventoryDate
  , c.CategoryName
  , p.ProductName
  ,  e.EmployeeFirstName + ' ' + e.EmployeeLastName ;
GO
--SELECT * FROM vInventoriesByProductsByEmployees









-- Question 8 (10% pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the Employee who took the count
-- for the Products 'Chai' and 'Chang'? 

-- Here are the rows selected from the view:

-- CategoryName	ProductName	InventoryDate	Count	EmployeeName
-- Beverages	  Chai	      2017-01-01	  39	  Steven Buchanan
-- Beverages	  Chang	      2017-01-01	  17	  Steven Buchanan
-- Beverages	  Chai	      2017-02-01	  49	  Robert King
-- Beverages	  Chang	      2017-02-01	  27	  Robert King
-- Beverages	  Chai	      2017-03-01	  59	  Anne Dodsworth
-- Beverages	  Chang	      2017-03-01	  37	  Anne Dodsworth

CREATE OR ALTER VIEW
    vInventoriesForChaiAndChangByEmployees
AS SELECT TOP 10000000
    c.CategoryName
  , p.ProductName
  , i.InventoryDate
  , i.[Count]	 as [Inventory Count]
  , e.EmployeeFirstName + ' ' + e.EmployeeLastName as [Employee Name]
FROM 
	(SELECT 
		psub.CategoryID
	  , psub.ProductID
	  , psub.ProductName
	  , psub.UnitPrice  
	 FROM PRODUCTS psub 
	 WHERE psub.ProductName IN ('Chai', 'Chang') ) p
JOIN 
	Inventories i
ON 
	p.ProductID = i.ProductID
JOIN
	Categories c
ON 
	p.CategoryID = c.CategoryID
JOIN
	Employees e
ON
	i.EmployeeID = e.EmployeeID
ORDER BY
    i.InventoryDate
  , c.CategoryName
  , p.ProductName
  , e.EmployeeFirstName + ' ' + e.EmployeeLastName ;
GO
--SELECT * FROM vInventoriesForChaiAndChangByEmployees



-- Question 9 (10% pts): How can you create a view to show a list of Employees and the Manager who manages them?
-- Order the results by the Manager's name!

-- Here are teh rows selected from the view:
-- Manager	        Employee
-- Andrew Fuller	  Andrew Fuller
-- Andrew Fuller	  Janet Leverling
-- Andrew Fuller	  Laura Callahan
-- Andrew Fuller	  Margaret Peacock
-- Andrew Fuller	  Nancy Davolio
-- Andrew Fuller	  Steven Buchanan
-- Steven Buchanan	Anne Dodsworth
-- Steven Buchanan	Michael Suyama
-- Steven Buchanan	Robert King


CREATE OR ALTER VIEW
    vEmployeesByManager
AS SELECT TOP 1000000
    m.EmployeeFirstName + ' ' + m.EmployeeLastName as [Manager Name]
  , e.EmployeeFirstName + ' ' + e.EmployeeLastName  as [Employee Name]
FROM 
    Employees e
JOIN 
    Employees m
ON 
    e.ManagerID = m.EmployeeID
ORDER BY    
    m.EmployeeFirstName 
  , e.EmployeeFirstName	 	;
GO
--SELECT * FROM vEmployeesByManager ;




-- Question 10 (20% pts): How can you create one view to show all the data from all four 
-- BASIC Views? Also show the Employee's Manager Name and order the data by 
-- Category, Product, InventoryID, and Employee.

-- Here is an example of some rows selected from the view:
-- CategoryID	  CategoryName	ProductID	ProductName	        UnitPrice	InventoryID	InventoryDate	Count	EmployeeID	Employee
-- 1	          Beverages	    1	        Chai	              18.00	    1	          2017-01-01	  39	  5	          Steven Buchanan
-- 1	          Beverages	    1	        Chai	              18.00	    78	        2017-02-01	  49	  7	          Robert King
-- 1	          Beverages	    1	        Chai	              18.00	    155	        2017-03-01	  59	  9	          Anne Dodsworth
-- 1	          Beverages	    2	        Chang	              19.00	    2	          2017-01-01	  17	  5	          Steven Buchanan
-- 1	          Beverages	    2	        Chang	              19.00	    79	        2017-02-01	  27	  7	          Robert King
-- 1	          Beverages	    2	        Chang	              19.00	    156	        2017-03-01	  37	  9	          Anne Dodsworth
-- 1	          Beverages	    24	      Guaraná Fantástica	4.50	    24	        2017-01-01	  20	  5	          Steven Buchanan
-- 1	          Beverages	    24	      Guaraná Fantástica	4.50	    101	        2017-02-01	  30	  7	          Robert King
-- 1	          Beverages	    24	      Guaraná Fantástica	4.50	    178	        2017-03-01	  40	  9	          Anne Dodsworth
-- 1	          Beverages	    34	      Sasquatch Ale	      14.00	    34	        2017-01-01	  111	  5	          Steven Buchanan
-- 1	          Beverages	    34	      Sasquatch Ale	      14.00	    111	        2017-02-01	  121	  7	          Robert King
-- 1	          Beverages	    34	      Sasquatch Ale	      14.00	    188	        2017-03-01	  131	  9	          Anne Dodsworth


CREATE OR ALTER VIEW
    vInventoriesByProductsByCategoriesByEmployees
AS SELECT TOP 10000000
	vc.*
	,vp.ProductID
	,vp.ProductName
	,vp.UnitPrice
	,vi.InventoryID
	,vi.InventoryDate
	,vi.[Count]
	,ve.EmployeeID
	,ve.EmployeeFirstName + ' ' + ve.EmployeeLastName as Employee 
	,vm.EmployeeFirstName + ' ' + vm.EmployeeLastName as Manager
FROM 
    vcategories vc
FULL JOIN 
    vProducts vp
ON 
    vc.CategoryID = vp.CategoryID
FULL JOIN 
    vInventories vi
ON 
    vp.ProductID = vi.ProductID
JOIN 
    vEmployees ve
ON 
    vi.EmployeeID = ve.EmployeeID
JOIN 
    vEmployees vm
ON 
    ve.ManagerID = vm.EmployeeID
ORDER BY 
    vc.CategoryID
  , vp.ProductID
  , vi.InventoryID
  , ve.EmployeeID    ;

GO
--SELECT * FROM vInventoriesByProductsByCategoriesByEmployees ;

-- Test your Views (NOTE: You must change the names to match yours as needed!)
Print 'Note: You will get an error until the views are created!'

PRINT 'question 1'
PRINT 'vCategories view'
SELECT * FROM [dbo].[vCategories]

PRINT 'vProducts view'
SELECT * FROM [dbo].[vProducts]

PRINT 'vEmployees view'
SELECT * FROM [dbo].[vEmployees]

PRINT 'vInventories view'
SELECT * FROM [dbo].[vInventories]
GO

PRINT 'question 3 - vCategoryProductReport'
SELECT * FROM [dbo].[vCategoryProductReport]
GO

PRINT 'quesiton 4 - vProductName_InventoryCount_ByDate'
SELECT * FROM [dbo].[vProductName_InventoryCount_ByDate]
GO

PRINT 'question 5 - vInventoryDate_byEmployeeName'
SELECT * FROM [dbo].[vInventoryDate_byEmployeeName]
GO

PRINT 'question 6 - vInventoriesByProductsByCategories' 
SELECT * FROM [dbo].[vInventoriesByProductsByCategories]
GO

PRINT 'question 7 - vInventoriesByProductsByEmployees'
SELECT * FROM [dbo].[vInventoriesByProductsByEmployees]
GO

PRINT 'question 8 - vInventoriesForChaiAndChangByEmployees'
SELECT * FROM [dbo].[vInventoriesForChaiAndChangByEmployees]
GO

PRINT 'question 9 - vEmployeesByManager'
SELECT * FROM [dbo].[vEmployeesByManager]
GO

PRINT 'question 10 - vInventoriesByProductsByCategoriesByEmployees' 
SELECT * FROM [dbo].[vInventoriesByProductsByCategoriesByEmployees]
GO

/***************************************************************************************/