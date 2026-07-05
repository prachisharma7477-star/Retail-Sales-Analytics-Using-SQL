/*
=================================================================

                    Retail Sales Analytics using SQL

Author : Prachi Sharma

Project Type :
Business Intelligence | Data Analytics

Project Description :

Designed a relational retail database and performed
business analysis using SQL.

This project answers key business questions by utilizing
advanced SQL concepts such as:

• Joins
• Aggregate Functions
• CASE Statements
• Window Functions
• CTEs
• Subqueries
• Ranking Functions

=================================================================
*/

/*=========================================================
SECTION 1 : DATABASE CREATION
=========================================================*/
-- Create and use the database
CREATE DATABASE RetailDB_4;
USE RetailDB_4;


/*=========================================================
SECTION 2 : DATABASE SCHEMA
=========================================================*/
-- 1. Customers Table
CREATE TABLE Customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    city VARCHAR(50),
    signup_date DATE
);

-- 2. Suppliers Table
CREATE TABLE Suppliers (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_name VARCHAR(100),
    contact_email VARCHAR(100),
    city VARCHAR(50)
);

-- 3. Shippers Table
CREATE TABLE Shippers (
    shipper_id INT AUTO_INCREMENT PRIMARY KEY,
    shipper_name VARCHAR(100),
    contact VARCHAR(100)
);

-- 4. Payment Methods Table
CREATE TABLE Payment_Methods (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    payment_type VARCHAR(50) UNIQUE
);

-- 5. Products Table
CREATE TABLE Products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2),
    stock_qty INT,
    supplier_id INT,
    FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id)
);

-- 6. Orders Table (Normalized)
CREATE TABLE Orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    payment_id INT,
    shipper_id INT,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    FOREIGN KEY (payment_id) REFERENCES Payment_Methods(payment_id),
    FOREIGN KEY (shipper_id) REFERENCES Shippers(shipper_id)
);

-- 7. Order_Items Table
CREATE TABLE Order_Items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    price_each DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

/*=========================================================
SECTION 3 : DATA VALIDATION
=========================================================*/
SELECT * FROM Customers;
SELECT * FROM Orders;
SELECT * FROM Products;
SELECT * FROM Suppliers;
SELECT * FROM Order_Items;
SELECT * FROM Payment_Methods;
SELECT * FROM Shippers;

/*=========================================================
SECTION 4 : BUSINESS ANALYSIS
=========================================================*/
-- Part A: Joins, Group By, Order By & Aggregations

/*=========================================================
Business Question 1
Which shipping partner generated the highest total revenue?
=========================================================*/
SELECT s.shipper_name, SUM(oi.quantity * oi.price_each) AS total_revenue
FROM Shippers s
JOIN Orders o ON s.shipper_id = o.shipper_id
JOIN Order_Items oi ON o.order_id = oi.order_id
GROUP BY s.shipper_name;

/*=========================================================
Business Question 2
Who are the top 5 highest-spending customers?
=========================================================*/
SELECT c.name, SUM(oi.quantity * oi.price_each) AS total_spent
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN Order_Items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.name
ORDER BY total_spent DESC
LIMIT 5;

/*=========================================================
Business Question 3
Which product categories have an average selling price above ₹8,000?
=========================================================*/
SELECT category, AVG(price) as avg_price
FROM Products
GROUP BY category
HAVING AVG(price) > 8000;

/*=========================================================
Business Question 4
Which cities placed the highest number of orders?
=========================================================*/
SELECT c.city, COUNT(o.order_id) AS total_orders
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.city
ORDER BY total_orders DESC;

/*=========================================================
Business Question 5
Which suppliers provide products across multiple categories?
=========================================================*/
SELECT s.supplier_name, COUNT(DISTINCT p.category) AS categories_supplied
FROM Suppliers s
JOIN Products p ON s.supplier_id = p.supplier_id
GROUP BY s.supplier_id, s.supplier_name
HAVING categories_supplied > 1;

/*=========================================================
Business Question 6
How many items are included in each customer order?
=========================================================*/
SELECT order_id, SUM(quantity) AS total_items
FROM Order_Items
GROUP BY order_id;

-- Part B: Subqueries - Nested & Correlated
/*=========================================================
Business Question 7
Which customers spend more than the average customer?
=========================================================*/
SELECT name FROM Customers WHERE customer_id IN (
    SELECT customer_id FROM Orders o
    JOIN Order_Items oi ON o.order_id = oi.order_id
    GROUP BY customer_id
    HAVING SUM(quantity * price_each) > (
        SELECT AVG(customer_total) FROM (
            SELECT SUM(quantity * price_each) AS customer_total 
            FROM Order_Items oi JOIN Orders o ON oi.order_id = o.order_id 
            GROUP BY customer_id
        ) AS avg_table
    )
);

/*=========================================================
Business Question 8
Which products are priced above their category average?
=========================================================*/
SELECT product_name, category, price
FROM Products p1
WHERE price > (
    SELECT AVG(price) 
    FROM Products p2 
    WHERE p1.category = p2.category
);

