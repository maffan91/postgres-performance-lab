INSERT INTO orders(
    customer_id,
    order_date,
    status,
    total_amount
)
SELECT
    floor(random() * 10000 + 1)::bigint,
    NOW() - (random() * interval '365 days'),
    (
        ARRAY[
            'pending',
            'paid',
            'shipped',
            'delivered',
            'cancelled'
        ]
    )[floor(random()*5 + 1)],
    round((random() * 5000 + 100)::numeric,2)
FROM generate_series(1,100000);