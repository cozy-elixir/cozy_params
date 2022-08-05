defmodule CozyParams.SchemaTest do
  use ExUnit.Case
  doctest CozyParams.Schema

  describe "schema/1" do
    test "defines a valid struct of Ecto.Schema" do
      defmodule SampleParams do
        use CozyParams.Schema

        schema do
          field :name, :string, default: "anonymous", required: true
          field :age, :integer

          embeds_one :address, Address, required: true do
            field :latitude, :float, required: true
            field :longtitude, :float, required: true
          end

          embeds_many :pets, Pet do
            field :name, :string, required: true
            field :breed, :string
          end
        end
      end

      assert [:name, :age, :address, :pets] == SampleParams.__schema__(:fields)
    end

    test "generates functions for runtime introspection" do
      defmodule IntrospectionParams do
        use CozyParams.Schema

        schema do
          field :name, :string, default: "anonymous", required: true
          field :age, :integer

          embeds_one :address, Address, required: true do
            field :latitude, :float, required: true
            field :longtitude, :float, required: true
          end

          embeds_many :pets, Pet do
            field :name, :string, required: true
            field :breed, :string
          end
        end
      end

      assert {:__block__, _,
              [
                {:field, _, [:name, :string, [default: "anonymous", required: true]]},
                {:field, _, [:age, :integer]},
                {:embeds_one, _,
                 [
                   :address,
                   {:__aliases__, _, [:Address]},
                   [required: true],
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
              ]} = IntrospectionParams.__cozy_params_schema__(:origin)

      assert {:__block__, _,
              [
                {:field, _, [:name, :string, [default: "anonymous"]]},
                {:field, _, [:age, :integer]},
                {:embeds_one, _,
                 [
                   :address,
                   {:__aliases__, _, [:Address]},
                   [
                     do:
                       {:__block__, _,
                        [
                          {:field, _, [:latitude, :float]},
                          {:field, _, [:longtitude, :float]}
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
                          {:field, _, [:name, :string]},
                          {:field, _, [:breed, :string]}
                        ]}
                   ]
                 ]}
              ]} = IntrospectionParams.__cozy_params_schema__(:ecto)
    end

    test "supports shortcuts of embeds_one and embeds_many" do
      defmodule ShortcutParams do
        use CozyParams.Schema

        schema do
          field :name, :string, default: "anonymous", required: true
          field :age, :integer

          embeds_one :address, required: true do
            field :latitude, :float, required: true
            field :longtitude, :float, required: true
          end

          embeds_many :pets do
            field :name, :string, required: true
            field :breed, :string
          end
        end
      end

      assert {:__block__, _,
              [
                {:field, _, [:name, :string, [default: "anonymous"]]},
                {:field, _, [:age, :integer]},
                {:embeds_one, [line: 123],
                 [
                   :address,
                   {:__aliases__, _, [:Address]},
                   [
                     do:
                       {:__block__, _,
                        [
                          {:field, _, [:latitude, :float]},
                          {:field, _, [:longtitude, :float]}
                        ]}
                   ]
                 ]},
                {:embeds_many, _,
                 [
                   :pets,
                   {:__aliases__, _, [:Pets]},
                   [
                     do:
                       {:__block__, _,
                        [
                          {:field, _, [:name, :string]},
                          {:field, _, [:breed, :string]}
                        ]}
                   ]
                 ]}
              ]} = ShortcutParams.__cozy_params_schema__(:ecto)
    end

    test "reports compile error when unsupported Ecto macro is called" do
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
