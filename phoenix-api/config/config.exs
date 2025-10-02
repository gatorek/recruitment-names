# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :phoenix_api,
  ecto_repos: [PhoenixApi.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :phoenix_api, PhoenixApiWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: PhoenixApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PhoenixApi.PubSub,
  live_view: [signing_salt: "BHR7pE3M"]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Centralized CSV URLs configuration
config :phoenix_api, :import,
  male_first_name_url:
    "https://api.dane.gov.pl/media/resources/20250124/8_-_Wykaz_imion_m%C4%99skich_os%C3%B3b_%C5%BCyj%C4%85cych_wg_pola_imi%C4%99_pierwsze_wyst%C4%99puj%C4%85cych_w_rejestrze_PESEL_bez_zgon%C3%B3w.csv",
  male_last_name_url:
    "https://api.dane.gov.pl/media/resources/20250123/nazwiska_m%C4%99skie-osoby_%C5%BCyj%C4%85ce.csv",
  female_first_name_url:
    "https://api.dane.gov.pl/media/resources/20250124/8_-_Wykaz_imion_%C5%BCe%C5%84skich__os%C3%B3b_%C5%BCyj%C4%85cych_wg_pola_imi%C4%99_pierwsze_wyst%C4%99puj%C4%85cych_w_rejestrze_PESEL_bez_zgon%C3%B3w.csv",
  female_last_name_url:
    "https://api.dane.gov.pl/media/resources/20250123/nazwiska_%C5%BCe%C5%84skie-osoby_%C5%BCyj%C4%85ce_efby1gw.csv"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
