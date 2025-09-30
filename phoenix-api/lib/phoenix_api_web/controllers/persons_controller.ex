defmodule PhoenixApiWeb.PersonsController do
  use PhoenixApiWeb, :controller

  alias PhoenixApi.Persons

  @doc """
  Imports random persons using default parameters.

  ## Returns

  - `200` with `{"count": number}` - Number of persons successfully imported
  - `500` with `{"error": "error_message"}` - Error occurred during import
  """
  def import(conn, _params) do
    case Persons.import(%{}) do
      {:ok, count} ->
        conn
        |> put_status(:ok)
        |> json(%{count: count})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: to_string(reason)})
    end
  end
end
