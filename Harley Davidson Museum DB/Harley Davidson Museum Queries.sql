-- 1. Basic SQL Queries:

-- Retrieve all customers from France:
SELECT * FROM customers WHERE country = 'France';

-- Find the total number of orders placed in 2003:
SELECT COUNT(*) FROM orders WHERE YEAR(orderDate) = 2003;

-- List all products in the "Classic Cars" product line:
SELECT * FROM products WHERE productLine = 'Classic Cars';

-- 2. Joins:

-- Retrieve customer information along with their corresponding sales representative:
SELECT c.customerName, e.firstName, e.lastName 
FROM customers c
LEFT JOIN employees e 
ON c.salesRepEmployeeNumber = e.employeeNumber;

-- 3. Subqueries:

-- Find the order number and total amount for the order with the highest total amount:
SELECT orderNumber, SUM(quantityOrdered * priceEach) as total_amount
FROM orderdetails
GROUP BY orderNumber
HAVING total_amount = (
    SELECT MAX(total_amount)
    FROM (
        SELECT orderNumber, SUM(quantityOrdered * priceEach) as total_amount
        FROM orderdetails
        GROUP BY orderNumber
    ) as subquery
);

-- 4. Common Table Expressions (CTEs):

-- Find the top 3 customers with the highest total order value:
WITH CustomerTotalOrders AS (
    SELECT c.customerNumber, c.customerName, 
           SUM(od.quantityOrdered * od.priceEach) as total_order_value
    FROM customers c
    JOIN orders o ON c.customerNumber = o.customerNumber
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    GROUP BY c.customerNumber, c.customerName
)
SELECT customerNumber, customerName, total_order_value
FROM CustomerTotalOrders
ORDER BY total_order_value DESC
LIMIT 3;

-- 5. Window Functions:

-- Calculate the rank of customers based on their total order value:
SELECT customerNumber, customerName, 
       SUM(od.quantityOrdered * od.priceEach) as total_order_value,
       RANK() OVER (ORDER BY SUM(od.quantityOrdered * od.priceEach) DESC) as customer_rank
FROM customers c
JOIN orders o ON c.customerNumber = o.customerNumber
JOIN orderdetails od ON o.orderNumber = od.orderNumber
GROUP BY c.customerNumber, c.customerName;

-- 6. Case Statements:

-- Classify customers based on their credit limit:
SELECT customerNumber, customerName, 
       CASE 
           WHEN creditLimit > 100000 THEN 'High Credit Limit'
           WHEN creditLimit > 50000 THEN 'Medium Credit Limit'
           ELSE 'Low Credit Limit'
       END as credit_limit_category
FROM customers;

-- 7. Stored Procedures:

-- Create a stored procedure to get the total revenue for a given year:
DELIMITER $$ 
CREATE PROCEDURE GetTotalRevenueForYear(IN input_year INT) 
BEGIN 
    SELECT SUM(od.quantityOrdered * od.priceEach) as total_revenue 
    FROM orders o 
    JOIN orderdetails od 
    ON o.orderNumber = od.orderNumber 
    WHERE YEAR(o.orderDate) = input_year; 
END $$ 
DELIMITER ;

-- 8. Views:

-- Create a view to display customer information and their total order value:
CREATE VIEW CustomerTotalOrdersView AS 
SELECT c.customerNumber, c.customerName, 
       SUM(od.quantityOrdered * od.priceEach) as total_order_value 
FROM customers c 
JOIN orders o ON c.customerNumber = o.customerNumber 
JOIN orderdetails od ON o.orderNumber = od.orderNumber 
GROUP BY c.customerNumber, c.customerName;

-- 9. Indexes:

-- Create an index on the customerNumber column in the orders table to improve query performance:
CREATE INDEX idx_customerNumber ON orders (customerNumber);

-- 10. Transactions:

-- Update the quantity in stock and the order details in a single transaction to ensure data consistency:
START TRANSACTION;

    UPDATE products 
    SET quantityInStock = quantityInStock - 10 
    WHERE productCode = 'S10_1678'; 

    INSERT INTO orderdetails 
    (orderNumber, productCode, quantityOrdered, priceEach, orderLineNumber) 
    VALUES (10426, 'S10_1678', 10, 48.81, 1); 

COMMIT;

-- 11. Advanced Joins:

-- 11.1 Self-Join: Find all employees who report to another employee:
SELECT e1.employeeNumber, e1.lastName, e1.firstName, e2.lastName AS managerLastName, e2.firstName AS managerFirstName
FROM employees e1
JOIN employees e2 ON e1.reportsTo = e2.employeeNumber;

-- 11.2 Multiple Joins: Find the total revenue generated by each sales representative:
SELECT e.employeeNumber, e.firstName, e.lastName, SUM(od.quantityOrdered * od.priceEach) AS total_revenue
FROM employees e
JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
JOIN orders o ON c.customerNumber = o.customerNumber
JOIN orderdetails od ON o.orderNumber = od.orderNumber
GROUP BY e.employeeNumber, e.firstName, e.lastName;

-- 12. Advanced Subqueries:

-- 12.1 Find customers who have placed more orders than the average number of orders per customer:
SELECT c.customerNumber, c.customerName
FROM customers c
WHERE (SELECT COUNT(*) FROM orders WHERE customerNumber = c.customerNumber) > 
      (SELECT AVG(order_count) FROM (SELECT customerNumber, COUNT(*) AS order_count 
                                     FROM orders 
                                     GROUP BY customerNumber) AS avg_orders);

-- 12.2 Find products that have never been ordered:
SELECT p.productCode, p.productName
FROM products p
WHERE NOT EXISTS (
    SELECT 1 
    FROM orderdetails od 
    WHERE od.productCode = p.productCode
);

-- 13. Advanced Window Functions:

/* The RANK() window function is used in a subquery (as the subquery can handle the window function).
Inside the subquery, we aggregate the order value by customer and year using SUM(quantityOrdered * priceEach) and apply RANK() to rank the customers based on their order value in descending order.
The outer query then filters only the top 5 customers using WHERE rank <= 5.*/

-- 13.1 Calculate the moving average of daily order totals for the past 7 days:
SELECT orderDate, SUM(quantityOrdered * priceEach) AS daily_total_sales,
       AVG(SUM(quantityOrdered * priceEach)) OVER (ORDER BY orderDate ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_sales
FROM orders o
JOIN orderdetails od ON o.orderNumber = od.orderNumber
GROUP BY orderDate;