/*=========================================================
Business Question 9
Which customers placed orders worth more than ₹50,000?
=========================================================*/
SELECT DISTINCT c.name
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
WHERE o.order_id IN (
    SELECT order_id 
    FROM Order_Items 
    GROUP BY order_id 
    HAVING SUM(quantity * price_each) > 50000
);

/*=========================================================
Business Question 10
Which customers placed more orders than the average customer?
=========================================================*/
SELECT name FROM Customers WHERE customer_id IN (
    SELECT customer_id FROM Orders 
    GROUP BY customer_id 
    HAVING COUNT(order_id) > (
        SELECT AVG(order_count) FROM (
            SELECT COUNT(order_id) AS order_count FROM Orders GROUP BY customer_id
        ) AS avg_orders
    )
);

/*=========================================================
Business Question 11
Which product is the most expensive in the catalog?
=========================================================*/
SELECT product_name, price 
FROM Products 
WHERE price = (SELECT MAX(price) FROM Products);

-- Part C: Window Functions
/*=========================================================
Business Question 12
How do customers rank based on their total spending?
=========================================================*/
SELECT name, 
       SUM(oi.quantity * oi.price_each) AS total_spending,
       RANK() OVER (ORDER BY SUM(oi.quantity * oi.price_each) DESC) AS spending_rank
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN Order_Items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.name;

/*=========================================================
Business Question 13
What is the cumulative sales trend over time?
=========================================================*/
SELECT order_date, 
       SUM(daily_sales) OVER (ORDER BY order_date) AS cumulative_sales
FROM (
    SELECT o.order_date, SUM(oi.quantity * oi.price_each) AS daily_sales
    FROM Orders o
    JOIN Order_Items oi ON o.order_id = oi.order_id
    GROUP BY o.order_date
) AS daily_totals;

/*=========================================================
Business Question 14
What percentage of total orders does each customer contribute?
=========================================================*/
SELECT name, 
       COUNT(order_id) AS order_count,
       (COUNT(order_id) * 100.0 / SUM(COUNT(order_id)) OVER()) AS percentage_contribution
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name;

/*=========================================================
Business Question 15
What is the most recent order placed by each customer?
=========================================================*/
SELECT name, order_date, order_id
FROM (
    SELECT c.name, o.order_date, o.order_id,
           ROW_NUMBER() OVER(PARTITION BY c.customer_id ORDER BY o.order_date DESC) as rn
    FROM Customers c
    JOIN Orders o ON c.customer_id = o.customer_id
) t
WHERE rn = 1;

/*=========================================================
Business Question 16
How do products rank within each category based on sales quantity?
=========================================================*/
SELECT category, product_name, total_qty,
       DENSE_RANK() OVER(PARTITION BY category ORDER BY total_qty DESC) as sales_rank
FROM (
    SELECT p.category, p.product_name, SUM(oi.quantity) as total_qty
    FROM Products p
    JOIN Order_Items oi ON p.product_id = oi.product_id
    GROUP BY p.category, p.product_name
) t;

-- Part D: CTE & Case
/*=========================================================
Business Question 17
How can products be classified into price segments?
=========================================================*/
SELECT product_name, price,
CASE 
    WHEN price > 50000 THEN 'High'
    WHEN price BETWEEN 10000 AND 50000 THEN 'Medium'
    ELSE 'Low'
END AS price_category
FROM Products;

/*=========================================================
Business Question 18
Who are the top 3 customers based on total spending?
=========================================================*/
WITH CustomerSpending AS (
    SELECT c.name, SUM(oi.quantity * oi.price_each) as total_spent
    FROM Customers c
    JOIN Orders o ON c.customer_id = o.customer_id
    JOIN Order_Items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_id, c.name
)
SELECT * FROM CustomerSpending 
ORDER BY total_spent DESC 
LIMIT 3;

/*=========================================================
Business Question 19
How can customers be classified into loyalty tiers based on purchase frequency?
=========================================================*/
WITH CustomerOrders AS (
    SELECT customer_id, COUNT(order_id) as order_count
    FROM Orders
    GROUP BY customer_id
)
SELECT c.name, co.order_count,
CASE 
    WHEN order_count >= 5 THEN 'Platinum'
    WHEN order_count BETWEEN 3 AND 4 THEN 'Gold'
    ELSE 'Silver'
END AS loyalty_status
FROM Customers c
JOIN CustomerOrders co ON c.customer_id = co.customer_id;

/*=========================================================
Business Question 20
What is the month-over-month revenue growth percentage?
=========================================================*/
WITH MonthlyRev AS (
    SELECT DATE_FORMAT(order_date, '%Y-%m') AS month, 
           SUM(oi.quantity * oi.price_each) AS revenue
    FROM Orders o
    JOIN Order_Items oi ON o.order_id = oi.order_id
    GROUP BY month
)
SELECT month, revenue,
       LAG(revenue) OVER (ORDER BY month) AS prev_month_rev,
       ((revenue - LAG(revenue) OVER (ORDER BY month)) / LAG(revenue) OVER (ORDER BY month) * 100) AS growth_pct
FROM MonthlyRev;

