INSERT INTO customers(
    first_name,
    last_name,
    email,
    city,
    country
)
SELECT
    'First_' || gs,
    'Last_' || gs,
    'user' || gs || '@example.com',
    'Karachi',
    'Pakistan'
FROM generate_series(1,10000) gs;