defmodule PhoenixApi.Users do
  @moduledoc """
  Module for importing and generating random user data.

  This module provides functionality to fetch names from external APIs
  and generate random users with birth dates within specified ranges.
  """

  alias PhoenixApi.ApiClient
  alias PhoenixApi.RandomNamesGenerator
  alias PhoenixApi.Repo
  alias PhoenixApi.Schemas.User

  import Ecto.Query

  @type url_map :: %{
          male: %{
            first_name: String.t(),
            last_name: String.t()
          },
          female: %{
            first_name: String.t(),
            last_name: String.t()
          }
        }

  @type import_params :: %{
          urls: url_map(),
          birth_date_from: Date.t(),
          birth_date_to: Date.t(),
          count: pos_integer(),
          top: pos_integer()
        }

  @type filter_params :: %{
          first_name: String.t() | nil,
          last_name: String.t() | nil,
          gender: atom() | nil,
          birthdate_from: Date.t() | nil,
          birthdate_to: Date.t() | nil,
          sort: String.t() | nil,
          order: String.t() | nil
        }

  # Default values
  @default_birth_date_from ~D[1970-01-01]
  @default_birth_date_to ~D[2024-12-31]
  @default_count 100
  @default_top 100

  @doc """
  Imports names from external APIs and saves random users to the database.

  ## Parameters

  - `params` - A map containing:
    - `urls` - Map with URLs for male and female first/last names
    - `birth_date_from` - Start date for birth date range (optional, defaults to #{@default_birth_date_from})
    - `birth_date_to` - End date for birth date range (optional, defaults to #{@default_birth_date_to})
    - `count` - Number of users to generate (optional, defaults to #{@default_count})
    - `top` - Number of names to fetch from each URL (optional, defaults to #{@default_top})

  ## Returns

  - `{:ok, count}` - Number of users successfully saved to database
  - `{:error, reason}` - Error tuple with reason for failure

  ## Examples

      iex> params = %{
      ...>   urls: %{
      ...>     male: %{
      ...>       first_name: "https://example.com/male-first.csv",
      ...>       last_name: "https://example.com/male-last.csv"
      ...>     },
      ...>     female: %{
      ...>       first_name: "https://example.com/female-first.csv",
      ...>       last_name: "https://example.com/female-last.csv"
      ...>     }
      ...>   },
      ...>   birth_date_from: ~D[1990-01-01],
      ...>   birth_date_to: ~D[2000-12-31],
      ...>   count: 5,
      ...>   top: 50
      ...> }
      iex> PhoenixApi.Users.import(params)
      {:ok, 5}

  """
  @spec import(map()) :: {:ok, non_neg_integer()} | {:error, any()}
  def import(params) do
    with {:ok, processed_params} <- process_import_params(params),
         {:ok, names} <- fetch_names(processed_params),
         {:ok, count} <- save_users(names, processed_params) do
      {:ok, count}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec process_import_params(map()) :: {:ok, import_params()} | {:error, atom()}
  defp process_import_params(params) do
    urls = get_urls(params)
    birth_date_from = Map.get(params, :birth_date_from, @default_birth_date_from)
    birth_date_to = Map.get(params, :birth_date_to, @default_birth_date_to)
    count = Map.get(params, :count, @default_count)
    top = Map.get(params, :top, @default_top)

    # Validate date range
    if Date.compare(birth_date_from, birth_date_to) == :gt do
      {:error, :invalid_date_range}
    else
      {:ok,
       %{
         urls: urls,
         birth_date_from: birth_date_from,
         birth_date_to: birth_date_to,
         count: count,
         top: top
       }}
    end
  end

  @spec get_urls(map()) :: url_map()
  defp get_urls(params) do
    default_urls = get_default_urls()

    urls = Map.get(params, :urls, %{})

    %{
      male: %{
        first_name: urls[:male][:first_name] || default_urls.male.first_name,
        last_name: urls[:male][:last_name] || default_urls.male.last_name
      },
      female: %{
        first_name: urls[:female][:first_name] || default_urls.female.first_name,
        last_name: urls[:female][:last_name] || default_urls.female.last_name
      }
    }
  end

  @spec get_default_urls() :: url_map()
  defp get_default_urls do
    config = Application.get_env(:phoenix_api, :import)

    %{
      male: %{
        first_name: Keyword.get(config, :male_first_name_url),
        last_name: Keyword.get(config, :male_last_name_url)
      },
      female: %{
        first_name: Keyword.get(config, :female_first_name_url),
        last_name: Keyword.get(config, :female_last_name_url)
      }
    }
  end

  @spec fetch_names(import_params()) :: {:ok, map()} | {:error, any()}
  defp fetch_names(params) do
    with {:ok, male_first_names} <- ApiClient.call(params.urls.male.first_name, params.top),
         {:ok, male_last_names} <- ApiClient.call(params.urls.male.last_name, params.top),
         {:ok, female_first_names} <- ApiClient.call(params.urls.female.first_name, params.top),
         {:ok, female_last_names} <- ApiClient.call(params.urls.female.last_name, params.top) do
      {:ok,
       %{
         male_first_names: male_first_names,
         male_last_names: male_last_names,
         female_first_names: female_first_names,
         female_last_names: female_last_names
       }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec save_users(map(), import_params()) :: {:ok, non_neg_integer()} | {:error, any()}
  defp save_users(names, params) do
    birth_date_range = Date.range(params.birth_date_from, params.birth_date_to)
    generated_users = RandomNamesGenerator.call(names, birth_date_range, params.count)

    # Convert generated users to data for insert_all
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    user_data =
      Enum.map(generated_users, fn user ->
        %{
          first_name: user.first_name,
          last_name: user.last_name,
          gender: user.gender,
          birthdate: user.birth_date,
          inserted_at: now,
          updated_at: now
        }
      end)

    case Repo.insert_all(User, user_data) do
      {count, _} -> {:ok, count}
    end
  end

  # CRUD Operations

  @doc """
  Lists users with filtering and sorting.

  ## Parameters

  - `params` - A map containing filter and sort parameters

  ## Returns

  - `{:ok, [User.t()]}` - List of users
  """
  @spec list_users(map()) :: {:ok, [User.t()]}
  def list_users(params) do
    users =
      params
      |> build_query()
      |> Repo.all()

    {:ok, users}
  end

  @doc """
  Gets a user by ID.

  ## Parameters

  - `id` - User ID

  ## Returns

  - `{:ok, user}` - User data
  - `{:error, :not_found}` - User not found
  """
  @spec get_user(integer()) :: {:ok, User.t()} | {:error, :not_found}
  def get_user(id) do
    case Repo.get(User, id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  @doc """
  Creates a new user.

  ## Parameters

  - `attrs` - User attributes

  ## Returns

  - `{:ok, user}` - Created user
  - `{:error, changeset}` - Validation errors
  """
  @spec create_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing user.

  ## Parameters

  - `id` - User ID
  - `attrs` - Updated attributes

  ## Returns

  - `{:ok, user}` - Updated user
  - `{:error, :not_found}` - User not found
  - `{:error, changeset}` - Validation errors
  """
  @spec update_user(integer(), map()) ::
          {:ok, User.t()} | {:error, :not_found | Ecto.Changeset.t()}
  def update_user(id, attrs) do
    case Repo.get(User, id) do
      nil ->
        {:error, :not_found}

      user ->
        user
        |> User.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Deletes a user.

  ## Parameters

  - `id` - User ID

  ## Returns

  - `:ok` - Successfully deleted
  - `{:error, :not_found}` - User not found
  """
  @spec delete_user(integer()) :: :ok | {:error, :not_found}
  def delete_user(id) do
    case Repo.get(User, id) do
      nil ->
        {:error, :not_found}

      user ->
        Repo.delete(user)
        :ok
    end
  end

  # Private helper functions for query building

  defp build_query(params) do
    User
    |> filter_by_first_name(params[:first_name])
    |> filter_by_last_name(params[:last_name])
    |> filter_by_gender(params[:gender])
    |> filter_by_birthdate_from(params[:birthdate_from])
    |> filter_by_birthdate_to(params[:birthdate_to])
    |> apply_sorting(params[:sort], params[:order])
  end

  defp filter_by_first_name(query, nil), do: query

  defp filter_by_first_name(query, first_name) do
    where(query, [p], ilike(p.first_name, ^"%#{first_name}%"))
  end

  defp filter_by_last_name(query, nil), do: query

  defp filter_by_last_name(query, last_name) do
    where(query, [p], ilike(p.last_name, ^"%#{last_name}%"))
  end

  defp filter_by_gender(query, nil), do: query

  defp filter_by_gender(query, gender) do
    where(query, [p], p.gender == ^gender)
  end

  defp filter_by_birthdate_from(query, nil), do: query

  defp filter_by_birthdate_from(query, from_date = %Date{}) do
    where(query, [p], p.birthdate >= ^from_date)
  end

  defp filter_by_birthdate_to(query, nil), do: query

  defp filter_by_birthdate_to(query, to_date = %Date{}) do
    where(query, [p], p.birthdate <= ^to_date)
  end

  defp apply_sorting(query, nil, _), do: order_by(query, [p], asc: p.id)

  defp apply_sorting(query, sort_field, order) do
    case sort_field do
      :first_name -> order_by(query, [p], [{^order, p.first_name}])
      :last_name -> order_by(query, [p], [{^order, p.last_name}])
      :gender -> order_by(query, [p], [{^order, p.gender}])
      :birthdate -> order_by(query, [p], [{^order, p.birthdate}])
      _ -> order_by(query, [p], asc: p.id)
    end
  end
end
