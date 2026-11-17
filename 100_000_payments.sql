INSERT INTO payments(
    order_id,
    payment_method,
    amount,
    payment_date,
    status
)
SELECT
    o.id,
    (
        ARRAY[
            'credit_card',
            'bank_transfer',
            'paypal'
        ]
    )[floor(random()*3 + 1)],
    o.total_amount,
    o.order_date + (random() * interval '2 days'),
    'completed'
FROM orders o;
