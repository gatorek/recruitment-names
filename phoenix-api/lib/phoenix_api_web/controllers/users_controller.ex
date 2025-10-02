defmodule PhoenixApiWeb.UsersController do
  use PhoenixApiWeb, :controller

  alias PhoenixApi.Users

  @valid_sort_fields ~w[first_name last_name gender birthdate]a
  @valid_order_fields ~w[asc desc]a

  @doc """
  Imports random users using default parameters.

  ## Returns

  - `200` with `{"count": number}` - Number of users successfully imported
  - `500` with `{"error": "error_message"}` - Error occurred during import
  """
  def import(conn, _params) do
    case Users.import(%{}) do
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

  @doc """
  Lists users with filtering and sorting options.

  ## Query Parameters

  - `first_name` - Filter by first name (partial match)
  - `last_name` - Filter by last name (partial match)
  - `gender` - Filter by gender (male/female)
  - `birthdate_from` - Filter by birthdate from (YYYY-MM-DD)
  - `birthdate_to` - Filter by birthdate to (YYYY-MM-DD)
  - `sort` - Sort by field (first_name, last_name, gender, birthdate)
  - `order` - Sort order (asc/desc, defaults to asc)

  ## Returns

  - `200` with user list
  """
  def index(conn, params) do
    with {:ok, parsed_params} <- parse_list_params(params),
         {:ok, users} <- Users.list_users(parsed_params) do
      conn
      |> put_status(:ok)
      |> json(%{data: users})
    else
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  @doc """
  Shows a specific user by ID.

  ## Returns

  - `200` with user data
  - `404` if user not found
  """
  def show(conn, %{"id" => id_string}) do
    with {:ok, id} <- parse_id(id_string),
         {:ok, user} <- Users.get_user(id) do
      conn
      |> put_status(:ok)
      |> json(%{data: user})
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "User not found"})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  @doc """
  Creates a new user.

  ## Request Body

  ```json
  {
    "first_name": "John",
    "last_name": "Doe",
    "gender": "male",
    "birthdate": "1990-01-01"
  }
  ```

  ## Returns

  - `201` with created user data
  - `422` with validation errors
  """
  def create(conn, params) do
    with {:ok, parsed_params} <- parse_create_params(params),
         {:ok, user} <- Users.create_user(parsed_params) do
      conn
      |> put_status(:created)
      |> json(%{data: user})
    else
      {:error, changeset} when is_struct(changeset, Ecto.Changeset) ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  @doc """
  Updates an existing user.

  ## Request Body

  ```json
  {
    "first_name": "Jane",
    "last_name": "Smith",
    "gender": "female",
    "birthdate": "1995-05-15"
  }
  ```

  ## Returns

  - `200` with updated user data
  - `404` if user not found
  - `422` with validation errors
  """
  def update(conn, %{"id" => id_string} = params) do
    with {:ok, id} <- parse_id(id_string),
         {:ok, parsed_params} <- parse_update_params(params),
         {:ok, updated_user} <- Users.update_user(id, parsed_params) do
      conn
      |> put_status(:ok)
      |> json(%{data: updated_user})
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "User not found"})

      {:error, changeset} when is_struct(changeset, Ecto.Changeset) ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  @doc """
  Deletes a user.

  ## Returns

  - `204` on successful deletion
  - `404` if user not found
  """
  def delete(conn, %{"id" => id_string}) do
    with {:ok, id} <- parse_id(id_string),
         :ok <- Users.delete_user(id) do
      conn
      |> put_status(:no_content)
      |> json(%{})
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "User not found"})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  # Private functions

  defp parse_list_params(params) do
    with {:ok, gender} <- parse_gender(params["gender"]),
         {:ok, birthdate_from} <- parse_date(params["birthdate_from"]),
         {:ok, birthdate_to} <- parse_date(params["birthdate_to"]),
         {:ok, sort} <- validate_sort(params["sort"]),
         {:ok, order} <- validate_order(params["order"]) do
      parsed_params = %{
        first_name: params["first_name"],
        last_name: params["last_name"],
        gender: gender,
        birthdate_from: birthdate_from,
        birthdate_to: birthdate_to,
        sort: sort,
        order: order
      }

      {:ok, parsed_params}
    end
  end

  defp parse_id(id_string) when is_binary(id_string) do
    case Integer.parse(id_string) do
      {id, ""} when id > 0 -> {:ok, id}
      {_id, _rest} -> {:error, "ID must be a valid positive integer"}
      :error -> {:error, "ID must be a valid integer"}
    end
  end

  defp parse_create_params(params) do
    with {:ok, first_name} <- validate_required_string(params["first_name"], "first_name"),
         {:ok, last_name} <- validate_required_string(params["last_name"], "last_name"),
         {:ok, gender} <- parse_gender_required(params["gender"]),
         {:ok, birthdate} <- parse_birthdate(params["birthdate"]) do
      parsed_params = %{
        first_name: first_name,
        last_name: last_name,
        gender: gender,
        birthdate: birthdate
      }

      {:ok, parsed_params}
    end
  end

  defp validate_required_string(nil, field_name) do
    {:error, "#{field_name} is required"}
  end

  defp validate_required_string("", field_name) do
    {:error, "#{field_name} cannot be empty"}
  end

  defp validate_required_string(value, field_name) when is_binary(value) do
    if String.length(value) > 0 and String.length(value) <= 100 do
      {:ok, value}
    else
      {:error, "#{field_name} must be between 1 and 100 characters"}
    end
  end

  defp validate_required_string(_, field_name) do
    {:error, "#{field_name} must be a string"}
  end

  defp parse_birthdate(nil) do
    {:error, "birthdate is required"}
  end

  defp parse_birthdate("") do
    {:error, "birthdate cannot be empty"}
  end

  defp parse_birthdate(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> {:ok, date}
      {:error, _} -> {:error, "Invalid birthdate format. Use YYYY-MM-DD"}
    end
  end

  defp parse_gender(nil), do: {:ok, nil}
  defp parse_gender("male"), do: {:ok, :male}
  defp parse_gender("female"), do: {:ok, :female}

  defp parse_gender(_gender) do
    {:error, "gender must be 'male' or 'female'"}
  end

  defp parse_gender_required(nil) do
    {:error, "gender is required"}
  end

  defp parse_gender_required(gender) do
    parse_gender(gender)
  end

  defp parse_update_params(params) do
    with {:ok, first_name} <- validate_optional_string(params["first_name"], "first_name"),
         {:ok, last_name} <- validate_optional_string(params["last_name"], "last_name"),
         {:ok, gender} <- parse_gender(params["gender"]),
         {:ok, birthdate} <- parse_optional_date(params["birthdate"]) do
      parsed_params = %{
        first_name: first_name,
        last_name: last_name,
        gender: gender,
        birthdate: birthdate
      }

      {:ok, parsed_params}
    end
  end

  defp validate_optional_string(nil, _field_name), do: {:ok, nil}
  defp validate_optional_string("", _field_name), do: {:ok, nil}

  defp validate_optional_string(value, field_name) when is_binary(value) do
    if String.length(value) > 0 and String.length(value) <= 100 do
      {:ok, value}
    else
      {:error, "#{field_name} must be between 1 and 100 characters"}
    end
  end

  defp validate_optional_string(_, field_name) do
    {:error, "#{field_name} must be a string"}
  end

  defp parse_optional_date(nil), do: {:ok, nil}
  defp parse_optional_date(""), do: {:ok, nil}

  defp parse_optional_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> {:ok, date}
      {:error, _} -> {:error, "Invalid birthdate format. Use YYYY-MM-DD"}
    end
  end

  defp parse_optional_date(_) do
    {:error, "birthdate must be a string"}
  end

  defp parse_date(nil), do: {:ok, nil}
  defp parse_date(""), do: {:ok, nil}

  defp parse_date(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> {:ok, date}
      {:error, _} -> {:error, "Invalid date format. Use YYYY-MM-DD"}
    end
  end

  defp validate_sort(nil), do: {:ok, nil}
  defp validate_sort(""), do: {:ok, nil}

  defp validate_sort(sort) do
    valid_sort_fields = Enum.map(@valid_sort_fields, &Atom.to_string/1)

    if sort in valid_sort_fields do
      {:ok, String.to_existing_atom(sort)}
    else
      {:error, "sort must be one of: #{Enum.join(valid_sort_fields, ", ")}"}
    end
  end

  defp validate_order(nil), do: {:ok, nil}
  defp validate_order(""), do: {:ok, nil}

  defp validate_order(order) do
    valid_order_fields = Enum.map(@valid_order_fields, &Atom.to_string/1)

    if order in valid_order_fields do
      {:ok, String.to_existing_atom(order)}
    else
      {:error, "order must be one of: #{Enum.join(valid_order_fields, ", ")}"}
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", format_value(value))
      end)
    end)
  end

  defp format_value(value) when is_binary(value), do: value
  defp format_value(value) when is_atom(value), do: to_string(value)
  defp format_value(value) when is_integer(value), do: to_string(value)
  defp format_value(value) when is_float(value), do: to_string(value)
  defp format_value(value) when is_list(value), do: inspect(value)
  defp format_value(value) when is_map(value), do: inspect(value)
  defp format_value(value), do: inspect(value)
end
