defmodule PhoenixApi.Schemas.Person do
  @moduledoc """
  Schema for Person entity.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "persons" do
    field :first_name, :string
    field :last_name, :string
    field :gender, Ecto.Enum, values: [:male, :female]
    field :birthdate, :date

    timestamps()
  end

  @doc false
  def changeset(person, attrs) do
    person
    |> cast(attrs, [:first_name, :last_name, :gender, :birthdate])
    |> validate_required([:first_name, :last_name, :gender, :birthdate])
    |> validate_length(:first_name, min: 1, max: 255)
    |> validate_length(:last_name, min: 1, max: 255)
  end
end
