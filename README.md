# Recruitment task for Morizon

Application for creating random users based on publicly available data.
Allows to browse, search and manage imported users.

## Development

### Quick Start (Development)
```bash
# Copy .env for symfony
cp .env.dev symfony-app/.env

# Run the application in development mode
docker-compose up -d

# The application will be available at:
# Phoenix API: http://localhost:4000
# Symfony App: http://localhost:8000
```

### Environment Configuration

Uses `.env.dev` i `docker-compose.yml` (default)
  - Hot reload enabled
  - Debug logging
  - Development database
  - Automatic migrations

### Import

The phoenix-api import URL is secured by api key, defined in `phoenix-api/config/dev.exs`
The key is by default: `dev-api-token-12345`
It may be overriden by setting `API_TOKEN` in `.env.dev`

To trigger the import you can use `curl` like below:
```bash
curl --request POST \
  --url http://localhost:4000/import \
  --header 'authorization: Bearer dev-api-token-12345'
```

The gov API ULRs are defined in `phoenix-api/config/config.exs`:
- `https://api.dane.gov.pl/media/resources/20250124/8_-_Wykaz_imion_m%C4%99skich_os%C3%B3b_%C5%BCyj%C4%85cych_wg_pola_imi%C4%99_pierwsze_wyst%C4%99puj%C4%85cych_w_rejestrze_PESEL_bez_zgon%C3%B3w.csv`
- `https://api.dane.gov.pl/media/resources/20250123/nazwiska_m%C4%99skie-osoby_%C5%BCyj%C4%85ce.csv`
- `https://api.dane.gov.pl/media/resources/20250124/8_-_Wykaz_imion_%C5%BCe%C5%84skich__os%C3%B3b_%C5%BCyj%C4%85cych_wg_pola_imi%C4%99_pierwsze_wyst%C4%99puj%C4%85cych_w_rejestrze_PESEL_bez_zgon%C3%B3w.csv`
- `https://api.dane.gov.pl/media/resources/20250123/nazwiska_%C5%BCe%C5%84skie-osoby_%C5%BCyj%C4%85ce_efby1gw.csv`

## Test

### Quick Start (Testing)
```bash
# 1. Start up test database on port 5433
docker-compose -f docker-compose.test.yml up -d
# You may adjust `phoenix-api/config/test.exs` instead to use an existing db

# 2. Run phoenix tests
cd phoenix-api
mix test

# 3. Some of the tests are disabled by default. They may require external internet connection or have risk of being false negative.
# They shouldn't be used in CI, but you may run it manually using:
mix test.all

# 4. Run Syfony tests
cd ../symfony-app
# If you haven't run the dev environment before, you have to create `.env` and install dependencies:
cp ../.env.test .env
composer install 
# run tests
bin/phpunit
```

### Test Environment Configuration

Uses `.env.test` and `docker-compose.test.yml`
  - PostgreSQL database only
  - Isolated test environment
  - Fast startup and shutdown

## TODO
Things, that could/should be done in the future
- [ ] fetch gov api data in paralel
- [ ] retry failed gov api calls
- [ ] create production configuration with applications in prod mode, elixir release, etc
