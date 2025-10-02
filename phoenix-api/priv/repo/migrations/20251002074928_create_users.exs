defmodule PhoenixApi.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE users_gender_enum AS ENUM ('female', 'male')",
            "DROP TYPE users_gender_enum"

    create table(:users) do
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :gender, :users_gender_enum, null: false
      add :birthdate, :date, null: false

      timestamps()
    end

    execute "ALTER TABLE users ALTER COLUMN first_name TYPE varchar COLLATE \"und-x-icu\""
    execute "ALTER TABLE users ALTER COLUMN last_name TYPE varchar COLLATE \"und-x-icu\""

    create index(:users, [:first_name])
    create index(:users, [:last_name])
    create index(:users, [:gender])
    create index(:users, [:birthdate])
  end
end
