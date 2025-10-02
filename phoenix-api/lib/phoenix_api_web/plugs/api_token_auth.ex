defmodule PhoenixApiWeb.Plugs.ApiTokenAuth do
  @moduledoc """
  Plug for API token authentication.

  This plug validates API tokens sent in the Authorization header
  using the Bearer token format.
  """

  import Plug.Conn
  import Phoenix.Controller

  @doc """
  Validates the API token from the Authorization header.

  Expected header format: `Authorization: Bearer <token>`
  """
  def init(opts), do: opts

  def call(conn, _opts) do
    case get_auth_header(conn) do
      {:ok, token} ->
        if valid_token?(token) do
          conn
        else
          conn
          |> put_status(:unauthorized)
          |> json(%{error: "Invalid API token"})
          |> halt()
        end

      {:error, :missing} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Missing Authorization header"})
        |> halt()

      {:error, :invalid_format} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid Authorization header format. Use: Bearer <token>"})
        |> halt()
    end
  end

  defp get_auth_header(conn) do
    case get_req_header(conn, "authorization") do
      [header | _] ->
        case String.split(header, " ", parts: 2) do
          ["Bearer", token] when token != "" ->
            {:ok, token}

          _ ->
            {:error, :invalid_format}
        end

      [] ->
        {:error, :missing}
    end
  end

  defp valid_token?(token) do
    expected_token = Application.get_env(:phoenix_api, :api_token)

    case expected_token do
      nil ->
        false

      expected when is_binary(expected) ->
        Plug.Crypto.secure_compare(token, expected)

      _ ->
        false
    end
  end
end
