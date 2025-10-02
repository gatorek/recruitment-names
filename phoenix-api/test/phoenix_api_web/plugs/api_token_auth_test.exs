defmodule PhoenixApiWeb.Plugs.ApiTokenAuthTest do
  use PhoenixApiWeb.ConnCase, async: true

  describe "ApiTokenAuth plug" do
    test "allows access with valid token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer test-api-token-12345")
        |> PhoenixApiWeb.Plugs.ApiTokenAuth.call([])

      refute conn.halted
    end

    test "rejects access without authorization header", %{conn: conn} do
      conn = PhoenixApiWeb.Plugs.ApiTokenAuth.call(conn, [])

      assert conn.halted
      assert conn.status == 401
      assert json_response(conn, 401) == %{"error" => "Missing Authorization header"}
    end

    test "rejects access with invalid token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer invalid-token")
        |> PhoenixApiWeb.Plugs.ApiTokenAuth.call([])

      assert conn.halted
      assert conn.status == 401
      assert json_response(conn, 401) == %{"error" => "Invalid API token"}
    end

    test "rejects access with malformed authorization header", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "InvalidFormat")
        |> PhoenixApiWeb.Plugs.ApiTokenAuth.call([])

      assert conn.halted
      assert conn.status == 401

      assert json_response(conn, 401) == %{
               "error" => "Invalid Authorization header format. Use: Bearer <token>"
             }
    end

    test "rejects access with empty token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer ")
        |> PhoenixApiWeb.Plugs.ApiTokenAuth.call([])

      assert conn.halted
      assert conn.status == 401

      assert json_response(conn, 401) == %{
               "error" => "Invalid Authorization header format. Use: Bearer <token>"
             }
    end
  end
end
