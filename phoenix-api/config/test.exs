import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :phoenix_api, PhoenixApi.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "phoenix_api_test#{System.get_env("MIX_TEST_PARTITION")}",
  port: 5433,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :phoenix_api, PhoenixApiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "mrSRdsg0ttb42LiHg3ceCnvGMw0JVKkVVi20kFmRdGx18wYslGyfms52m5m+bw4L",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# API Token for testing
config :phoenix_api, :api_token, "test-api-token-12345"
