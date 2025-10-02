defmodule PhoenixApiWeb.Router do
  use PhoenixApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_protected do
    plug :accepts, ["json"]
    plug PhoenixApiWeb.Plugs.ApiTokenAuth
  end

  scope "/", PhoenixApiWeb do
    pipe_through :api

    # User CRUD operations (public)
    get "/users", UsersController, :index
    get "/users/:id", UsersController, :show
    post "/users", UsersController, :create
    put "/users/:id", UsersController, :update
    delete "/users/:id", UsersController, :delete
  end

  scope "/", PhoenixApiWeb do
    pipe_through :api_protected

    # Protected endpoints requiring API token
    post "/import", UsersController, :import
  end
end
