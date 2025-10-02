defmodule PhoenixApi.Schemas.UserTest do
  use PhoenixApi.DataCase, async: true

  alias PhoenixApi.Schemas.User

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      attrs = %{
        first_name: "Jan",
        last_name: "Kowalski",
        gender: :male,
        birthdate: ~D[1990-01-01]
      }

      changeset = User.changeset(%User{}, attrs)

      assert changeset.valid?
      assert changeset.changes.first_name == "Jan"
      assert changeset.changes.last_name == "Kowalski"
      assert changeset.changes.gender == :male
      assert changeset.changes.birthdate == ~D[1990-01-01]
    end

    test "valid changeset with female gender" do
      attrs = %{
        first_name: "Anna",
        last_name: "Nowak",
        gender: :female,
        birthdate: ~D[1985-05-15]
      }

      changeset = User.changeset(%User{}, attrs)

      assert changeset.valid?
      assert changeset.changes.gender == :female
    end

    test "invalid changeset when first_name is missing" do
      attrs = %{
        last_name: "Kowalski",
        gender: :male,
        birthdate: ~D[1990-01-01]
      }

      changeset = User.changeset(%User{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).first_name
    end

    test "invalid changeset when last_name is missing" do
      attrs = %{
        first_name: "Jan",
        gender: :male,
        birthdate: ~D[1990-01-01]
      }

      changeset = User.changeset(%User{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).last_name
    end

    test "invalid changeset when gender is missing" do
      attrs = %{
        first_name: "Jan",
        last_name: "Kowalski",
        birthdate: ~D[1990-01-01]
      }

      changeset = User.changeset(%User{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).gender
    end

    test "invalid changeset when birthdate is missing" do
      attrs = %{
        first_name: "Jan",
        last_name: "Kowalski",
        gender: :male
      }

      changeset = User.changeset(%User{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).birthdate
    end

    test "invalid changeset when first_name is empty string" do
      attrs = %{
        first_name: "",
        last_name: "Kowalski",
        gender: :male,
        birthdate: ~D[1990-01-01]
      }

      changeset = User.changeset(%User{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).first_name
    end

    test "invalid changeset when last_name is empty string" do
      attrs = %{
        first_name: "Jan",
        last_name: "",
        gender: :male,
        birthdate: ~D[1990-01-01]
      }

      changeset = User.changeset(%User{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).last_name
    end

    test "invalid changeset when first_name is too long" do
      long_name = String.duplicate("A", 256)

      attrs = %{
        first_name: long_name,
        last_name: "Kowalski",
        gender: :male,
        birthdate: ~D[1990-01-01]
      }

      changeset = User.changeset(%User{}, attrs)

      refute changeset.valid?
      assert "should be at most 255 character(s)" in errors_on(changeset).first_name
    end

    test "invalid changeset when last_name is too long" do
      long_name = String.duplicate("A", 256)

      attrs = %{
        first_name: "Jan",
        last_name: long_name,
        gender: :male,
        birthdate: ~D[1990-01-01]
      }

      changeset = User.changeset(%User{}, attrs)

      refute changeset.valid?
      assert "should be at most 255 character(s)" in errors_on(changeset).last_name
    end

    test "invalid changeset when gender is invalid" do
      attrs = %{
        first_name: "Jan",
        last_name: "Kowalski",
        gender: :invalid_gender,
        birthdate: ~D[1990-01-01]
      }

      changeset = User.changeset(%User{}, attrs)

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).gender
    end

    test "valid changeset with maximum length names" do
      long_name = String.duplicate("A", 255)

      attrs = %{
        first_name: long_name,
        last_name: long_name,
        gender: :male,
        birthdate: ~D[1990-01-01]
      }

      changeset = User.changeset(%User{}, attrs)

      assert changeset.valid?
    end

    test "valid changeset with minimum length names" do
      attrs = %{
        first_name: "A",
        last_name: "B",
        gender: :female,
        birthdate: ~D[1990-01-01]
      }

      changeset = User.changeset(%User{}, attrs)

      assert changeset.valid?
    end

    test "changeset ignores unknown fields" do
      attrs = %{
        first_name: "Jan",
        last_name: "Kowalski",
        gender: :male,
        birthdate: ~D[1990-01-01],
        unknown_field: "should be ignored"
      }

      changeset = User.changeset(%User{}, attrs)

      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :unknown_field)
    end

    test "changeset updates existing user" do
      user = %User{
        first_name: "Jan",
        last_name: "Kowalski",
        gender: :male,
        birthdate: ~D[1990-01-01]
      }

      attrs = %{
        first_name: "Anna",
        last_name: "Nowak",
        gender: :female,
        birthdate: ~D[1985-05-15]
      }

      changeset = User.changeset(user, attrs)

      assert changeset.valid?
      assert changeset.changes.first_name == "Anna"
      assert changeset.changes.last_name == "Nowak"
      assert changeset.changes.gender == :female
      assert changeset.changes.birthdate == ~D[1985-05-15]
    end
  end

  describe "schema fields" do
    test "schema has correct fields" do
      user = %User{
        id: 1,
        first_name: "Jan",
        last_name: "Kowalski",
        gender: :male,
        birthdate: ~D[1990-01-01],
        inserted_at: ~N[2024-01-01 00:00:00],
        updated_at: ~N[2024-01-01 00:00:00]
      }

      assert user.id == 1
      assert user.first_name == "Jan"
      assert user.last_name == "Kowalski"
      assert user.gender == :male
      assert user.birthdate == ~D[1990-01-01]
      assert user.inserted_at == ~N[2024-01-01 00:00:00]
      assert user.updated_at == ~N[2024-01-01 00:00:00]
    end
  end
end