/*=========================================================
Business Question 21
Who are the top 2 highest-spending customers in each city?
=========================================================*/
WITH CitySpending AS (
    SELECT c.city, c.name, SUM(oi.quantity * oi.price_each) as total_spent,
           ROW_NUMBER() OVER(PARTITION BY c.city ORDER BY SUM(oi.quantity * oi.price_each) DESC) as city_rank
    FROM Customers c
    JOIN Orders o ON c.customer_id = o.customer_id
    JOIN Order_Items oi ON o.order_id = oi.order_id
    GROUP BY c.city, c.name
)
SELECT city, name, total_spent 
FROM CitySpending 
WHERE city_rank <= 2;

-- Part E: Miscellaneous Advanced Joins & Aggregations
/*=========================================================
Business Question 22
Which cities generated the highest sales revenue and which shipping partner handled them?
=========================================================*/
SELECT c.city, s.shipper_name, SUM(oi.quantity * oi.price_each) AS total_revenue
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN Order_Items oi ON o.order_id = oi.order_id
JOIN Shippers s ON o.shipper_id = s.shipper_id
GROUP BY c.city, s.shipper_name
ORDER BY total_revenue DESC
LIMIT 3;

/*=========================================================
Business Question 23
Generate a complete order summary including customer, product, supplier, and shipper details.
=========================================================*/
SELECT o.order_id, c.name AS customer_name, p.product_name, sup.supplier_name, sh.shipper_name
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
JOIN Order_Items oi ON o.order_id = oi.order_id
JOIN Products p ON oi.product_id = p.product_id
JOIN Suppliers sup ON p.supplier_id = sup.supplier_id
JOIN Shippers sh ON o.shipper_id = sh.shipper_id;

/*=========================================================
Business Question 24
How does each supplier perform in terms of total sales and average order value?
=========================================================*/
SELECT s.supplier_name, 
       SUM(oi.quantity * oi.price_each) AS total_sales,
       AVG(oi.quantity * oi.price_each) AS avg_order_value
FROM Suppliers s
JOIN Products p ON s.supplier_id = p.supplier_id
JOIN Order_Items oi ON p.product_id = oi.product_id
GROUP BY s.supplier_id, s.supplier_name;

/*=========================================================
Business Question 25
Which product categories contribute more than 30% of total sales revenue?
=========================================================*/
SELECT category, SUM(oi.quantity * oi.price_each) as category_revenue
FROM Products p
JOIN Order_Items oi ON p.product_id = oi.product_id
GROUP BY category
HAVING category_revenue > (SELECT SUM(quantity * price_each) * 0.30 FROM Order_Items);

/*=========================================================
SECTION 5 : EXECUTIVE BUSINESS KPI DASHBOARD
=========================================================*/

-- KPI 1 : Total Business Revenue
SELECT
ROUND(SUM(quantity * price_each),2) AS Total_Revenue
FROM Order_Items;

-- KPI 2 : Total Orders Processed
SELECT
COUNT(order_id) AS Total_Orders
FROM Orders;

-- KPI 3 : Total Customers
SELECT
COUNT(customer_id) AS Total_Customers
FROM Customers;

-- KPI 4 : Average Order Value (AOV)
SELECT
ROUND(AVG(order_total),2) AS Average_Order_Value
FROM
(
SELECT
order_id,
SUM(quantity*price_each) AS order_total
FROM Order_Items
GROUP BY order_id
)t;

-- KPI 5 : Total Units Sold
SELECT
SUM(quantity) AS Total_Units_Sold
FROM Order_Items;

-- KPI 6 : Average Product Price
SELECT
ROUND(AVG(price),2) AS Average_Product_Price
FROM Products;

-- KPI 7 : Average Revenue Per Customer
SELECT
ROUND(SUM(quantity*price_each)/
COUNT(DISTINCT customer_id),2)
AS Avg_Revenue_Per_Customer
FROM Orders o
JOIN Order_Items oi
ON o.order_id=oi.order_id;

-- KPI 8 : Best Selling Product
SELECT
p.product_name,
SUM(oi.quantity) AS Units_Sold
FROM Products p
JOIN Order_Items oi
ON p.product_id=oi.product_id
GROUP BY p.product_name
ORDER BY Units_Sold DESC
LIMIT 1;

-- KPI 9 : Highest Revenue Category
SELECT
category,
SUM(quantity*price_each) AS Revenue
FROM Products p
JOIN Order_Items oi
ON p.product_id=oi.product_id
GROUP BY category
ORDER BY Revenue DESC
LIMIT 1;

-- KPI 10 : Average Orders Per Customer
SELECT
ROUND(AVG(Order_Count),2)
FROM
(
SELECT
customer_id,
COUNT(order_id) AS Order_Count
FROM Orders
GROUP BY customer_id
)x;

SELECT COUNT(*) FROM Customers;
SELECT COUNT(*) FROM Orders;
SELECT COUNT(*) FROM Products;
SELECT COUNT(*) FROM Suppliers;
SELECT COUNT(*) FROM Shippers;
SELECT COUNT(*) FROM Payment_Methods;
SELECT COUNT(*) FROM Orders;
SELECT COUNT(*) FROM Order_Items;