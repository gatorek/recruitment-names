defmodule PhoenixApiWeb.Router do
  use PhoenixApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PhoenixApiWeb do
    pipe_through :api

    post "/import", PersonsController, :import

    # User CRUD operations
    get "/users", UsersController, :index
    get "/users/:id", UsersController, :show
    post "/users", UsersController, :create
    put "/users/:id", UsersController, :update
    delete "/users/:id", UsersController, :delete
  end
end
