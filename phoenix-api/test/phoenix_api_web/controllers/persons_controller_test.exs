defmodule PhoenixApiWeb.PersonsControllerTest do
  use PhoenixApiWeb.ConnCase, async: false
  import Mimic

  alias PhoenixApi.ApiClient
  alias PhoenixApi.Repo
  alias PhoenixApi.Schemas.Person, as: PersonSchema

  # Test URLs from .env-example
  @male_first_name_url "https://api.dane.gov.pl/media/resources/20250124/8_-_Wykaz_imion_m%C4%99skich_os%C3%B3b_%C5%BCyj%C4%85cych_wg_pola_imi%C4%99_pierwsze_wyst%C4%99puj%C4%85cych_w_rejestrze_PESEL_bez_zgon%C3%B3w.csv"
  @male_last_name_url "https://api.dane.gov.pl/media/resources/20250123/nazwiska_m%C4%99skie-osoby_%C5%BCyj%C4%85ce.csv"
  @female_first_name_url "https://api.dane.gov.pl/media/resources/20250124/8_-_Wykaz_imion_%C5%BCe%C5%84skich__os%C3%B3b_%C5%BCyj%C4%85cych_wg_pola_imi%C4%99_pierwsze_wyst%C4%99puj%C4%85cych_w_rejestrze_PESEL_bez_zgon%C3%B3w.csv"
  @female_last_name_url "https://api.dane.gov.pl/media/resources/20250123/nazwiska_%C5%BCe%C5%84skie-osoby_%C5%BCyj%C4%85ce_efby1gw.csv"

  setup :verify_on_exit!

  setup do
    # Copy modules for Mimic
    Mimic.copy(PhoenixApi.RandomNamesGenerator)
    # Setup database sandbox
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(PhoenixApi.Repo)

    # Set default configuration for tests
    Application.put_env(:phoenix_api, :person,
      male_first_name_url: @male_first_name_url,
      male_last_name_url: @male_last_name_url,
      female_first_name_url: @female_first_name_url,
      female_last_name_url: @female_last_name_url
    )

    # Clean up database before each test
    Repo.delete_all(PersonSchema)
    :ok
  end

  describe "POST /import" do
    test "successfully imports persons with default parameters", %{conn: conn} do
      # Mock ApiClient calls to return test data
      stub(ApiClient, :call, fn url, _count ->
        case url do
          @male_first_name_url ->
            {:ok, ["JAN", "PIOTR", "STANISŁAW", "ANDRZEJ", "PAWEŁ"]}

          @male_last_name_url ->
            {:ok, ["KOWALSKI", "NOWAK", "WIŚNIEWSKI", "WÓJCIK", "KOWALCZYK"]}

          @female_first_name_url ->
            {:ok, ["ANNA", "MARIA", "KRYSTYNA", "BARBARA", "DANUTA"]}

          @female_last_name_url ->
            {:ok, ["KOWALSKA", "NOWAK", "WIŚNIEWSKA", "WÓJCIK", "KOWALCZYK"]}

          _ ->
            {:error, "Unknown URL"}
        end
      end)

      # Make the request
      conn = post(conn, ~p"/import")

      # Assert response
      assert %{"count" => count} = json_response(conn, 200)
      # Default count
      assert count == 100

      # Verify that persons were actually inserted into the database
      assert Repo.aggregate(PersonSchema, :count) == 100
    end

    test "returns error when API client fails", %{conn: conn} do
      # Mock ApiClient to return an error
      stub(ApiClient, :call, fn _url, _count ->
        {:error, "Network timeout"}
      end)

      # Make the request
      conn = post(conn, ~p"/import")

      # Assert error response
      assert %{"error" => "Network timeout"} = json_response(conn, 500)
    end

    test "returns error when API client fails with network error", %{conn: conn} do
      # Mock ApiClient to return a network error
      stub(ApiClient, :call, fn _url, _count ->
        {:error, "Connection timeout"}
      end)

      # Make the request
      conn = post(conn, ~p"/import")

      # Assert error response
      assert %{"error" => "Connection timeout"} = json_response(conn, 500)
    end

    test "ignores request parameters and uses defaults", %{conn: conn} do
      # Mock ApiClient calls to return test data
      stub(ApiClient, :call, fn url, _count ->
        case url do
          @male_first_name_url ->
            {:ok, ["JAN", "PIOTR", "STANISŁAW", "ANDRZEJ", "PAWEŁ"]}

          @male_last_name_url ->
            {:ok, ["KOWALSKI", "NOWAK", "WIŚNIEWSKI", "WÓJCIK", "KOWALCZYK"]}

          @female_first_name_url ->
            {:ok, ["ANNA", "MARIA", "KRYSTYNA", "BARBARA", "DANUTA"]}

          @female_last_name_url ->
            {:ok, ["KOWALSKA", "NOWAK", "WIŚNIEWSKA", "WÓJCIK", "KOWALCZYK"]}

          _ ->
            {:error, "Unknown URL"}
        end
      end)

      # Make the request with parameters (should be ignored)
      conn =
        post(conn, ~p"/import", %{
          "count" => 5,
          "birth_date_from" => "1990-01-01",
          "birth_date_to" => "2000-12-31"
        })

      # Assert response - should still use default count of 100
      assert %{"count" => count} = json_response(conn, 200)
      # Default count, not the 5 from params
      assert count == 100

      # Verify that 100 persons were inserted (default count)
      assert Repo.aggregate(PersonSchema, :count) == 100
    end

    test "returns proper JSON content type", %{conn: conn} do
      # Mock ApiClient calls to return test data
      stub(ApiClient, :call, fn url, _count ->
        case url do
          @male_first_name_url ->
            {:ok, ["JAN", "PIOTR", "STANISŁAW", "ANDRZEJ", "PAWEŁ"]}

          @male_last_name_url ->
            {:ok, ["KOWALSKI", "NOWAK", "WIŚNIEWSKI", "WÓJCIK", "KOWALCZYK"]}

          @female_first_name_url ->
            {:ok, ["ANNA", "MARIA", "KRYSTYNA", "BARBARA", "DANUTA"]}

          @female_last_name_url ->
            {:ok, ["KOWALSKA", "NOWAK", "WIŚNIEWSKA", "WÓJCIK", "KOWALCZYK"]}

          _ ->
            {:error, "Unknown URL"}
        end
      end)

      # Make the request
      conn = post(conn, ~p"/import")

      # Assert content type
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    end
  end
end
