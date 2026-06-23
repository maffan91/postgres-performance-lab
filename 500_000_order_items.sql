INSERT INTO order_items(
    order_id,
    product_id,
    quantity,
    unit_price
)
SELECT
    floor(random() * 100000 + 1)::bigint,
    floor(random() * 5000 + 1)::bigint,
    floor(random() * 5 + 1)::int,
    round((random() * 1000 + 50)::numeric,2)
FROM generate_series(1,500000);