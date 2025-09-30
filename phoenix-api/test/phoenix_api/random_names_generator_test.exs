defmodule PhoenixApi.RandomNamesGeneratorTest do
  use ExUnit.Case, async: true

  alias PhoenixApi.RandomNamesGenerator

  describe "call/3" do
    setup do
      names = %{
        male_first_names: ["adam", "stefan", "piotr"],
        male_last_names: ["kowalski", "nowak", "wiśniewski"],
        female_first_names: ["anna", "ewa", "maria"],
        female_last_names: ["kowalska", "nowak", "wiśniewska"]
      }

      date_range = Date.range(~D[1990-01-01], ~D[2000-12-31])

      %{names: names, date_range: date_range}
    end

    test "generates correct number of persons", %{names: names, date_range: date_range} do
      result = RandomNamesGenerator.call(names, date_range, 5)
      assert length(result) == 5
    end

    test "generates empty list when count is 0", %{names: names, date_range: date_range} do
      result = RandomNamesGenerator.call(names, date_range, 0)
      assert result == []
    end

    test "generates persons with correct structure", %{names: names, date_range: date_range} do
      result = RandomNamesGenerator.call(names, date_range, 1)
      person = List.first(result)

      assert Map.has_key?(person, :gender)
      assert Map.has_key?(person, :first_name)
      assert Map.has_key?(person, :last_name)
      assert Map.has_key?(person, :birth_date)

      assert person.gender in [:male, :female]
      assert is_binary(person.first_name)
      assert is_binary(person.last_name)
      assert %Date{} = person.birth_date
    end

    test "generates male names correctly", %{names: names, date_range: date_range} do
      # Generate many persons to increase chance of getting males
      result = RandomNamesGenerator.call(names, date_range, 100)
      males = Enum.filter(result, &(&1.gender == :male))

      # Check that male persons have male names
      for male <- males do
        assert male.first_name in names.male_first_names
        assert male.last_name in names.male_last_names
      end
    end

    test "generates female names correctly", %{names: names, date_range: date_range} do
      # Generate many persons to increase chance of getting females
      result = RandomNamesGenerator.call(names, date_range, 100)
      females = Enum.filter(result, &(&1.gender == :female))

      # Check that female persons have female names
      for female <- females do
        assert female.first_name in names.female_first_names
        assert female.last_name in names.female_last_names
      end
    end

    test "generates birth dates within the specified range", %{
      names: names
    } do
      date_range = Date.range(~D[1990-01-01], ~D[1990-01-03])
      result = RandomNamesGenerator.call(names, date_range, 10)

      for person <- result do
        assert Date.compare(person.birth_date, date_range.first) != :lt
        assert Date.compare(person.birth_date, date_range.last) != :gt
      end
    end

    # This test may occasionally fail; skipped by default.
    @tag :skip
    test "generates different results on multiple calls", %{names: names, date_range: date_range} do
      result1 = RandomNamesGenerator.call(names, date_range, 5)
      result2 = RandomNamesGenerator.call(names, date_range, 5)

      # Results should be different (very high probability with random generation)
      assert result1 != result2
    end

    test "handles single day date range", %{names: names} do
      single_day_range = Date.range(~D[1995-06-15], ~D[1995-06-15])
      result = RandomNamesGenerator.call(names, single_day_range, 3)

      for person <- result do
        assert person.birth_date == ~D[1995-06-15]
      end
    end

    test "handles edge case with minimal names", %{date_range: date_range} do
      minimal_names = %{
        male_first_names: ["adam"],
        male_last_names: ["kowalski"],
        female_first_names: ["anna"],
        female_last_names: ["nowak"]
      }

      result = RandomNamesGenerator.call(minimal_names, date_range, 4)

      # Should generate persons with the only available names
      male_names = Enum.filter(result, &(&1.gender == :male))
      female_names = Enum.filter(result, &(&1.gender == :female))

      for male <- male_names do
        assert male.first_name == "adam"
        assert male.last_name == "kowalski"
      end

      for female <- female_names do
        assert female.first_name == "anna"
        assert female.last_name == "nowak"
      end
    end

    test "generates both genders", %{names: names, date_range: date_range} do
      # Generate enough persons to ensure we get both genders
      result = RandomNamesGenerator.call(names, date_range, 50)
      genders = Enum.map(result, & &1.gender) |> Enum.uniq()

      assert :male in genders
      assert :female in genders
    end

    test "birth dates are distributed across the range", %{names: names, date_range: date_range} do
      result = RandomNamesGenerator.call(names, date_range, 100)
      birth_dates = Enum.map(result, & &1.birth_date)

      # Check that we have dates from different parts of the range
      unique_dates = Enum.uniq(birth_dates)
      assert length(unique_dates) > 1
    end

    test "random_gender returns valid gender" do
      # Test the private function indirectly through call/3
      names = %{
        male_first_names: ["adam"],
        male_last_names: ["kowalski"],
        female_first_names: ["anna"],
        female_last_names: ["nowak"]
      }

      date_range = Date.range(~D[1990-01-01], ~D[2000-12-31])

      result = RandomNamesGenerator.call(names, date_range, 20)
      genders = Enum.map(result, & &1.gender)

      assert Enum.all?(genders, &(&1 in [:male, :female]))
    end
  end
end
