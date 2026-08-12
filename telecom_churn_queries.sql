-- ============================================================
-- TELECOM CUSTOMER CHURN & REVENUE INTELLIGENCE
-- SQL Analysis Queries
-- Database: telecom_churn_analysis
-- Table: telecom_customers (6,589 rows, Churned + Stayed only)
-- ============================================================


-- Query 1: Overall Churn Rate and Revenue at Risk
-- Business Question: What is our headline churn problem in numbers?
SELECT
    COUNT(*) AS Total_Customers,
    SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) AS Churned_Customers,
    ROUND(SUM(CASE WHEN Customer_Status = 'Churned' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS Churn_Rate_Percent,
    ROUND(SUM(Annual_Revenue_at_Risk), 2) AS Total_Revenue_at_Risk
FROM telecom_customers;
-- Insight: 28.4% churn, ~$1.65M lost annually.


-- Query 2: Churn Rate and Revenue Lost by Contract Type
-- Business Question: Which contract type costs us most?
SELECT
    Contract,
    COUNT(*) AS Total_Customers,
    SUM(Churn_Flag) AS Churned_Customers,
    ROUND(AVG(Churn_Flag) * 100, 1) AS Churn_Rate_Percent,
    ROUND(SUM(Annual_Revenue_at_Risk), 2) AS Revenue_at_Risk
FROM telecom_customers
GROUP BY Contract
ORDER BY Churn_Rate_Percent DESC;
-- Insight: M2M churns at 51.7% vs 2.6% for Two Year - 20x gap. Biggest lever in the whole dataset.


-- Query 3: Root Cause Analysis - Revenue Lost by Churn Category
-- Business Question: How much revenue does each churn reason category cost us?
SELECT
    Churn_Category,
    COUNT(*) AS Customers_Lost,
    ROUND(SUM(Annual_Revenue_at_Risk), 2) AS Revenue_Lost
FROM telecom_customers
WHERE Churn_Flag = 1
GROUP BY Churn_Category
ORDER BY Revenue_Lost DESC;
-- Insight: 46.5% of lost revenue is competitor-driven, not our fault. Market problem, not a service problem.


-- Query 4: Top 10 Specific Churn Reasons by Customer Count and Revenue Impact
-- Business Question: Which exact reasons should we fix first?
SELECT
    Churn_Reason,
    COUNT(*) AS Customers_Lost,
    ROUND(SUM(Annual_Revenue_at_Risk), 2) AS Revenue_Lost
FROM telecom_customers
WHERE Churn_Flag = 1
GROUP BY Churn_Reason
ORDER BY Customers_Lost DESC
LIMIT 10;
-- Insight: Top 2 reasons are competitor-related, can't fix those. #3 is support attitude (220 people) - fully fixable, easy priority.


-- Query 5: Fixable vs Competitive Churn Split
-- Business Question: How much of our churn can we actually control?
SELECT
    Churn_Type,
    COUNT(*) AS Customers_Lost,
    ROUND(SUM(Annual_Revenue_at_Risk), 2) AS Revenue_Lost,
    ROUND(
        SUM(Annual_Revenue_at_Risk)
        / (SELECT SUM(Annual_Revenue_at_Risk) FROM telecom_customers WHERE Churn_Flag = 1) * 100, 1
    ) AS Percent_of_Total_Revenue_Lost
FROM telecom_customers
WHERE Churn_Flag = 1
GROUP BY Churn_Type
ORDER BY Revenue_Lost DESC;
-- Insight: 53.5% of lost revenue was avoidable (price, attitude, dissatisfaction). Over half the fire is one we could've put out ourselves.


-- Query 6: Internet Type Churn Rate and Revenue Analysis
-- Business Question: Which internet product needs urgent attention?
SELECT
    Internet_Type,
    COUNT(*) AS Total_Customers,
    ROUND(AVG(Churn_Flag) * 100, 1) AS Churn_Rate_Percent,
    ROUND(SUM(Annual_Revenue_at_Risk), 2) AS Revenue_at_Risk
FROM telecom_customers
WHERE Internet_Type != 'No Internet Service'
GROUP BY Internet_Type
ORDER BY Churn_Rate_Percent DESC;
-- Insight: Fiber churns at 42.1%, double DSL. Premium product, worst retention - either overpriced or underdelivering on speed.


-- Query 7: Tenure Bucket Churn Analysis
-- Business Question: When do we lose most customers?
SELECT
    Tenure_Bucket,
    COUNT(*) AS Total_Customers,
    ROUND(AVG(Churn_Flag) * 100, 1) AS Churn_Rate_Percent
FROM telecom_customers
GROUP BY Tenure_Bucket
ORDER BY Churn_Rate_Percent DESC;
-- Insight: First-year churn is 59.9%, drops to 9.5% past year 4. Onboarding is the danger zone.


-- Query 8: Offer Performance Ranking
-- Business Question: Which offers work and which hurt us?
SELECT
    Offer,
    COUNT(*) AS Total_Customers,
    ROUND(AVG(Churn_Flag) * 100, 1) AS Churn_Rate_Percent,
    RANK() OVER (ORDER BY AVG(Churn_Flag) ASC) AS Performance_Rank
FROM telecom_customers
GROUP BY Offer
ORDER BY Churn_Rate_Percent ASC;
-- Insight: Offer E churns at 67.6%, worse than no offer at all (29.2%). Kill it. Offer A works great at 6.7% - replicate it instead.


-- Query 9: High Value Churned Customers - Win-Back Targets
-- Business Question: Which lost customers hurt us most financially?
SELECT
    Customer_ID,
    Monthly_Charge,
    Tenure_in_Months,
    Contract,
    Internet_Type,
    Churn_Category,
    Churn_Reason
FROM telecom_customers
WHERE Churn_Flag = 1
ORDER BY Monthly_Charge DESC
LIMIT 20;
-- Insight: Top 20 are almost all Fiber customers paying $111+/month. Same Fiber problem from Query 6, showing up again in the highest-value losses.


-- Query 10: City-Level Churn Concentration
-- Business Question: Which geographies need immediate attention?
SELECT
    City,
    COUNT(*) AS Total_Customers,
    SUM(Churn_Flag) AS Churned_Customers,
    ROUND(AVG(Churn_Flag) * 100, 1) AS Churn_Rate_Percent
FROM telecom_customers
GROUP BY City
HAVING COUNT(*) > 10
ORDER BY Churn_Rate_Percent DESC
LIMIT 15;
-- Insight: San Diego, Fallbrook, Temecula all churn at 60%+, more than double the average. All Southern California - likely a regional competitor issue.