defmodule CozyParams.SchemaTest do
  use ExUnit.Case
  doctest CozyParams.Schema

  defmodule SearchParams do
    use CozyParams.Schema

    schema do
      field :name, :string, default: "anonymous"
      field :age, :integer
    end
  end

  describe "schema/1" do
    test "defines a valid struct of Ecto.Schema" do
      assert %{name: "anonymous", age: nil} = %SearchParams{}
      assert [:name, :age] == SearchParams.__schema__(:fields)
    end

    test "generates functions for runtime introspection" do
      assert {:__block__, [],
              [
                {:field, _, [:name, :string, [default: "anonymous"]]},
                {:field, _, [:age, :integer]}
              ]} = SearchParams.__cozy_params_schema__()
    end
  end
end
