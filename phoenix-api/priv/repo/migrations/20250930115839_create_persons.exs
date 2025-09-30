defmodule PhoenixApi.Repo.Migrations.CreatePersons do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE gender_enum AS ENUM ('male', 'female')", "DROP TYPE gender_enum"

    create table(:persons) do
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :gender, :gender_enum, null: false
      add :birthdate, :date, null: false

      timestamps()
    end
  end
end
