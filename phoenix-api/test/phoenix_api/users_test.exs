defmodule PhoenixApi.UsersTest do
  use ExUnit.Case, async: false
  import Mimic

  alias PhoenixApi.Users
  alias PhoenixApi.ApiClient
  alias PhoenixApi.Repo
  alias PhoenixApi.Schemas.User, as: UserSchema

  @config Application.compile_env(:phoenix_api, :import, [])
  @male_first_name_url @config[:male_first_name_url]
  @male_last_name_url @config[:male_last_name_url]
  @female_first_name_url @config[:female_first_name_url]
  @female_last_name_url @config[:female_last_name_url]

  setup :verify_on_exit!

  setup do
    # Setup database sandbox
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(PhoenixApi.Repo)

    # Clean up database before each test
    Repo.delete_all(UserSchema)
    :ok
  end

  describe "import/1" do
    test "successfully imports and generates users with all parameters provided" do
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

      assert {:ok, count} = Users.import(params)
      assert count == 3

      # Check that users were saved to database
      saved_users = Repo.all(UserSchema)
      assert length(saved_users) == 3

      # Check structure of saved users
      for user <- saved_users do
        assert user.gender in [:male, :female]
        assert is_binary(user.first_name)
        assert is_binary(user.last_name)
        assert %Date{} = user.birthdate

        # Check that birth date is within range
        assert Date.compare(user.birthdate, ~D[1990-01-01]) != :lt
        assert Date.compare(user.birthdate, ~D[2000-12-31]) != :gt
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

      assert {:ok, count} = Users.import(params)
      # default count
      assert count == 100

      # Check that users were saved to database
      saved_users = Repo.all(UserSchema)
      assert length(saved_users) == 100

      # Check that birth dates are within default range
      for user <- saved_users do
        assert Date.compare(user.birthdate, ~D[1970-01-01]) != :lt
        assert Date.compare(user.birthdate, ~D[2024-12-31]) != :gt
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

      assert {:ok, count} = Users.import(params)
      assert count == 2

      # Check that users were saved to database
      saved_users = Repo.all(UserSchema)
      assert length(saved_users) == 2
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

      assert {:error, :invalid_date_range} = Users.import(params)
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

      assert {:error, :invalid_url} = Users.import(params)
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

      assert {:ok, count} = Users.import(params)
      assert count == 0

      # Check that no users were saved to database
      saved_users = Repo.all(UserSchema)
      assert Enum.empty?(saved_users)
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

      assert {:ok, count} = Users.import(params)
      assert count == 1

      # Check that users were saved to database
      saved_users = Repo.all(UserSchema)
      assert length(saved_users) == 1
    end

    test "validates that generated users have correct names based on gender" do
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

      assert {:ok, count} = Users.import(params)
      assert count == 100

      # Check that users were saved to database
      saved_users = Repo.all(UserSchema)
      assert length(saved_users) == 100

      # Check that male users have male names
      male_users = Enum.filter(saved_users, &(&1.gender == :male))

      for male <- male_users do
        assert male.first_name in ["JAN", "PIOTR", "STANISŁAW", "ANDRZEJ", "PAWEŁ"]
        assert male.last_name in ["KOWALSKI", "NOWAK", "WIŚNIEWSKI", "WÓJCIK", "KOWALCZYK"]
      end

      # Check that female users have female names
      female_users = Enum.filter(saved_users, &(&1.gender == :female))

      for female <- female_users do
        assert female.first_name in ["ANNA", "MARIA", "KRYSTYNA", "BARBARA", "DANUTA"]
        assert female.last_name in ["KOWALSKA", "NOWAK", "WIŚNIEWSKA", "WÓJCIK", "KOWALCZYK"]
      end
    end

    @tag :external
    test "successfully imports users using real API endpoints" do
      params = %{
        count: 5,
        top: 10
      }

      assert {:ok, count} = Users.import(params)
      assert count == 5

      # Check that users were saved to database
      saved_users = Repo.all(UserSchema)
      assert length(saved_users) == 5

      # Verify that all saved users have valid data
      for user <- saved_users do
        assert user.gender in [:male, :female]
        assert is_binary(user.first_name)
        assert is_binary(user.last_name)
        assert %Date{} = user.birthdate
        assert String.length(user.first_name) > 0
        assert String.length(user.last_name) > 0
      end
    end
  end

  describe "list_users" do
    test "returns empty list when no users exist" do
      {:ok, result} = Users.list_users(%{})

      assert result == []
    end

    test "returns list of users" do
      # Create test users
      _users = create_test_users(5)

      {:ok, result} = Users.list_users(%{})

      assert length(result) == 5
    end

    test "filters by first_name" do
      create_test_users([
        %{first_name: "John", last_name: "Doe", gender: :male, birthdate: ~D[1990-01-01]},
        %{first_name: "Jane", last_name: "Smith", gender: :female, birthdate: ~D[1995-05-15]},
        %{first_name: "Johnny", last_name: "Walker", gender: :male, birthdate: ~D[1985-12-10]}
      ])

      {:ok, result} = Users.list_users(%{first_name: "John"})

      assert length(result) == 2
      assert Enum.all?(result, fn user -> String.contains?(user.first_name, "John") end)
    end

    test "filters by part of first_name" do
      create_test_users([
        %{first_name: "John", last_name: "Doe", gender: :male, birthdate: ~D[1990-01-01]},
        %{first_name: "Jane", last_name: "Smith", gender: :female, birthdate: ~D[1995-05-15]},
        %{first_name: "Johnny", last_name: "Walker", gender: :male, birthdate: ~D[1985-12-10]}
      ])

      {:ok, result} = Users.list_users(%{first_name: "ohn"})

      assert length(result) == 2
      assert Enum.all?(result, fn user -> String.contains?(user.first_name, "ohn") end)
    end

    test "filters by last_name" do
      create_test_users([
        %{first_name: "John", last_name: "Doe", gender: :male, birthdate: ~D[1990-01-01]},
        %{first_name: "Jane", last_name: "Smith", gender: :female, birthdate: ~D[1995-05-15]},
        %{first_name: "Bob", last_name: "Smith", gender: :male, birthdate: ~D[1985-12-10]}
      ])

      {:ok, result} = Users.list_users(%{last_name: "Smith"})

      assert length(result) == 2
      assert Enum.all?(result, fn user -> String.contains?(user.last_name, "Smith") end)
    end

    test "filters by gender" do
      create_test_users([
        %{first_name: "John", last_name: "Doe", gender: :male, birthdate: ~D[1990-01-01]},
        %{first_name: "Jane", last_name: "Smith", gender: :female, birthdate: ~D[1995-05-15]},
        %{first_name: "Bob", last_name: "Johnson", gender: :male, birthdate: ~D[1985-12-10]}
      ])

      {:ok, result} = Users.list_users(%{gender: :female})

      assert length(result) == 1
      assert hd(result).gender == :female
    end

    test "filters by birthdate range" do
      create_test_users([
        %{first_name: "John", last_name: "Doe", gender: :male, birthdate: ~D[1990-01-01]},
        %{first_name: "Jane", last_name: "Smith", gender: :female, birthdate: ~D[1995-05-15]},
        %{first_name: "Bob", last_name: "Johnson", gender: :male, birthdate: ~D[2000-12-10]}
      ])

      {:ok, result} =
        Users.list_users(%{
          birthdate_from: ~D[1990-01-01],
          birthdate_to: ~D[1999-12-31]
        })

      assert length(result) == 2
    end

    test "sorts by first_name ascending" do
      create_test_users([
        %{first_name: "Charlie", last_name: "Brown", gender: :male, birthdate: ~D[1990-01-01]},
        %{first_name: "Alice", last_name: "Smith", gender: :female, birthdate: ~D[1995-05-15]},
        %{first_name: "Bob", last_name: "Johnson", gender: :male, birthdate: ~D[1985-12-10]}
      ])

      {:ok, result} = Users.list_users(%{sort: :first_name, order: :asc})

      first_names = Enum.map(result, & &1.first_name)
      assert first_names == ["Alice", "Bob", "Charlie"]
    end

    test "sorts by first_name honoring polish letters" do
      create_test_users([
        %{first_name: "Łukasz", last_name: "Zdun", gender: :male, birthdate: ~D[1995-05-15]},
        %{first_name: "Manfred", last_name: "Szewc", gender: :male, birthdate: ~D[1985-12-10]},
        %{first_name: "Leon", last_name: "Kowal", gender: :male, birthdate: ~D[1990-01-01]}
      ])

      {:ok, result} = Users.list_users(%{sort: :first_name, order: :asc})

      first_names = Enum.map(result, & &1.first_name)
      assert first_names == ["Leon", "Łukasz", "Manfred"]
    end

    test "sorts by birthdate descending" do
      create_test_users([
        %{first_name: "John", last_name: "Doe", gender: :male, birthdate: ~D[1990-01-01]},
        %{first_name: "Jane", last_name: "Smith", gender: :female, birthdate: ~D[1995-05-15]},
        %{first_name: "Bob", last_name: "Johnson", gender: :male, birthdate: ~D[1985-12-10]}
      ])

      {:ok, result} = Users.list_users(%{sort: :birthdate, order: :desc})

      birthdates = Enum.map(result, & &1.birthdate)
      assert birthdates == [~D[1995-05-15], ~D[1990-01-01], ~D[1985-12-10]]
    end
  end

  describe "get_user" do
    test "returns user when found" do
      user =
        create_test_user(%{
          first_name: "John",
          last_name: "Doe",
          gender: :male,
          birthdate: ~D[1990-01-01]
        })

      {:ok, result} = Users.get_user(user.id)

      assert result.id == user.id
      assert result.first_name == "John"
      assert result.last_name == "Doe"
      assert result.gender == :male
      assert result.birthdate == ~D[1990-01-01]
    end

    test "returns error when user not found" do
      assert {:error, :not_found} = Users.get_user(999_999)
    end
  end

  describe "create_user" do
    test "creates user with valid data" do
      attrs = %{
        first_name: "John",
        last_name: "Doe",
        gender: :male,
        birthdate: ~D[1990-01-01]
      }

      {:ok, user} = Users.create_user(attrs)

      assert user.first_name == "John"
      assert user.last_name == "Doe"
      assert user.gender == :male
      assert user.birthdate == ~D[1990-01-01]
      assert user.id
    end

    test "returns validation errors for invalid data" do
      attrs = %{
        first_name: "",
        last_name: "",
        gender: :male,
        # Invalid date format
        birthdate: "invalid-date"
      }

      {:error, changeset} = Users.create_user(attrs)

      assert changeset.errors[:first_name]
      assert changeset.errors[:last_name]
      assert changeset.errors[:birthdate]
    end

    test "returns validation errors for missing required fields" do
      {:error, changeset} = Users.create_user(%{})

      assert changeset.errors[:first_name]
      assert changeset.errors[:last_name]
      assert changeset.errors[:gender]
      assert changeset.errors[:birthdate]
    end
  end

  describe "update_user" do
    test "updates user with valid data" do
      user =
        create_test_user(%{
          first_name: "John",
          last_name: "Doe",
          gender: :male,
          birthdate: ~D[1990-01-01]
        })

      attrs = %{
        "first_name" => "Jane",
        "last_name" => "Smith",
        "gender" => "female",
        "birthdate" => "1995-05-15"
      }

      {:ok, updated_user} = Users.update_user(user.id, attrs)

      assert updated_user.id == user.id
      assert updated_user.first_name == "Jane"
      assert updated_user.last_name == "Smith"
      assert updated_user.gender == :female
      assert updated_user.birthdate == ~D[1995-05-15]
    end

    test "returns error when user not found" do
      attrs = %{
        first_name: "Jane",
        last_name: "Smith"
      }

      assert {:error, :not_found} = Users.update_user(999_999, attrs)
    end

    test "returns validation errors for invalid data" do
      user =
        create_test_user(%{
          first_name: "John",
          last_name: "Doe",
          gender: :male,
          birthdate: ~D[1990-01-01]
        })

      invalid_attrs = %{
        first_name: "",
        last_name: "",
        gender: :male,
        # Invalid date format
        birthdate: "invalid-date"
      }

      {:error, changeset} = Users.update_user(user.id, invalid_attrs)

      assert changeset.errors[:first_name]
      assert changeset.errors[:last_name]
      assert changeset.errors[:birthdate]
    end
  end

  describe "delete_user" do
    test "deletes user when found" do
      user =
        create_test_user(%{
          first_name: "John",
          last_name: "Doe",
          gender: :male,
          birthdate: ~D[1990-01-01]
        })

      assert :ok = Users.delete_user(user.id)
      assert {:error, :not_found} = Users.get_user(user.id)
    end

    test "returns error when user not found" do
      assert {:error, :not_found} = Users.delete_user(999_999)
    end
  end

  # Helper functions for CRUD tests

  defp create_test_user(attrs) do
    default_attrs = %{
      first_name: "Test",
      last_name: "User",
      gender: :male,
      birthdate: ~D[1990-01-01]
    }

    attrs = Map.merge(default_attrs, attrs)

    %UserSchema{}
    |> UserSchema.changeset(attrs)
    |> Repo.insert!()
  end

  defp create_test_users(count) when is_integer(count) do
    for i <- 1..count do
      create_test_user(%{
        first_name: "User#{i}",
        last_name: "LastName#{i}",
        gender: if(rem(i, 2) == 0, do: :female, else: :male),
        birthdate: Date.add(~D[1990-01-01], i)
      })
    end
  end

  defp create_test_users(users_list) when is_list(users_list) do
    Enum.map(users_list, &create_test_user/1)
  end
end
