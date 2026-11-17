# Query Performance Examples

Each example shows a query, what `EXPLAIN` reports, and the change that helps. Run the queries in Adminer or with:

```bash
docker compose exec db psql -U postgres_user -d practice_db
```

Timings are from one local run and will vary by machine. Focus on the shape of the plan and the relative difference.

**Dates:** the seed data is generated relative to the day you load it (`NOW() - random() * 365 days`). The date ranges below use June 2026, which matches a load in late 2026. If your data is different, check the range first:

```sql
SELECT min(order_date), max(order_date) FROM orders;
```

Use `EXPLAIN (ANALYZE, BUFFERS)` for the examples. `ANALYZE` runs the query, so it reports real row counts and timings. `BUFFERS` shows how many 8 KB pages were read from cache or disk.

## How to read a plan

Run:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE customer_id = 42;
```

Check these, in order:

1. **Scan node type.** `Seq Scan` reads the whole table. `Index Scan`, `Bitmap Index Scan` + `Bitmap Heap Scan`, and `Index Only Scan` use an index.
2. **`rows=` estimate against `actual rows=`.** A large gap means the planner's statistics are wrong, and it may choose a bad plan. Running `ANALYZE` refreshes the statistics.
3. **`Rows Removed by Filter`.** A large number means the database read many rows only to throw them away. An index on the filter column can avoid that work.
4. **`Buffers: shared hit/read`.** Pages read from disk (`read`) are slower than pages found in cache (`hit`).

## 1. Missing index on a range filter

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders
WHERE order_date >= '2026-06-01' AND order_date < '2026-07-01';
```

Without `idx_orders_order_date` (run `DROP INDEX idx_orders_order_date;` first) the plan is a `Seq Scan` with `Rows Removed by Filter: 91663`, taking about **10 ms**.

With `indexes.sql` applied it becomes a `Bitmap Heap Scan` on `idx_orders_order_date`, taking about **3.5 ms**.

Re-create the index afterwards with `CREATE INDEX idx_orders_order_date ON orders(order_date);`, or re-apply `indexes.sql`.

## 2. Wrapping a column in a function (non-sargable)

```sql
-- Slow: the function hides order_date from the index
SELECT * FROM orders
WHERE DATE_TRUNC('month', order_date) = '2026-06-01';

-- Fast: a range on the bare column can use the index
SELECT * FROM orders
WHERE order_date >= '2026-06-01' AND order_date < '2026-07-01';
```

With `idx_orders_order_date` present, the first query is a `Seq Scan` taking about **15 ms**. The second uses the index and takes about **3.5 ms**. Write filters as ranges on the raw column, not as functions of it.

## 3. Composite index: small gain on this data

```sql
SELECT * FROM orders
WHERE customer_id = 42 AND order_date >= '2026-01-01';
```

With only `idx_orders_customer_id` the plan is a `Bitmap Index Scan` and takes about **0.07 ms**. Adding `CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);` gave about **0.20 ms**, which is no faster. Drop it before the next example with `DROP INDEX idx_orders_customer_date;`.

Each customer here has about 10 orders, so the existing index already narrows the result enough. A composite index helps more when the first column matches many rows and the second column filters or sorts them. Try it on a customer with more orders, or on a query that sorts by `order_date` within a customer.

## 4. Covering index (index-only scan)

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, status FROM orders
WHERE customer_id BETWEEN 100 AND 400;
```

With `idx_orders_customer_id` alone, the plan is a `Bitmap Heap Scan` and takes about **1.6 ms**.

After `CREATE INDEX idx_orders_cust_incl ON orders(customer_id) INCLUDE (status);` and `VACUUM ANALYZE orders;`, the plan is an `Index Only Scan` with `Heap Fetches: 0`, taking about **0.7 ms**. Drop it with `DROP INDEX idx_orders_cust_incl;` before re-running the baseline.

`INCLUDE` stores extra columns in the index, so the query can be answered from the index alone. Index-only scans need `VACUUM` to update the visibility map. Without it, `Heap Fetches` counts rows that still need a table lookup.

## 5. Partial index: check selectivity first

```sql
CREATE INDEX idx_orders_pending ON orders(id) WHERE status = 'pending';

