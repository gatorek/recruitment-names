defmodule Mix.Tasks.BackfillUsers do
  @moduledoc """
  Mix task to backfill users table with data from persons table.

  ## Usage

      mix backfill_users

  ## Options

      --batch-size    Number of records to process in each batch (default: 1000)
      --dry-run       Show what would be done without actually doing it
  """

  use Mix.Task
  import Ecto.Query
  alias PhoenixApi.Repo
  alias PhoenixApi.Schemas.Person
  alias PhoenixApi.Schemas.User

  @shortdoc "Backfill users table with data from persons table"

  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        switches: [batch_size: :integer, dry_run: :boolean],
        aliases: [b: :batch_size, d: :dry_run]
      )

    batch_size = Keyword.get(opts, :batch_size, 1000)
    dry_run = Keyword.get(opts, :dry_run, false)

    Mix.Task.run("app.start")

    if dry_run do
      IO.puts("DRY RUN MODE - No data will be modified")
    end

    IO.puts("Starting backfill process...")
    IO.puts("Batch size: #{batch_size}")

    # Get total count of persons
    total_persons = Repo.aggregate(Person, :count, :id)
    IO.puts("Total persons to process: #{total_persons}")

    if total_persons == 0 do
      IO.puts("No persons found to backfill")
      System.halt(0)
    end

    # Check if users table is empty
    total_users = Repo.aggregate(User, :count, :id)

    if total_users > 0 do
      IO.puts("Users table is not empty (#{total_users} records found)")
      IO.puts("Backfill aborted to prevent data duplication")

      if Mix.env() == :test do
        raise "Users table is not empty, backfill aborted"
      else
        System.halt(1)
      end
    end

    # Process in batches
    case process_batches(batch_size, dry_run, total_persons) do
      {:ok, processed} ->
        IO.puts("Backfill completed!")
        IO.puts("Processed #{processed} records")

      {:error, reason} ->
        IO.puts("Error executing backfill. No data was inserted. Reason: #{inspect(reason)}")
    end

    if not dry_run do
      final_user_count = Repo.aggregate(User, :count, :id)
      IO.puts("Final user count: #{final_user_count}")
    end
  end

  defp process_batches(batch_size, dry_run, total_persons) do
    query = from p in Person, order_by: [asc: p.id]

    Repo.transaction(fn ->
      process_batches_recursive(query, batch_size, dry_run, 0, total_persons)
    end)
  end

  defp process_batches_recursive(query, batch_size, dry_run, processed, total_persons) do
    persons = Repo.all(from p in query, limit: ^batch_size, offset: ^processed)

    if Enum.empty?(persons) do
      processed
    else
      batch_count = length(persons)
      IO.puts("Processing batch: #{processed + 1}-#{processed + batch_count} of #{total_persons}")

      if not dry_run do
        # Convert persons to user data
        user_data =
          Enum.map(persons, fn person ->
            %{
              first_name: person.first_name,
              last_name: person.last_name,
              gender: person.gender,
              birthdate: person.birthdate,
              inserted_at: person.inserted_at,
              updated_at: person.updated_at
            }
          end)

        # Insert users
        case Repo.insert_all(User, user_data) do
          {count, _} when count > 0 ->
            IO.puts("Inserted #{count} users")

          {0, _} ->
            IO.puts("No users inserted")
        end
      else
        IO.puts("Would insert #{batch_count} users")
      end

      # Continue with next batch
      process_batches_recursive(
        query,
        batch_size,
        dry_run,
        processed + batch_count,
        total_persons
      )
    end
  end
end
