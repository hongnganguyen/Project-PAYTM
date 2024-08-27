Project Overview:

The PayTM Analysis project involves managing the data of a payment application. The database consists of four main tables: payment_history_18, paying_method, product, and table_message. Below are the details of each table's components:

1.payment_history_18:
- order_id: Unique identifier for each order
- customer_id: Unique identifier for each customer
- product_id: Unique identifier for each product
- promotion_id: Unique identifier for the promotion (promotion_id = 0 indicates no promotion, while promotion_id ≠ 0 indicates a promotion)
- bank_id: Unique identifier for each bank
- platform_id: Unique identifier for each payment method
- app_version: Version of each application
- message_id: Unique identifier for each payment notification
- discount_price: Discounted amount when a promotion code is applied
- final_price: Price after discount
- transaction_date: Transaction date
2. paying_method:
- method_id: Unique identifier for each payment method
- name: Name of each payment method
3. product:
- product_number: Unique identifier for each product
- sub_category: Subcategory of each product
- category: Product category
- product_group: Product group
- online_offline: Payment type
4. table_message:
- message_id: Unique identifier for each payment notification
- description: Notification for each order

Data Management of the PayTM payment app:
- Customer behavior analysis: Identify the most frequently purchased products on the app.
- Promotion program analysis: Provide an overview of transactions with successful discount codes. Measure the effectiveness of promotion programs.
- Cohort analysis: Define the customer dataset for the best-selling product in 2018.
- RFM analysis: By dividing each group for self-study, we conducted analysis and divided customers into segments.

Conclusion:
Based on the data management project of the PayTM payment app, we analyzed the most frequently purchased products on the app and could propose several promotion programs. Additionally, we measured the effectiveness of promotion programs, specifically by measuring the number of customers who returned to make a second purchase after the initial transaction with a promotion. The number of returning customers exceeded 50% of the total app users. This highlights the importance of attracting customers through promotion programs. Furthermore, cohort and RFM analysis can be conducted to identify the customer dataset for a product over 12 months. This allows us to make observations and insights about the customer segment for that product.