EXPLAIN (ANALYZE)
SELECT id FROM orders WHERE status = 'pending';          -- ~20% of rows

EXPLAIN (ANALYZE)
SELECT id FROM orders WHERE status = 'pending' AND id < 100;
```

The first query uses the index as an `Index Only Scan` but takes about **12.7 ms**, slower than the **10.7 ms** `Seq Scan` without the index. Matching 20% of the table is too many rows for an index to help.

The second query takes about **0.16 ms**, because the extra `id` condition makes the result small.

Partial indexes help when the filter matches a small part of the table. Before creating one, check the share of rows it matches. Drop the index afterwards with `DROP INDEX idx_orders_pending;`.

## 6. `LIKE` patterns on `products.name`

```sql
SELECT * FROM products WHERE name LIKE 'Product 12%';   -- prefix
SELECT * FROM products WHERE name LIKE '%99%';          -- infix
```

With no index on `name`, both are `Seq Scan`s, taking about **1.4 ms**.

Adding a prefix-friendly index:

```sql
CREATE INDEX idx_products_name_pattern ON products(name text_pattern_ops);
```

The prefix query becomes a `Bitmap Index Scan` and takes about **0.10 ms**. The infix query still uses a `Seq Scan`, because a B-tree index can only search from the start of a value.

`text_pattern_ops` is needed for `LIKE` when the database isn't using the C locale. For infix or case-insensitive search, use the `pg_trgm` extension instead (not tested here). Drop the index with `DROP INDEX idx_products_name_pattern;` before re-running the baseline.

## 7. Deep `OFFSET` pagination vs keyset pagination

Pagination by offset:

```sql
SELECT * FROM orders ORDER BY order_date DESC LIMIT 20 OFFSET 90000;
```

Postgres reads and discards the first 90,000 rows. Without an index it sorts the whole table, taking about **52 ms**. With `idx_orders_order_date` it walks the index but still discards 90,000 rows, taking about **44 ms**.

Keyset pagination remembers the last row of the previous page:

```sql
SELECT * FROM orders
WHERE (order_date, id) < ('2026-03-01', 50000)
ORDER BY order_date DESC, id DESC
LIMIT 20;
```

This takes about **0.18 ms** no matter how deep the page is. The `id` tiebreaker keeps the order stable when two orders share a timestamp. To get the cursor values, take them from the last row of the previous page.

## 8. `IN` vs `EXISTS`

```sql
SELECT count(*) FROM orders o
WHERE o.id IN (SELECT order_id FROM payments WHERE payment_method = 'paypal');

SELECT count(*) FROM orders o
WHERE EXISTS (SELECT 1 FROM payments p
              WHERE p.order_id = o.id AND p.payment_method = 'paypal');
```

Both produce the same `Hash Semi Join` plan. Timings differed (68 ms and 39 ms), but the plans are identical and the gap was noise. The planner rewrites both forms, so write whichever is clearer.

## 9. Find out which indexes are used

```sql
SELECT relname, indexrelname, idx_scan
FROM pg_stat_user_indexes
WHERE relname = 'orders'
ORDER BY indexrelname;
```

`idx_scan` counts how many times each index was used since statistics were last reset. An index that stays at 0 under real load is a candidate for removal, but check the other queries first. `customers.email` has two indexes: `customers_email_key`, created by the `UNIQUE` constraint, and `idx_customers_email` from `indexes.sql`. The second one is redundant and can be dropped.

## Resetting between experiments

`drop_indexes.sql` removes the indexes from `indexes.sql` and the experimental indexes created in Sections 3, 4, and 6, so you can compare before and after without reseeding:

```bash
docker compose exec -T db psql -U postgres_user -d practice_db < drop_indexes.sql
docker compose exec -T db psql -U postgres_user -d practice_db < indexes.sql
```
