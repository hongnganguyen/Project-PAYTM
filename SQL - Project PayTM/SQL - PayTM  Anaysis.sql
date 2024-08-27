---View data 
SELECT TOP 100 * 
FROM payment_history_18

SELECT * 
FROM paying_method 

SELECT * 
FROM product 

SELECT * 
FROM table_message 

-- 1.Analyze to see which product is bought the most
WITH join_table AS (
SELECT pay18.*, category, sub_category
FROM payment_history_18 as pay18 
JOIN product as pro  
ON pay18.product_id = pro.product_number 
JOIN table_message as mess 
ON pay18.message_id = mess.message_id) 
SELECT customer_id, category, sub_category 
       , COUNT(order_id) AS num_tran 
FROM join_table 
GROUP BY customer_id, category, sub_category 

----- Discussion: The results show that the Telco product is the most purchased by customers. There needs to be programs to pay attention to and impress with this product line
----2.Analyze the promotional programs applied to Telco products. 
--2.1. Overview of successful transactions with promotional conditions
WITH join_table AS (
SELECT pay18.*, category, sub_category
FROM payment_history_18 as pay18 
JOIN product as pro  
ON pay18.product_id = pro.product_number 
JOIN table_message as mess 
ON pay18.message_id = mess.message_id
WHERE [description] = 'success' AND category = 'Telco' ) 
, succ_table AS (
SELECT MONTH(transaction_date ) AS [Month],
       COUNT(order_id) AS num_tran_succ
FROM join_table 
WHERE promotion_id <> '0'
GROUP BY MONTH(transaction_date) 
) 
, total_table AS (
SELECT MONTH(transaction_date) AS [Month]
       ,COUNT(order_id) AS num_total 
FROM join_table 
GROUP BY MONTH(transaction_date) 
) 
SELECT succ_table.[Month]
       ,num_tran_succ
       ,num_total
       ,format( num_tran_succ*1.0/num_total,'p') AS pct 
FROM succ_table 
JOIN total_table 
ON succ_table.[Month] = total_table.[Month] 
--Discussion: The implemented promotional program showed a gradual increase in successful transaction percentage, peaking in August and November, but then declined.
----2.2. Measuring the effectiveness of the promotional program
WITH table_cus AS (
SELECT customer_id, order_id, promotion_id 
       ,IIF(promotion_id <> '0', 'promo', 'normal') AS tran_type 
       ,LAG(IIF(promotion_id <> '0', 'promo', 'normal'),1 ) OVER(PARTITION BY customer_id ORDER BY order_id) AS last_type 
       ,ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_id) AS row_number 
FROM payment_history_18 as pay18 
JOIN product as pro  
ON pay18.product_id = pro.product_number 
JOIN table_message as mess 
ON pay18.message_id = mess.message_id
WHERE [description] = 'success' AND category = 'Telco' 
) 
, table_first_promo AS (
SELECT distinct customer_id 
FROM table_cus 
WHERE row_number = 1 AND tran_type = 'promo' 
) 
SELECT COUNT(distinct table_first_promo.customer_id) AS number_cus
      ,(SELECT COUNT(distinct customer_id) FROM table_first_promo) AS total 
      ,COUNT(distinct table_first_promo.customer_id) * 1.0/ (SELECT COUNT(distinct customer_id) FROM table_first_promo) AS pct 
FROM table_first_promo 
JOIN table_cus 
ON table_first_promo.customer_id = table_cus.customer_id 
WHERE tran_type = 'normal' AND last_type = 'promo' 
--Discussion: Measuring the list of customers who purchased Telco products and made a second purchase after the initial purchase with a promotional program. 
--The results also show that the number of repeat purchases after the promotion is more than 50% of the total
----3. COHORT ANALYSIS: Identify the customer segment of the Telco product, how does this customer segment trend over 12 months of 2018 
WITH join_table AS (
SELECT customer_id 
      ,MIN(MONTH(transaction_date)) OVER (PARTITION BY customer_id) AS first_month 
      ,DATEDIFF( month,MIN(transaction_date) OVER (PARTITION BY customer_id),transaction_date ) AS subsequent_month 
FROM payment_history_18 as pay18 
JOIN product as pro  
ON pay18.product_id = pro.product_number 
JOIN table_message as mess 
ON pay18.message_id = mess.message_id
WHERE [description] = 'success' AND category = 'Telco' 
) 
, retained_table AS (
SELECT first_month
      ,subsequent_month
      ,COUNT(distinct customer_id) AS retained_user 
FROM join_table 
GROUP BY first_month, subsequent_month 
)
SELECT first_month
      ,subsequent_month
      ,retained_user 
      ,MAX(retained_user) OVER (PARTITION BY first_month) AS original_user 
      ,FORMAT( retained_user*1.0/MAX(retained_user) OVER (PARTITION BY first_month),'p') AS pct 
