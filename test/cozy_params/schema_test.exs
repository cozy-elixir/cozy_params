defmodule CozyParams.SchemaTest do
  use ExUnit.Case
  doctest CozyParams.Schema

  defmodule SearchParams do
    use CozyParams.Schema

    schema do
      field :name, :string, default: "anonymous", required: true
      field :age, :integer

      embeds_one :address, Address do
        field :latitude, :float, required: true
        field :longtitude, :float, required: true
      end

      embeds_many :pets, Pet do
        field :name, :string, required: true
        field :breed, :string
      end
    end
  end

  describe "schema/1" do
    test "defines a valid struct of Ecto.Schema" do
      assert [:name, :age, :address, :pets] == SearchParams.__schema__(:fields)
    end

    test "generates functions for runtime introspection" do
      assert {:__block__, _,
              [
                {:field, _, [:name, :string, [default: "anonymous", required: true]]},
                {:field, _, [:age, :integer]},
                {:embeds_one, _,
                 [
                   :address,
                   {:__aliases__, _, [:Address]},
                   [
                     do:
                       {:__block__, _,
                        [
                          {:field, _, [:latitude, :float, [required: true]]},
                          {:field, _, [:longtitude, :float, [required: true]]}
                        ]}
                   ]
                 ]},
                {:embeds_many, _,
                 [
                   :pets,
                   {:__aliases__, _, [:Pet]},
                   [
                     do:
                       {:__block__, _,
                        [
                          {:field, _, [:name, :string, [required: true]]},
                          {:field, _, [:breed, :string]}
                        ]}
                   ]
                 ]}
              ]} = SearchParams.__cozy_params_schema__()
    end

    test "has compile error when unsupported Ecto macro is called" do
      try do
        defmodule BadParams do
          use CozyParams.Schema

          schema do
            field :name, :string, default: "anonymous", required: true
            field :age, :integer

            has_one :address, Address do
              field :latitude, :float, required: true
              field :longtitude, :float, required: true
            end

            has_many :pets, Pet do
              field :name, :string, required: true
              field :breed, :string
            end
          end
        end
      rescue
        error in [ArgumentError] ->
          assert %{
                   message:
                     "unsupported macro - :has_one, only :field, :embeds_one, :embeds_many are supported"
                 } = error

        _ ->
          assert false, "bad error message"
      end
    end
  end
end
