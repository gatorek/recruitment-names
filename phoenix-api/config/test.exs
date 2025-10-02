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

# Person module URLs configuration for testing
config :phoenix_api, :person,
  male_first_name_url:
    System.get_env(
      "MALE_FIRST_NAME_URL",
      "https://api.dane.gov.pl/media/resources/20250124/8_-_Wykaz_imion_m%C4%99skich_os%C3%B3b_%C5%BCyj%C4%85cych_wg_pola_imi%C4%99_pierwsze_wyst%C4%99puj%C4%85cych_w_rejestrze_PESEL_bez_zgon%C3%B3w.csv"
    ),
  male_last_name_url:
    System.get_env(
      "MALE_LAST_NAME_URL",
      "https://api.dane.gov.pl/media/resources/20250123/nazwiska_m%C4%99skie-osoby_%C5%BCyj%C4%85ce.csv"
    ),
  female_first_name_url:
    System.get_env(
      "FEMALE_FIRST_NAME_URL",
      "https://api.dane.gov.pl/media/resources/20250124/8_-_Wykaz_imion_%C5%BCe%C5%84skich__os%C3%B3b_%C5%BCyj%C4%85cych_wg_pola_imi%C4%99_pierwsze_wyst%C4%99puj%C4%85cych_w_rejestrze_PESEL_bez_zgon%C3%B3w.csv"
    ),
  female_last_name_url:
    System.get_env(
      "FEMALE_LAST_NAME_URL",
      "https://api.dane.gov.pl/media/resources/20250123/nazwiska_%C5%BCe%C5%84skie-osoby_%C5%BCyj%C4%85ce_efby1gw.csv"
    )
