INSERT INTO payments(
    order_id,
    payment_method,
    amount,
    status
)
SELECT
    id,
    (
        ARRAY[
            'credit_card',
            'bank_transfer',
            'paypal'
        ]
    )[floor(random()*3 + 1)],
    total_amount,
    'completed'
FROM orders;