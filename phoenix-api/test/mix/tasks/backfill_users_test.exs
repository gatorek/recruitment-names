defmodule Mix.Tasks.BackfillUsersTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  alias PhoenixApi.Repo
  alias PhoenixApi.Schemas.Person
  alias PhoenixApi.Schemas.User

  setup do
    # Setup database sandbox
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(PhoenixApi.Repo)

    # Clean up database before each test
    Repo.delete_all(User)
    Repo.delete_all(Person)

    :ok
  end

  describe "run/1" do
    test "successfully backfills users from persons with default batch size" do
      # Create test persons
      persons = create_test_persons(5)

      # Capture output
      output =
        capture_io(fn ->
          Mix.Tasks.BackfillUsers.run([])
        end)

      # Verify output contains expected messages
      assert output =~ "Starting backfill process..."
      assert output =~ "Batch size: 1000"
      assert output =~ "Total persons to process: 5"
      assert output =~ "Processing batch: 1-5 of 5"
      assert output =~ "Inserted 5 users"
      assert output =~ "Backfill completed!"
      assert output =~ "Processed 5 records"
      assert output =~ "Final user count: 5"

      # Verify users were created
      users = Repo.all(User)
      assert length(users) == 5

      # Verify data integrity
      for {person, user} <- Enum.zip(persons, users) do
        assert user.first_name == person.first_name
        assert user.last_name == person.last_name
        assert user.gender == person.gender
        assert user.birthdate == person.birthdate
        assert user.inserted_at == person.inserted_at
        assert user.updated_at == person.updated_at
      end
    end

    test "successfully backfills users with custom batch size" do
      # Create test persons
      _persons = create_test_persons(3)

      # Capture output
      output =
        capture_io(fn ->
          Mix.Tasks.BackfillUsers.run(["--batch-size", "2"])
        end)

      # Verify output contains expected messages
      assert output =~ "Batch size: 2"
      assert output =~ "Total persons to process: 3"
      assert output =~ "Processing batch: 1-2 of 3"
      assert output =~ "Inserted 2 users"
      assert output =~ "Processing batch: 3-3 of 3"
      assert output =~ "Inserted 1 users"
      assert output =~ "Backfill completed!"

      # Verify users were created
      users = Repo.all(User)
      assert length(users) == 3
    end

    test "successfully backfills users with batch size alias" do
      # Create test persons
      _persons = create_test_persons(2)

      # Capture output
      output =
        capture_io(fn ->
          Mix.Tasks.BackfillUsers.run(["-b", "1"])
        end)

      # Verify output contains expected messages
      assert output =~ "Batch size: 1"
      assert output =~ "Total persons to process: 2"
      assert output =~ "Processing batch: 1-1 of 2"
      assert output =~ "Inserted 1 users"
      assert output =~ "Processing batch: 2-2 of 2"
      assert output =~ "Inserted 1 users"

      # Verify users were created
      users = Repo.all(User)
      assert length(users) == 2
    end

    test "dry run mode shows what would be done without actually doing it" do
      # Create test persons
      _persons = create_test_persons(3)

      # Capture output
      output =
        capture_io(fn ->
          Mix.Tasks.BackfillUsers.run(["--dry-run"])
        end)

      # Verify output contains expected messages
      assert output =~ "DRY RUN MODE - No data will be modified"
      assert output =~ "Starting backfill process..."
      assert output =~ "Total persons to process: 3"
      assert output =~ "Processing batch: 1-3 of 3"
      assert output =~ "Would insert 3 users"
      assert output =~ "Backfill completed!"
      assert output =~ "Processed 3 records"

      # Verify no users were actually created
      users = Repo.all(User)
      assert length(users) == 0
    end

    test "handles empty persons table gracefully" do
      # Capture output
      output =
        capture_io(fn ->
          Mix.Tasks.BackfillUsers.run([])
        end)

      # Verify output contains expected messages
      assert output =~ "Starting backfill process..."
      assert output =~ "Total persons to process: 0"
      assert output =~ "No persons found to backfill"

      # Verify no users were created
      users = Repo.all(User)
      assert length(users) == 0
    end

    test "aborts backfill when users table is not empty" do
      # Create some persons to backfill
      _persons = create_test_persons(3)

      # Create some existing users
      existing_users = [
        %{
          first_name: "Existing",
          last_name: "User1",
          gender: :male,
          birthdate: ~D[1990-01-01]
        },
        %{
          first_name: "Existing",
          last_name: "User2",
          gender: :female,
          birthdate: ~D[1985-05-15]
        }
      ]

      Enum.each(existing_users, fn attrs ->
        %User{}
        |> User.changeset(attrs)
        |> Repo.insert!()
      end)

      # Capture output and expect exception
      output =
        capture_io(fn ->
          assert_raise RuntimeError, "Users table is not empty, backfill aborted", fn ->
            Mix.Tasks.BackfillUsers.run([])
          end
        end)

      # Verify output contains expected messages
      assert output =~ "Starting backfill process..."
      assert output =~ "Total persons to process: 3"
      assert output =~ "Users table is not empty (2 records found)"
      assert output =~ "Backfill aborted to prevent data duplication"

      # Verify no additional users were created
      users = Repo.all(User)
      # Only the existing users
      assert length(users) == 2
    end

    test "aborts backfill when users table is not empty (dry run)" do
      # Create some persons to backfill
      _persons = create_test_persons(2)

      # Create some existing users
      existing_user = %{
        first_name: "Existing",
        last_name: "User",
        gender: :male,
        birthdate: ~D[1990-01-01]
      }

      %User{}
      |> User.changeset(existing_user)
      |> Repo.insert!()

      # Capture output and expect exception
      output =
        capture_io(fn ->
          assert_raise RuntimeError, "Users table is not empty, backfill aborted", fn ->
            Mix.Tasks.BackfillUsers.run(["--dry-run"])
          end
        end)

      # Verify output contains expected messages
      assert output =~ "DRY RUN MODE - No data will be modified"
      assert output =~ "Starting backfill process..."
      assert output =~ "Total persons to process: 2"
      assert output =~ "Users table is not empty (1 records found)"
      assert output =~ "Backfill aborted to prevent data duplication"

      # Verify no additional users were created
      users = Repo.all(User)
      # Only the existing user
      assert length(users) == 1
    end

    test "handles large number of persons with batching" do
      # Create test persons (more than default batch size)
      _persons = create_test_persons(1500)

      # Capture output
      output =
        capture_io(fn ->
          Mix.Tasks.BackfillUsers.run(["--batch-size", "500"])
        end)

      # Verify output contains expected messages
      assert output =~ "Batch size: 500"
      assert output =~ "Total persons to process: 1500"
      assert output =~ "Processing batch: 1-500 of 1500"
      assert output =~ "Inserted 500 users"
      assert output =~ "Processing batch: 501-1000 of 1500"
      assert output =~ "Inserted 500 users"
      assert output =~ "Processing batch: 1001-1500 of 1500"
      assert output =~ "Inserted 500 users"
      assert output =~ "Backfill completed!"
      assert output =~ "Processed 1500 records"
      assert output =~ "Final user count: 1500"

      # Verify users were created
      users = Repo.all(User)
      assert length(users) == 1500
    end

    test "preserves data integrity with various person data" do
      # Create persons with different data types
      persons_data = [
        %{
          first_name: "Jan",
          last_name: "Kowalski",
          gender: :male,
          birthdate: ~D[1990-01-15]
        },
        %{
          first_name: "Anna",
          last_name: "Nowak",
          gender: :female,
          birthdate: ~D[1985-05-20]
        },
        %{
          first_name: "Piotr",
          last_name: "Wiśniewski",
          gender: :male,
          birthdate: ~D[1995-12-03]
        }
      ]

      persons =
        Enum.map(persons_data, fn attrs ->
          %Person{}
          |> Person.changeset(attrs)
          |> Repo.insert!()
        end)

      # Run backfill
      capture_io(fn ->
        Mix.Tasks.BackfillUsers.run([])
      end)

      # Verify users were created with correct data
      users = Repo.all(User)
      assert length(users) == 3

      # Sort both lists by first_name for comparison
      sorted_persons = Enum.sort_by(persons, & &1.first_name)
      sorted_users = Enum.sort_by(users, & &1.first_name)

      for {person, user} <- Enum.zip(sorted_persons, sorted_users) do
        assert user.first_name == person.first_name
        assert user.last_name == person.last_name
        assert user.gender == person.gender
        assert user.birthdate == person.birthdate
        assert user.inserted_at == person.inserted_at
        assert user.updated_at == person.updated_at
      end
    end

    test "handles single person correctly" do
      # Create single person
      _person =
        create_test_person(%{
          first_name: "Single",
          last_name: "Person",
          gender: :male,
          birthdate: ~D[1990-01-01]
        })

      # Capture output
      output =
        capture_io(fn ->
          Mix.Tasks.BackfillUsers.run([])
        end)

      # Verify output contains expected messages
      assert output =~ "Total persons to process: 1"
      assert output =~ "Processing batch: 1-1 of 1"
      assert output =~ "Inserted 1 users"
      assert output =~ "Backfill completed!"
      assert output =~ "Processed 1 records"
      assert output =~ "Final user count: 1"

      # Verify user was created
      users = Repo.all(User)
      assert length(users) == 1

      user = hd(users)
      assert user.first_name == "Single"
      assert user.last_name == "Person"
      assert user.gender == :male
      assert user.birthdate == ~D[1990-01-01]
    end

    test "handles persons with special characters in names" do
      # Create persons with special characters
      persons_data = [
        %{
          first_name: "Łukasz",
          last_name: "Żółć",
          gender: :male,
          birthdate: ~D[1990-01-01]
        },
        %{
          first_name: "Świętosława",
          last_name: "Ćwikła",
          gender: :female,
          birthdate: ~D[1985-05-15]
        }
      ]

      _persons =
        Enum.map(persons_data, fn attrs ->
          %Person{}
          |> Person.changeset(attrs)
          |> Repo.insert!()
        end)

      # Run backfill
      capture_io(fn ->
        Mix.Tasks.BackfillUsers.run([])
      end)

      # Verify users were created with correct special characters
      users = Repo.all(User)
      assert length(users) == 2

      # Find users by first name to verify correct mapping
      lukasz_user = Enum.find(users, &(&1.first_name == "Łukasz"))
      swietoslawa_user = Enum.find(users, &(&1.first_name == "Świętosława"))

      assert lukasz_user.last_name == "Żółć"
      assert lukasz_user.gender == :male
      assert lukasz_user.birthdate == ~D[1990-01-01]

      assert swietoslawa_user.last_name == "Ćwikła"
      assert swietoslawa_user.gender == :female
      assert swietoslawa_user.birthdate == ~D[1985-05-15]
    end
  end

  # Helper functions

  defp create_test_person(attrs) do
    default_attrs = %{
      first_name: "Test",
      last_name: "Person",
      gender: :male,
      birthdate: ~D[1990-01-01]
    }

    attrs = Map.merge(default_attrs, attrs)

    %Person{}
    |> Person.changeset(attrs)
    |> Repo.insert!()
  end

  defp create_test_persons(count) when is_integer(count) do
    for i <- 1..count do
      create_test_person(%{
        first_name: "Person#{i}",
        last_name: "LastName#{i}",
        gender: if(rem(i, 2) == 0, do: :female, else: :male),
        birthdate: Date.add(~D[1990-01-01], i)
      })
    end
  end
end
