CREATE INDEX idx_products_category_id
ON products(category_id);

CREATE INDEX idx_orders_customer_id
ON orders(customer_id);

CREATE INDEX idx_orders_order_date
ON orders(order_date);

CREATE INDEX idx_order_items_order_id
ON order_items(order_id);

CREATE INDEX idx_order_items_product_id
ON order_items(product_id);

CREATE INDEX idx_payments_order_id
ON payments(order_id);

CREATE INDEX idx_customers_email
ON customers(email);