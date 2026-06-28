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

### Analyze Index Performance

It's time to analyze index performance and see how Postgres query planner works.
