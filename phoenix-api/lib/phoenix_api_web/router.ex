defmodule PhoenixApiWeb.Router do
  use PhoenixApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PhoenixApiWeb do
    pipe_through :api

    post "/import", PersonsController, :import
  end
end
