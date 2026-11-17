#### Requirements

- You should be familiar with Docker

## How to use this repo

1. Start the Docker container using command:

`docker compose up -d`

an empty postgres instance will be up. Open Adminer using [http://localhost:8080](http://localhost:8080/)

- Select `PostgreSQL` from the system dropdown
- Server `db`
- Username, password and database name should be selected from the `docker-compose.yml` file.

2. There will be no tables initially, Select SQL command from the side-bar and then copy the the SQL from `schema.sql` included in this repo.

3. Next, we'll fill the database with some dummy data. Copy & paste the sql from the given sql scripts in this order:

- Categories: `5_categories.sql`
- Customers: `10_000_customers.sql`
- Products: `5_000_products.sql`
- Orders: `100_000_orders.sql`
- Order Items: `500_000_order_items.sql`
- Payments: `100_000_payments.sql`

4. Now, we'll add indexes to the tables. Copy & paste the `indexes.sql` to the SQL command and hit execute.

To see query plans, use `EXPLAIN (ANALYZE, BUFFERS)` in front of any query. For a worked set of before/after comparisons, see [performance_examples.md](performance_examples.md). `drop_indexes.sql` removes the indexes from `indexes.sql` so you can compare without reloading the data.

### Practice Queries

#### 1. Top Ten Customers by Revenue

```
SELECT
    c.id,
    c.first_name,
    c.last_name,
    SUM(p.amount) revenue
FROM customers c
JOIN orders o
    ON o.customer_id = c.id
JOIN payments p
    ON p.order_id = o.id
GROUP BY c.id
ORDER BY revenue DESC
LIMIT 10;
```

#### 2. Best Selling product

```
SELECT
    p.name,
    SUM(oi.quantity) total_sold
FROM products p
JOIN order_items oi
    ON oi.product_id = p.id
GROUP BY p.id
ORDER BY total_sold DESC
LIMIT 20;
```

#### 3. Monthly Revenue

```
SELECT
    DATE_TRUNC('month', payment_date) AS month,
    SUM(amount)
FROM payments
GROUP BY month
ORDER BY month;
```

#### 4. Cancelled Order Rate by Customer

```
SELECT
    c.id,
    c.first_name,
    COUNT(*) FILTER (WHERE o.status = 'cancelled') * 100.0 / COUNT(*) AS cancelled_pct
FROM customers c
JOIN orders o
    ON o.customer_id = c.id
GROUP BY c.id, c.first_name
ORDER BY cancelled_pct DESC, c.id
LIMIT 10;
```

#### 5. Orders Without Any Items

```
SELECT o.id, o.total_amount
FROM orders o
WHERE NOT EXISTS (
    SELECT 1
    FROM order_items oi
    WHERE oi.order_id = o.id
);
```
