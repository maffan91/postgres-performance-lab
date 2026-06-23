INSERT INTO products(
    category_id,
    name,
    sku,
    price,
    stock_quantity
)
SELECT
    floor(random() * 5 + 1)::int,
    'Product ' || gs,
    'SKU-' || gs,
    round((random() * 1000 + 50)::numeric, 2),
    floor(random() * 500)::int
FROM generate_series(1,5000) gs;