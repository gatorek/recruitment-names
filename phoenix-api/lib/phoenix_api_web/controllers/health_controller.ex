defmodule PhoenixApiWeb.HealthController do
  use PhoenixApiWeb, :controller

  @doc """
  Health check endpoint that returns a simple "ok" response.

  ## Returns

  - `200` with `"ok"` - Service is healthy
  """
  def check(conn, _params) do
    conn
    |> put_status(:ok)
    |> text("ok")
  end
end
