defmodule PhoenixApiWeb.HealthControllerTest do
  use PhoenixApiWeb.ConnCase, async: true

  describe "GET /healthcheck" do
    test "returns ok with 200 status", %{conn: conn} do
      conn = get(conn, ~p"/healthcheck")

      assert response(conn, 200) == "ok"
    end

    test "returns text/plain content type", %{conn: conn} do
      conn = get(conn, ~p"/healthcheck")

      assert get_resp_header(conn, "content-type") == ["text/plain; charset=utf-8"]
    end
  end
end
