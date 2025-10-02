defmodule PhoenixApi.Repo.Migrations.DropPersonsTable do
  use Ecto.Migration

  def up do
    drop table(:persons)
    execute "DROP TYPE gender_enum"
  end

  def down do
    execute "CREATE TYPE gender_enum AS ENUM ('male', 'female')"

    create table(:persons) do
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :gender, :gender_enum, null: false
      add :birthdate, :date, null: false

      timestamps()
    end
  end
end