INTO #retention_table
FROM retained_table
ORDER BY first_month ASC 
---Create pivot 
SELECT first_month, original_user,"0", "1","2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12" 
FROM 
(SELECT first_month, subsequent_month ,original_user, pct 
 FROM #retention_table) AS source_table 
PIVOT(MIN(pct)
FOR subsequent_month IN ("0", "1","2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12")) 
AS pivot_logic 
ORDER BY first_month 
-----4. RFM Analysis  
WITH rfm_table AS (
SELECT customer_id
      ,DATEDIFF(day,MAX(transaction_date),'2018-12-31') AS recency 
      ,COUNT(order_id) AS frequency
      ,SUM(final_price*1.0) AS monetary
FROM (SELECT * FROM payment_history_17 UNION SELECT * FROM payment_history_18) year_table 
JOIN product as pro  
ON year_table.product_id = pro.product_number 
JOIN table_message as mess 
ON year_table.message_id = mess.message_id
WHERE [description] = 'success' AND category = 'Telco' 
GROUP BY customer_id 
)
,table_rank AS (
SELECT *
      ,PERCENT_RANK() OVER (ORDER BY recency ASC) AS r_rank 
      ,PERCENT_RANK() OVER (ORDER BY frequency ASC) AS f_rank
      ,PERCENT_RANK() OVER (ORDER BY monetary ASC) AS m_rank 
FROM rfm_table 
)
, table_tier AS (
SELECT *
      ,CASE WHEN r_rank > 0.75 THEN 4 
       WHEN r_rank > 0.5 THEN 3 
       WHEN r_rank > 0.25 THEN 2 
       ELSE 1 END r_tier 
      ,CASE WHEN f_rank > 0.75 THEN 4 
       WHEN f_rank> 0.5 THEN 3 
       WHEN f_rank > 0.25 THEN 2 
       ELSE 1 END f_tier 
      ,CASE WHEN m_rank  > 0.75 THEN 4 
       WHEN m_rank > 0.5 THEN 3 
       WHEN m_rank  > 0.25 THEN 2 
       ELSE 1 END m_tier  
FROM table_rank 
) 
, table_score AS (
SELECT *
      ,CONCAT(r_tier,f_tier,m_tier) AS rfm_score 
FROM table_tier
) 
,table_segment AS (
SELECT * 
       ,CASE WHEN rfm_score = 111 THEN 'Best Customers' 
       WHEN rfm_score LIKE '[3-4][3-4][1-4]' THEN 'Lost Bad Customers' 
       WHEN rfm_score LIKE '[3-4]2[1-4]' THEN 'Lost Customers' 
       WHEN rfm_score LIKE '21[1-4]' THEN 'Almost Lost'
       WHEN rfm_score LIKE '11[2-4]' THEN 'Loyal Customers' 
       WHEN rfm_score LIKE '[1-2][1-3]1' THEN 'Big Spenders'
       WHEN rfm_score LIKE '[1-2]4[1-4]' THEN 'New Customers' 
       WHEN rfm_score LIKE '[3-4]1[1-4]' THEN 'Hibernating'
       WHEN rfm_score LIKE '[1-2][2-3][2-4]' THEN 'Potential Loyalists' 
       ELSE 'unknown'
       END segment_label 
FROM table_score 
) 
SELECT segment_label
      ,COUNT(customer_id) AS number_cus 
FROM table_segment
GROUP BY segment_label
ORDER BY number_cus DESC 