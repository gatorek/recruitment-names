defmodule PhoenixApi.Schemas.User do
  @moduledoc """
  Schema for User entity.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :first_name, :last_name, :gender, :birthdate]}

  schema "users" do
    field :first_name, :string
    field :last_name, :string
    field :gender, Ecto.Enum, values: [:female, :male]
    field :birthdate, :date

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :gender, :birthdate])
    |> validate_required([:first_name, :last_name, :gender, :birthdate])
    |> validate_length(:first_name, min: 1, max: 255)
    |> validate_length(:last_name, min: 1, max: 255)
  end
end
