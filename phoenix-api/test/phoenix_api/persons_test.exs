defmodule PhoenixApi.PersonsTest do
  use ExUnit.Case, async: false
  import Mimic

  alias PhoenixApi.Persons, as: Person
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

  describe "import/1" do
    test "successfully imports and generates persons with all parameters provided" do
      # Mock ApiClient calls
      stub(ApiClient, :call, fn url, _count ->
        case url do
          "https://example.com/male-first.csv" ->
            {:ok, ["JAN", "PIOTR", "STANISŁAW", "ANDRZEJ", "PAWEŁ"]}

          "https://example.com/male-last.csv" ->
            {:ok, ["KOWALSKI", "NOWAK", "WIŚNIEWSKI", "WÓJCIK", "KOWALCZYK"]}

          "https://example.com/female-first.csv" ->
            {:ok, ["ANNA", "MARIA", "KRYSTYNA", "BARBARA", "DANUTA"]}

          "https://example.com/female-last.csv" ->
            {:ok, ["KOWALSKA", "NOWAK", "WIŚNIEWSKA", "WÓJCIK", "KOWALCZYK"]}

          _ ->
            {:error, :invalid_url}
        end
      end)

      params = %{
        urls: %{
          male: %{
            first_name: "https://example.com/male-first.csv",
            last_name: "https://example.com/male-last.csv"
          },
          female: %{
            first_name: "https://example.com/female-first.csv",
            last_name: "https://example.com/female-last.csv"
          }
        },
        birth_date_from: ~D[1990-01-01],
        birth_date_to: ~D[2000-12-31],
        count: 3,
        top: 5
      }

      assert {:ok, count} = Person.import(params)
      assert count == 3

      # Check that persons were saved to database
      saved_persons = Repo.all(PersonSchema)
      assert length(saved_persons) == 3

      # Check structure of saved persons
      for person <- saved_persons do
        assert person.gender in [:male, :female]
        assert is_binary(person.first_name)
        assert is_binary(person.last_name)
        assert %Date{} = person.birthdate

        # Check that birth date is within range
        assert Date.compare(person.birthdate, ~D[1990-01-01]) != :lt
        assert Date.compare(person.birthdate, ~D[2000-12-31]) != :gt
      end
    end

    test "uses default values when parameters are missing" do
      # Mock ApiClient calls
      stub(ApiClient, :call, fn url, count ->
        # Should use the default count
        assert count == 100

        case url do
          "https://example.com/male-first.csv" ->
            {:ok, ["JAN", "PIOTR", "STANISŁAW", "ANDRZEJ", "PAWEŁ"]}

          "https://example.com/male-last.csv" ->
            {:ok, ["KOWALSKI", "NOWAK", "WIŚNIEWSKI", "WÓJCIK", "KOWALCZYK"]}

          "https://example.com/female-first.csv" ->
            {:ok, ["ANNA", "MARIA", "KRYSTYNA", "BARBARA", "DANUTA"]}

          "https://example.com/female-last.csv" ->
            {:ok, ["KOWALSKA", "NOWAK", "WIŚNIEWSKA", "WÓJCIK", "KOWALCZYK"]}

          _ ->
            {:error, :invalid_url}
        end
      end)

      params = %{
        urls: %{
          male: %{
            first_name: "https://example.com/male-first.csv",
            last_name: "https://example.com/male-last.csv"
          },
          female: %{
            first_name: "https://example.com/female-first.csv",
            last_name: "https://example.com/female-last.csv"
          }
        }
      }

      assert {:ok, count} = Person.import(params)
      # default count
      assert count == 100

      # Check that persons were saved to database
      saved_persons = Repo.all(PersonSchema)
      assert length(saved_persons) == 100

      # Check that birth dates are within default range
      for person <- saved_persons do
        assert Date.compare(person.birthdate, ~D[1970-01-01]) != :lt
        assert Date.compare(person.birthdate, ~D[2024-12-31]) != :gt
      end
    end

    test "uses default URLs when urls parameter is missing" do
      # Mock default URLs
      stub(ApiClient, :call, fn url, _count ->
        case url do
          url
          when url in [
                 @male_first_name_url,
                 @male_last_name_url,
                 @female_first_name_url,
                 @female_last_name_url
               ] ->
            {:ok, ["NAME1", "NAME2", "NAME3"]}

          _ ->
            {:error, :invalid_url}
        end
      end)

      params = %{
        count: 2,
        top: 3
      }

      assert {:ok, count} = Person.import(params)
      assert count == 2

      # Check that persons were saved to database
      saved_persons = Repo.all(PersonSchema)
      assert length(saved_persons) == 2
    end

    test "returns error when birth_date_from is after birth_date_to" do
      # Mock ApiClient calls
      stub(ApiClient, :call, fn url, _count ->
        case url do
          "https://example.com/male-first.csv" ->
            {:ok, ["JAN", "PIOTR", "STANISŁAW", "ANDRZEJ", "PAWEŁ"]}

          "https://example.com/male-last.csv" ->
            {:ok, ["KOWALSKI", "NOWAK", "WIŚNIEWSKI", "WÓJCIK", "KOWALCZYK"]}

          "https://example.com/female-first.csv" ->
            {:ok, ["ANNA", "MARIA", "KRYSTYNA", "BARBARA", "DANUTA"]}

          "https://example.com/female-last.csv" ->
            {:ok, ["KOWALSKA", "NOWAK", "WIŚNIEWSKA", "WÓJCIK", "KOWALCZYK"]}

          _ ->
            {:error, :invalid_url}
        end
      end)

      params = %{
        urls: %{
          male: %{
            first_name: "https://example.com/male-first.csv",
            last_name: "https://example.com/male-last.csv"
          },
          female: %{
            first_name: "https://example.com/female-first.csv",
            last_name: "https://example.com/female-last.csv"
          }
        },
        birth_date_from: ~D[2000-01-01],
        birth_date_to: ~D[1990-12-31],
        count: 1,
        top: 1
      }

      assert {:error, :invalid_date_range} = Person.import(params)
    end

    test "returns error when ApiClient fails" do
      # Mock ApiClient to return error for invalid URL
      stub(ApiClient, :call, fn url, _count ->
        case url do
          "https://invalid-url.com/male-first.csv" ->
            {:error, :invalid_url}

          _ ->
            {:ok, ["NAME"]}
        end
      end)

      params = %{
        urls: %{
          male: %{
            first_name: "https://invalid-url.com/male-first.csv",
            last_name: "https://example.com/male-last.csv"
          },
          female: %{
            first_name: "https://example.com/female-first.csv",
            last_name: "https://example.com/female-last.csv"
          }
        },
        count: 1,
        top: 1
      }

      assert {:error, :invalid_url} = Person.import(params)
    end

    test "generates empty list when count is 0" do
      # Mock ApiClient calls
      stub(ApiClient, :call, fn url, _count ->
        case url do
          "https://example.com/male-first.csv" ->
            {:ok, ["JAN", "PIOTR", "STANISŁAW", "ANDRZEJ", "PAWEŁ"]}

          "https://example.com/male-last.csv" ->
            {:ok, ["KOWALSKI", "NOWAK", "WIŚNIEWSKI", "WÓJCIK", "KOWALCZYK"]}

          "https://example.com/female-first.csv" ->
            {:ok, ["ANNA", "MARIA", "KRYSTYNA", "BARBARA", "DANUTA"]}

          "https://example.com/female-last.csv" ->
            {:ok, ["KOWALSKA", "NOWAK", "WIŚNIEWSKA", "WÓJCIK", "KOWALCZYK"]}

          _ ->
            {:error, :invalid_url}
        end
      end)

      params = %{
        urls: %{
          male: %{
            first_name: "https://example.com/male-first.csv",
            last_name: "https://example.com/male-last.csv"
          },
          female: %{
            first_name: "https://example.com/female-first.csv",
            last_name: "https://example.com/female-last.csv"
          }
        },
        count: 0,
        top: 1
      }

      assert {:ok, count} = Person.import(params)
      assert count == 0

      # Check that no persons were saved to database
      saved_persons = Repo.all(PersonSchema)
      assert Enum.empty?(saved_persons)
    end

    test "handles partial URL configuration" do
      # Mock both provided and default URLs
      stub(ApiClient, :call, fn url, _count ->
        case url do
          "https://example.com/male-first.csv" ->
            {:ok, ["JAN"]}

          "https://example.com/female-last.csv" ->
            {:ok, ["KOWALSKA"]}

          url
          when url in [
                 @male_last_name_url,
                 @female_first_name_url
               ] ->
            {:ok, ["NAME"]}

          _ ->
            {:error, :invalid_url}
        end
      end)

      params = %{
        urls: %{
          male: %{
            first_name: "https://example.com/male-first.csv"
            # last_name missing - should use default
          },
          female: %{
            # first_name missing - should use default
            last_name: "https://example.com/female-last.csv"
          }
        },
        count: 1,
        top: 1
      }

      assert {:ok, count} = Person.import(params)
      assert count == 1

      # Check that persons were saved to database
      saved_persons = Repo.all(PersonSchema)
      assert length(saved_persons) == 1
    end

    test "validates that generated persons have correct names based on gender" do
      # Mock ApiClient calls
      stub(ApiClient, :call, fn url, _count ->
        case url do
          "https://example.com/male-first.csv" ->
            {:ok, ["JAN", "PIOTR", "STANISŁAW", "ANDRZEJ", "PAWEŁ"]}

          "https://example.com/male-last.csv" ->
            {:ok, ["KOWALSKI", "NOWAK", "WIŚNIEWSKI", "WÓJCIK", "KOWALCZYK"]}

          "https://example.com/female-first.csv" ->
            {:ok, ["ANNA", "MARIA", "KRYSTYNA", "BARBARA", "DANUTA"]}

          "https://example.com/female-last.csv" ->
            {:ok, ["KOWALSKA", "NOWAK", "WIŚNIEWSKA", "WÓJCIK", "KOWALCZYK"]}

          _ ->
            {:error, :invalid_url}
        end
      end)

      params = %{
        urls: %{
          male: %{
            first_name: "https://example.com/male-first.csv",
            last_name: "https://example.com/male-last.csv"
          },
          female: %{
            first_name: "https://example.com/female-first.csv",
            last_name: "https://example.com/female-last.csv"
          }
        },
        # Generate many to increase chance of getting both genders
        count: 100,
        top: 5
      }

      assert {:ok, count} = Person.import(params)
      assert count == 100

      # Check that persons were saved to database
      saved_persons = Repo.all(PersonSchema)
      assert length(saved_persons) == 100

      # Check that male persons have male names
      male_persons = Enum.filter(saved_persons, &(&1.gender == :male))

      for male <- male_persons do
        assert male.first_name in ["JAN", "PIOTR", "STANISŁAW", "ANDRZEJ", "PAWEŁ"]
        assert male.last_name in ["KOWALSKI", "NOWAK", "WIŚNIEWSKI", "WÓJCIK", "KOWALCZYK"]
      end

      # Check that female persons have female names
      female_persons = Enum.filter(saved_persons, &(&1.gender == :female))

      for female <- female_persons do
        assert female.first_name in ["ANNA", "MARIA", "KRYSTYNA", "BARBARA", "DANUTA"]
        assert female.last_name in ["KOWALSKA", "NOWAK", "WIŚNIEWSKA", "WÓJCIK", "KOWALCZYK"]
      end
    end

    @tag :skip
    test "successfully imports persons using real API endpoints" do
      params = %{
        count: 5,
        top: 10
      }

      assert {:ok, count} = Person.import(params)
      assert count == 5

      # Check that persons were saved to database
      saved_persons = Repo.all(PersonSchema)
      assert length(saved_persons) == 5

      # Verify that all saved persons have valid data
      for person <- saved_persons do
        assert person.gender in [:male, :female]
        assert is_binary(person.first_name)
        assert is_binary(person.last_name)
        assert %Date{} = person.birthdate
        assert String.length(person.first_name) > 0
        assert String.length(person.last_name) > 0
      end
    end
  end
end
