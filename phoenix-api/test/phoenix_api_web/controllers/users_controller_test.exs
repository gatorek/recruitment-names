defmodule PhoenixApiWeb.UsersControllerTest do
  use PhoenixApiWeb.ConnCase, async: false
  import Mimic

  alias PhoenixApi.ApiClient
  alias PhoenixApi.Users
  alias PhoenixApi.Repo
  alias PhoenixApi.Schemas.User, as: UserSchema

  setup :verify_on_exit!

  # Test URLs from .env-example
  @male_first_name_url "https://api.dane.gov.pl/media/resources/20250124/8_-_Wykaz_imion_m%C4%99skich_os%C3%B3b_%C5%BCyj%C4%85cych_wg_pola_imi%C4%99_pierwsze_wyst%C4%99puj%C4%85cych_w_rejestrze_PESEL_bez_zgon%C3%B3w.csv"
  @male_last_name_url "https://api.dane.gov.pl/media/resources/20250123/nazwiska_m%C4%99skie-osoby_%C5%BCyj%C4%85ce.csv"
  @female_first_name_url "https://api.dane.gov.pl/media/resources/20250124/8_-_Wykaz_imion_%C5%BCe%C5%84skich__os%C3%B3b_%C5%BCyj%C4%85cych_wg_pola_imi%C4%99_pierwsze_wyst%C4%99puj%C4%85cych_w_rejestrze_PESEL_bez_zgon%C3%B3w.csv"
  @female_last_name_url "https://api.dane.gov.pl/media/resources/20250123/nazwiska_%C5%BCe%C5%84skie-osoby_%C5%BCyj%C4%85ce_efby1gw.csv"

  setup do
    # Copy modules for Mimic
    Mimic.copy(Users)
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
    Repo.delete_all(UserSchema)
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
      assert Repo.aggregate(UserSchema, :count) == 100
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
      assert Repo.aggregate(UserSchema, :count) == 100
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

  describe "GET /users" do
    test "calls Users.list_users with correct parameters", %{conn: conn} do
      # Mock the Users module
      stub(Users, :list_users, fn params ->
        # Verify that parameters are passed correctly
        assert params[:first_name] == "John"
        assert params[:gender] == :male

        {:ok, []}
      end)

      conn =
        get(conn, ~p"/users", %{
          "first_name" => "John",
          "gender" => "male"
        })

      assert json_response(conn, 200)
    end

    test "returns proper JSON structure", %{conn: conn} do
      stub(Users, :list_users, fn _params ->
        {:ok, []}
      end)

      conn = get(conn, ~p"/users")

      response = json_response(conn, 200)
      assert Map.has_key?(response, "data")
      assert response["data"] == []
    end

    test "parses date parameters correctly", %{conn: conn} do
      stub(Users, :list_users, fn params ->
        # Verify that date parameters are parsed to Date structs
        assert params[:birthdate_from] == ~D[1990-01-01]
        assert params[:birthdate_to] == ~D[1999-12-31]

        {:ok, []}
      end)

      conn =
        get(conn, ~p"/users", %{
          "birthdate_from" => "1990-01-01",
          "birthdate_to" => "1999-12-31"
        })

      assert json_response(conn, 200)
    end

    test "handles invalid date parameters gracefully", %{conn: conn} do
      conn =
        get(conn, ~p"/users", %{
          "birthdate_from" => "invalid-date",
          "birthdate_to" => "1999-12-31"
        })

      response = json_response(conn, 400)
      assert response["error"] == "Invalid date format. Use YYYY-MM-DD"
    end

    test "returns error for invalid gender", %{conn: conn} do
      conn = get(conn, ~p"/users", %{"gender" => "invalid"})

      response = json_response(conn, 400)
      assert response["error"] == "gender must be 'male' or 'female'"
    end

    test "returns error for invalid date format", %{conn: conn} do
      conn = get(conn, ~p"/users", %{"birthdate_from" => "invalid-date"})

      response = json_response(conn, 400)
      assert response["error"] == "Invalid date format. Use YYYY-MM-DD"
    end

    test "returns error for invalid sort field", %{conn: conn} do
      conn = get(conn, ~p"/users", %{"sort" => "invalid_field"})

      response = json_response(conn, 400)
      assert response["error"] == "sort must be one of: first_name, last_name, gender, birthdate"
    end

    test "returns error for invalid order", %{conn: conn} do
      conn = get(conn, ~p"/users", %{"order" => "invalid"})

      response = json_response(conn, 400)
      assert response["error"] == "order must be one of: asc, desc"
    end
  end

  describe "GET /users/:id" do
    test "calls Users.get_user with correct ID", %{conn: conn} do
      stub(Users, :get_user, fn id ->
        assert id == 123
        {:ok, %UserSchema{id: 123, first_name: "John"}}
      end)

      conn = get(conn, ~p"/users/123")

      assert json_response(conn, 200)
    end

    test "returns error for invalid ID format", %{conn: conn} do
      conn = get(conn, ~p"/users/invalid")

      response = json_response(conn, 400)
      assert response["error"] == "ID must be a valid integer"
    end

    test "returns error for negative ID", %{conn: conn} do
      conn = get(conn, ~p"/users/-1")

      response = json_response(conn, 400)
      assert response["error"] == "ID must be a valid positive integer"
    end

    test "returns error for ID with trailing characters", %{conn: conn} do
      conn = get(conn, ~p"/users/123abc")

      response = json_response(conn, 400)
      assert response["error"] == "ID must be a valid positive integer"
    end

    test "handles not found response", %{conn: conn} do
      stub(Users, :get_user, fn _id ->
        {:error, :not_found}
      end)

      conn = get(conn, ~p"/users/999")

      response = json_response(conn, 404)
      assert response["error"] == "User not found"
    end
  end

  describe "POST /users" do
    test "calls Users.create_user with correct parameters", %{conn: conn} do
      user_params = %{
        "first_name" => "John",
        "last_name" => "Doe",
        "gender" => "male",
        "birthdate" => "1990-01-01"
      }

      stub(Users, :create_user, fn params ->
        # Verify that parameters are parsed correctly
        assert params[:first_name] == "John"
        assert params[:last_name] == "Doe"
        assert params[:gender] == :male
        assert params[:birthdate] == ~D[1990-01-01]
        {:ok, %UserSchema{id: 1, first_name: "John"}}
      end)

      conn = post(conn, ~p"/users", user_params)

      assert json_response(conn, 201)
    end

    test "handles validation errors from business layer", %{conn: conn} do
      # This test now passes valid parameters to trigger business layer validation
      stub(Users, :create_user, fn _params ->
        {:error, %Ecto.Changeset{errors: [first_name: {"can't be blank", []}]}}
      end)

      conn =
        post(conn, ~p"/users", %{
          "first_name" => "John",
          "last_name" => "Doe",
          "gender" => "male",
          "birthdate" => "1990-01-01"
        })

      response = json_response(conn, 422)
      assert Map.has_key?(response, "errors")
    end

    test "returns error for missing first_name", %{conn: conn} do
      conn =
        post(conn, ~p"/users", %{
          "last_name" => "Doe",
          "gender" => "male",
          "birthdate" => "1990-01-01"
        })

      response = json_response(conn, 400)
      assert response["error"] == "first_name is required"
    end

    test "returns error for missing last_name", %{conn: conn} do
      conn =
        post(conn, ~p"/users", %{
          "first_name" => "John",
          "gender" => "male",
          "birthdate" => "1990-01-01"
        })

      response = json_response(conn, 400)
      assert response["error"] == "last_name is required"
    end

    test "returns error for missing gender", %{conn: conn} do
      conn =
        post(conn, ~p"/users", %{
          "first_name" => "John",
          "last_name" => "Doe",
          "birthdate" => "1990-01-01"
        })

      response = json_response(conn, 400)
      assert response["error"] == "gender is required"
    end

    test "returns error for missing birthdate", %{conn: conn} do
      conn =
        post(conn, ~p"/users", %{
          "first_name" => "John",
          "last_name" => "Doe",
          "gender" => "male"
        })

      response = json_response(conn, 400)
      assert response["error"] == "birthdate is required"
    end

    test "returns error for invalid gender", %{conn: conn} do
      conn =
        post(conn, ~p"/users", %{
          "first_name" => "John",
          "last_name" => "Doe",
          "gender" => "invalid",
          "birthdate" => "1990-01-01"
        })

      response = json_response(conn, 400)
      assert response["error"] == "gender must be 'male' or 'female'"
    end

    test "returns error for invalid birthdate format", %{conn: conn} do
      conn =
        post(conn, ~p"/users", %{
          "first_name" => "John",
          "last_name" => "Doe",
          "gender" => "male",
          "birthdate" => "invalid-date"
        })

      response = json_response(conn, 400)
      assert response["error"] == "Invalid birthdate format. Use YYYY-MM-DD"
    end

    test "returns error for empty first_name", %{conn: conn} do
      conn =
        post(conn, ~p"/users", %{
          "first_name" => "",
          "last_name" => "Doe",
          "gender" => "male",
          "birthdate" => "1990-01-01"
        })

      response = json_response(conn, 400)
      assert response["error"] == "first_name cannot be empty"
    end
  end

  describe "PUT /users/:id" do
    test "calls Users.update_user with correct parameters", %{conn: conn} do
      update_params = %{
        "first_name" => "Jane",
        "last_name" => "Smith"
      }

      stub(Users, :update_user, fn id, params ->
        assert id == 123
        # Verify that parameters are parsed correctly
        assert params[:first_name] == "Jane"
        assert params[:last_name] == "Smith"
        assert params[:gender] == nil
        assert params[:birthdate] == nil
        {:ok, %UserSchema{id: 123, first_name: "Jane"}}
      end)

      conn = put(conn, ~p"/users/123", update_params)

      assert json_response(conn, 200)
    end

    test "handles not found response", %{conn: conn} do
      stub(Users, :update_user, fn _id, _params ->
        {:error, :not_found}
      end)

      conn = put(conn, ~p"/users/999", %{"first_name" => "Jane"})

      response = json_response(conn, 404)
      assert response["error"] == "User not found"
    end

    test "handles validation errors from business layer", %{conn: conn} do
      # This test now passes valid parameters to trigger business layer validation
      stub(Users, :update_user, fn _id, _params ->
        {:error, %Ecto.Changeset{errors: [first_name: {"can't be blank", []}]}}
      end)

      conn =
        put(conn, ~p"/users/123", %{
          "first_name" => "Jane",
          "last_name" => "Smith"
        })

      response = json_response(conn, 422)
      assert Map.has_key?(response, "errors")
    end

    test "returns error for invalid gender", %{conn: conn} do
      conn =
        put(conn, ~p"/users/123", %{
          "first_name" => "Jane",
          "gender" => "invalid"
        })

      response = json_response(conn, 400)
      assert response["error"] == "gender must be 'male' or 'female'"
    end

    test "returns error for invalid birthdate format", %{conn: conn} do
      conn =
        put(conn, ~p"/users/123", %{
          "first_name" => "Jane",
          "birthdate" => "invalid-date"
        })

      response = json_response(conn, 400)
      assert response["error"] == "Invalid birthdate format. Use YYYY-MM-DD"
    end

    test "returns error for too long first_name", %{conn: conn} do
      long_name = String.duplicate("a", 101)

      conn =
        put(conn, ~p"/users/123", %{
          "first_name" => long_name
        })

      response = json_response(conn, 400)
      assert response["error"] == "first_name must be between 1 and 100 characters"
    end

    test "allows empty strings for optional fields", %{conn: conn} do
      stub(Users, :update_user, fn id, params ->
        assert id == 123
        assert params[:first_name] == nil
        assert params[:last_name] == nil
        assert params[:gender] == nil
        assert params[:birthdate] == nil
        {:ok, %UserSchema{id: 123, first_name: "Jane"}}
      end)

      conn =
        put(conn, ~p"/users/123", %{
          "first_name" => "",
          "last_name" => "",
          "birthdate" => ""
        })

      assert json_response(conn, 200)
    end
  end

  describe "DELETE /users/:id" do
    test "calls Users.delete_user with correct ID", %{conn: conn} do
      stub(Users, :delete_user, fn id ->
        assert id == 123
        :ok
      end)

      conn = delete(conn, ~p"/users/123")

      assert json_response(conn, 204)
    end

    test "handles not found response", %{conn: conn} do
      stub(Users, :delete_user, fn _id ->
        {:error, :not_found}
      end)

      conn = delete(conn, ~p"/users/999")

      response = json_response(conn, 404)
      assert response["error"] == "User not found"
    end
  end
end
