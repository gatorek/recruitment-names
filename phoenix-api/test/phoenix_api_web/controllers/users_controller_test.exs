defmodule PhoenixApiWeb.UsersControllerTest do
  use PhoenixApiWeb.ConnCase, async: false
  import Mimic

  alias PhoenixApi.Persons
  alias PhoenixApi.Repo
  alias PhoenixApi.Schemas.Person, as: PersonSchema

  setup :verify_on_exit!

  setup do
    # Copy modules for Mimic
    Mimic.copy(Persons)

    # Setup database sandbox
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(PhoenixApi.Repo)

    # Clean up database before each test
    Repo.delete_all(PersonSchema)
    :ok
  end

  describe "GET /users" do
    test "calls Persons.list_persons with correct parameters", %{conn: conn} do
      # Mock the Persons module
      stub(Persons, :list_persons, fn params ->
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
      stub(Persons, :list_persons, fn _params ->
        {:ok, []}
      end)

      conn = get(conn, ~p"/users")

      response = json_response(conn, 200)
      assert Map.has_key?(response, "data")
      assert response["data"] == []
    end

    test "parses date parameters correctly", %{conn: conn} do
      stub(Persons, :list_persons, fn params ->
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
    test "calls Persons.get_person with correct ID", %{conn: conn} do
      stub(Persons, :get_person, fn id ->
        assert id == 123
        {:ok, %PersonSchema{id: 123, first_name: "John"}}
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
      stub(Persons, :get_person, fn _id ->
        {:error, :not_found}
      end)

      conn = get(conn, ~p"/users/999")

      response = json_response(conn, 404)
      assert response["error"] == "User not found"
    end
  end

  describe "POST /users" do
    test "calls Persons.create_person with correct parameters", %{conn: conn} do
      user_params = %{
        "first_name" => "John",
        "last_name" => "Doe",
        "gender" => "male",
        "birthdate" => "1990-01-01"
      }

      stub(Persons, :create_person, fn params ->
        # Verify that parameters are parsed correctly
        assert params[:first_name] == "John"
        assert params[:last_name] == "Doe"
        assert params[:gender] == :male
        assert params[:birthdate] == ~D[1990-01-01]
        {:ok, %PersonSchema{id: 1, first_name: "John"}}
      end)

      conn = post(conn, ~p"/users", user_params)

      assert json_response(conn, 201)
    end

    test "handles validation errors from business layer", %{conn: conn} do
      # This test now passes valid parameters to trigger business layer validation
      stub(Persons, :create_person, fn _params ->
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
    test "calls Persons.update_person with correct parameters", %{conn: conn} do
      update_params = %{
        "first_name" => "Jane",
        "last_name" => "Smith"
      }

      stub(Persons, :update_person, fn id, params ->
        assert id == 123
        # Verify that parameters are parsed correctly
        assert params[:first_name] == "Jane"
        assert params[:last_name] == "Smith"
        assert params[:gender] == nil
        assert params[:birthdate] == nil
        {:ok, %PersonSchema{id: 123, first_name: "Jane"}}
      end)

      conn = put(conn, ~p"/users/123", update_params)

      assert json_response(conn, 200)
    end

    test "handles not found response", %{conn: conn} do
      stub(Persons, :update_person, fn _id, _params ->
        {:error, :not_found}
      end)

      conn = put(conn, ~p"/users/999", %{"first_name" => "Jane"})

      response = json_response(conn, 404)
      assert response["error"] == "User not found"
    end

    test "handles validation errors from business layer", %{conn: conn} do
      # This test now passes valid parameters to trigger business layer validation
      stub(Persons, :update_person, fn _id, _params ->
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
      stub(Persons, :update_person, fn id, params ->
        assert id == 123
        assert params[:first_name] == nil
        assert params[:last_name] == nil
        assert params[:gender] == nil
        assert params[:birthdate] == nil
        {:ok, %PersonSchema{id: 123, first_name: "Jane"}}
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
    test "calls Persons.delete_person with correct ID", %{conn: conn} do
      stub(Persons, :delete_person, fn id ->
        assert id == 123
        :ok
      end)

      conn = delete(conn, ~p"/users/123")

      assert json_response(conn, 204)
    end

    test "handles not found response", %{conn: conn} do
      stub(Persons, :delete_person, fn _id ->
        {:error, :not_found}
      end)

      conn = delete(conn, ~p"/users/999")

      response = json_response(conn, 404)
      assert response["error"] == "User not found"
    end
  end
end
