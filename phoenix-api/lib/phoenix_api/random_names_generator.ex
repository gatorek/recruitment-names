defmodule PhoenixApi.RandomNamesGenerator do
  @moduledoc """
  Module for generating random names with birth dates.

  This module provides functionality to generate random combinations of first names,
  last names, genders, and birth dates based on provided parameters.
  """

  @type names_map :: %{
          male_first_names: [String.t()],
          male_last_names: [String.t()],
          female_first_names: [String.t()],
          female_last_names: [String.t()]
        }

  @type generated_person :: %{
          gender: :male | :female,
          first_name: String.t(),
          last_name: String.t(),
          birth_date: Date.t()
        }

  @typep gender :: :male | :female

  @genders ~w(male female)a

  @doc """
  Generates a list of random names with birth dates.

  ## Parameters

  - `names` - A map containing lists of male and female first and last names
  - `birth_date_range` - A Date.Range struct defining the range of possible birth dates
  - `count` - The number of generated persons to return

  ## Returns

  A list of maps containing gender, first_name, last_name, and birth_date.

  ## Examples

      iex> names = %{
      ...>   male_first_names: ["adam", "stefan"],
      ...>   male_last_names: ["kowalski", "nowak"],
      ...>   female_first_names: ["anna", "ewa"],
      ...>   female_last_names: ["kowalska", "nowak"]
      ...> }
      iex> date_range = Date.range(~D[1990-01-01], ~D[2000-12-31])
      iex> PhoenixApi.RandomNamesGenerator.call(names, date_range, 2)
      [
        %{gender: :male, first_name: "adam", last_name: "kowalski", birth_date: ~D[1995-06-15]},
        %{gender: :female, first_name: "anna", last_name: "nowak", birth_date: ~D[1992-03-22]}
      ]
  """
  @spec call(names_map(), Date.Range.t(), non_neg_integer()) :: [generated_person()]
  def call(_names, _birth_date_range, 0) do
    []
  end

  def call(names, birth_date_range, count) when count > 0 do
    1..count
    |> Enum.map(fn _ -> generate_random_person(names, birth_date_range) end)
  end

  @spec generate_random_person(names_map(), Date.Range.t()) :: generated_person()
  defp generate_random_person(names, birth_date_range) do
    gender = random_gender()
    first_name = random_first_name(names, gender)
    last_name = random_last_name(names, gender)
    birth_date = random_birth_date(birth_date_range)

    %{
      gender: gender,
      first_name: first_name,
      last_name: last_name,
      birth_date: birth_date
    }
  end

  @spec random_gender() :: gender()
  defp random_gender do
    Enum.random(@genders)
  end

  @spec random_first_name(names_map(), gender()) :: String.t()
  defp random_first_name(names, :male) do
    Enum.random(names.male_first_names)
  end

  defp random_first_name(names, :female) do
    Enum.random(names.female_first_names)
  end

  @spec random_last_name(names_map(), gender()) :: String.t()
  defp random_last_name(names, :male) do
    Enum.random(names.male_last_names)
  end

  defp random_last_name(names, :female) do
    Enum.random(names.female_last_names)
  end

  @spec random_birth_date(Date.Range.t()) :: Date.t()
  defp random_birth_date(date_range) do
    Enum.random(date_range)
  end
end
