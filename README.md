# Recruitment task for Morizon

## Development

Run `docker compose up -d` to run the application locally.

## Test

### Quick Start (Testing)
```bash
# 1. Start up test database
# Alternatively, adjust `phoenix-api/config/test.exs` to use existing db
docker-compose -f docker-compose.test.yml up -d

# 2. Run phoenix tests
cd phoenix-api
mix test

# 3. Some of the tests are disabled by default. They may require external internet connection or have risk of being false negative.
# They shouldn't be used in CI, but you may run it manually using:
mix test.all

# 4. Run Syfony tests
cd ../symfony-app
composer test
```

### Test Environment Configuration

- **Testing**: Uses `.env.test` and `docker-compose.test.yml`
  - PostgreSQL database only
  - Isolated test environment
  - Fast startup and shutdown
