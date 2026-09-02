-- tests/conftest.py connects to catcoin_poe_test (derived from DATABASE_URL).
-- Runs only on first Postgres data volume init; see docker-compose notes if the DB is missing.

CREATE DATABASE catcoin_poe_test;
