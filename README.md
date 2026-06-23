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

-

### Analyze Index Performance

1. Now, try searching the record using `email` and notice the time it takes.

2. Search the same record again but this time, use `id` to find it, and again notice the time. Also, see the difference in time.
