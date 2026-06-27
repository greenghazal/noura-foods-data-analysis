-- Database Setup
CREATE DATABASE noura_foods;
use noura_foods;

-- Scenario 1: Business Overview
SELECT COUNT(DISTINCT OrderID) AS Total_Orders,
       SUM(Quantity) AS Total_Items_Sold,
       SUM(LineTotal) AS Total_Revenue FROM fact_sales;

-- Scenario 2: Top Sellers
select dim_products.ProductName,
sum(fact_sales.Quantity) AS Total_Quantity_Sold from fact_sales
    join dim_products on fact_sales.ProductID=dim_products.ProductID
group by ProductName order by Total_Quantity_Sold
    desc limit 5;

-- Scenario 3: Marketing Channels
SELECT
    COALESCE(c.CampaignName, 'Organic / No Campaign') AS Campaign_Type,
    COUNT(DISTINCT f.OrderID) AS Total_Orders,
    SUM(f.LineTotal) AS Total_Revenue
FROM fact_sales f
LEFT JOIN dim_campaigns c ON f.CampaignID = c.CampaignID
GROUP BY Campaign_Type
ORDER BY Total_Revenue DESC;

-- Scenario 4: MoM Growth
WITH MonthlySales AS (SELECT DATE_FORMAT(OrderDate, '%Y-%m') AS SalesMonth,SUM(LineTotal) AS TotalRevenue
    FROM fact_sales GROUP BY DATE_FORMAT(OrderDate, '%Y-%m'))
SELECT SalesMonth,TotalRevenue,LAG(TotalRevenue) OVER(ORDER BY SalesMonth) AS PreviousMonthRevenue,
    TotalRevenue - LAG(TotalRevenue) OVER(ORDER BY SalesMonth) AS Revenue_Difference
FROM MonthlySales;

-- Scenario 5: Sales by Day of Week
select dayname(fact_sales.OrderDate) as Day_of_week,
       count(distinct fact_sales.OrderID) as Total_orders,
       sum(fact_sales.LineTotal) as Total_Revenue from fact_sales group by dayname(fact_sales.OrderDate)
order by Total_Revenue desc ;

-- Scenario 6: Age Demographics
select case when dim_customers.Age < 18 then '0. Under 18 (Teens)'
            when dim_customers.Age between 18 and 25 then '1. 18-25 (Young)'
            when dim_customers.Age between 26 and 40 then '2. 26-40 (Adult)'
            when dim_customers.Age between 41 and 55 then '3. 41-55 (Middle-Aged)'
            else '4. 55+ (Senior)'
        end as age_group,
        count(distinct fact_sales.CustomerID) as 'Total_Customers',sum(fact_sales.LineTotal) as Total_Revenue
from fact_sales join dim_customers on fact_sales.CustomerID=dim_customers.CustomerID
group by age_group order by age_group;

-- Scenario 7: Customer Loyalty
WITH customerordercount as
    (select fact_sales.CustomerID,count(distinct fact_sales.OrderID)as total_orders
     from fact_sales group by CustomerID)
select case when Total_Orders = 1 then '1. One-time Buyer'
        when Total_Orders = 2 then '2. Two-time Buyer'
        else '3. Loyal Customer (3+ Orders)' end as segment_loyalty,
    count(CustomerID) as Total_Customers from customerordercount
group by segment_loyalty order by segment_loyalty;

-- Scenario 8: Average Order Value (AOV)
select coalesce(dim_campaigns.CampaignName,'Organic / No Campaign') as Campaign_Name,
       count(distinct fact_sales.OrderID) as total_orders,
       sum(fact_sales.LineTotal)/count(distinct fact_sales.OrderID) as Average_Order_Value
from fact_sales
    left join dim_campaigns on fact_sales.CampaignID = dim_campaigns.CampaignID
group by CampaignName order by Average_Order_Value desc ;

-- Scenario 9: VIP Customers
select dim_customers.CustomerID,count(distinct OrderID)as total_orders,
       sum(fact_sales.LineTotal)as total_spent from fact_sales
join dim_customers on fact_sales.CustomerID=dim_customers.CustomerID
group by fact_sales.CustomerID order by total_spent desc limit 10;

-- Scenario 10: Seasonality
select monthname(fact_sales.OrderDate) as month_of_year,
       count(distinct fact_sales.OrderID) as Total_orders,
       sum(fact_sales.LineTotal) as Total_Revenue from fact_sales group by monthname(fact_sales.OrderDate)
order by Total_Revenue desc ;