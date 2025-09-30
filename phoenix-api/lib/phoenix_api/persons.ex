defmodule PhoenixApi.Persons do
  @moduledoc """
  Module for importing and generating random person data.

  This module provides functionality to fetch names from external APIs
  and generate random persons with birth dates within specified ranges.
  """

  alias PhoenixApi.ApiClient
  alias PhoenixApi.RandomNamesGenerator
  alias PhoenixApi.Repo
  alias PhoenixApi.Schemas.Person

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

  # Default values
  @default_birth_date_from ~D[1970-01-01]
  @default_birth_date_to ~D[2024-12-31]
  @default_count 100
  @default_top 100

  @doc """
  Imports names from external APIs and saves random persons to the database.

  ## Parameters

  - `params` - A map containing:
    - `urls` - Map with URLs for male and female first/last names
    - `birth_date_from` - Start date for birth date range (optional, defaults to #{@default_birth_date_from})
    - `birth_date_to` - End date for birth date range (optional, defaults to #{@default_birth_date_to})
    - `count` - Number of persons to generate (optional, defaults to #{@default_count})
    - `top` - Number of names to fetch from each URL (optional, defaults to #{@default_top})

  ## Returns

  - `{:ok, count}` - Number of persons successfully saved to database
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
      iex> PhoenixApi.Persons.import(params)
      {:ok, 5}

  """
  @spec import(map()) :: {:ok, non_neg_integer()} | {:error, any()}
  def import(params) do
    with {:ok, processed_params} <- process_params(params),
         {:ok, names} <- fetch_names(processed_params),
         {:ok, count} <- save_persons(names, processed_params) do
      {:ok, count}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec process_params(map()) :: {:ok, import_params()} | {:error, atom()}
  defp process_params(params) do
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
    config = Application.get_env(:phoenix_api, :person)

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

  @spec save_persons(map(), import_params()) :: {:ok, non_neg_integer()} | {:error, any()}
  defp save_persons(names, params) do
    birth_date_range = Date.range(params.birth_date_from, params.birth_date_to)
    generated_persons = RandomNamesGenerator.call(names, birth_date_range, params.count)

    # Convert generated persons to data for insert_all
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    person_data =
      Enum.map(generated_persons, fn person ->
        %{
          first_name: person.first_name,
          last_name: person.last_name,
          gender: person.gender,
          birthdate: person.birth_date,
          inserted_at: now,
          updated_at: now
        }
      end)

    case Repo.insert_all(Person, person_data) do
      {count, _} -> {:ok, count}
    end
  end
end
