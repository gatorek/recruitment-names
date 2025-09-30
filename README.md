# Recruitment task for Morizon

## Development

Run `docker compose up -d` to run the application locally.

## Test

If no local postgres is running - you may run `docker compose up -d db` before testing.
Otherwise you may need to adjust db params in `config/test.exs`.

Run `mix test` to test the application.

Run `mix test.all` to execute all tests, including those that are resource-intensive or require an external connection. Use with caution, as these tests may be flaky.