DROP INDEX IF EXISTS idx_products_category_id;
DROP INDEX IF EXISTS idx_orders_customer_id;
DROP INDEX IF EXISTS idx_orders_order_date;
DROP INDEX IF EXISTS idx_order_items_order_id;
DROP INDEX IF EXISTS idx_order_items_product_id;
DROP INDEX IF EXISTS idx_payments_order_id;
DROP INDEX IF EXISTS idx_customers_email;

-- Experimental indexes created in the examples
DROP INDEX IF EXISTS idx_orders_customer_date;
DROP INDEX IF EXISTS idx_orders_cust_incl;
DROP INDEX IF EXISTS idx_products_name_pattern;
