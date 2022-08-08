defmodule CozyParams.SchemaTest do
  use ExUnit.Case
  doctest CozyParams.Schema

  defmodule GoodParamsWithInlineDefinitions do
    use CozyParams.Schema

    schema do
      field :name, :string, required: true
      field :age, :integer

      embeds_one :mate, required: true do
        field :name, :string, required: true
        field :age, :integer
      end

      embeds_many :pets do
        field :name, :string, required: true
        field :breed, :string
      end
    end
  end

  defmodule GoodParamsWithCrossModuleDefinitions do
    use CozyParams.Schema

    defmodule Mate do
      use CozyParams.Schema

      schema do
        field :name, :string, required: true
        field :age, :integer
      end
    end

    defmodule Pet do
      use CozyParams.Schema

      schema do
        field :name, :string, required: true
        field :breed, :string
      end
    end

    schema do
      field :name, :string, required: true
      field :age, :integer

      embeds_one :mate, Mate, required: true

      embeds_many :pets, Pet
    end
  end

  describe "schema/1" do
    test "find bad macros at compile time" do
      assert_raise ArgumentError, "invalid macro bad_macro/2 of cozy_params", fn ->
        defmodule ParamsWithBadMacro do
          use CozyParams.Schema

          schema do
            bad_macro(:name, :string)
          end
        end
      end
    end

    test "find macros with wrong arguments at compile time" do
      assert_raise ArgumentError, "invalid option :do for embeds_one/3 of cozy_params", fn ->
        defmodule ParamsWithBadMacroArguments do
          use CozyParams.Schema

          schema do
            embeds_one :mate, Mate do
              field :name, :string, required: true
              field :age, :integer
            end
          end
        end
      end
    end

    test "find bad options of macros at compile time" do
      assert_raise ArgumentError, "invalid option :unknown for field/3 of cozy_params", fn ->
        defmodule ParamsWithBadMacroOption do
          use CozyParams.Schema

          schema do
            field :name, :string, unknown: true
          end
        end
      end
    end

    test "generates functions for runtime introspection" do
      defmodule IntrospectionParams do
        use CozyParams.Schema

        schema do
          field :name, :string, required: true
          field :age, :integer

          embeds_one :job, Job

          embeds_one :mate, required: true do
            field :name, :string, required: true
            field :age, :integer
          end

          embeds_many :friends, Friend

          embeds_many :pets do
            field :name, :string, required: true
            field :breed, :string
          end
        end
      end

      assert {:__block__, _,
              [
                {:field, _, [:name, :string, [required: true]]},
                {:field, _, [:age, :integer]},
                {:embeds_one, _,
                 [
                   :job,
                   {:__aliases__, _, [:Job]}
                 ]},
                {:embeds_one, _,
                 [
                   :mate,
                   [required: true],
                   [
                     do:
                       {:__block__, _,
                        [
                          {:field, _, [:name, :string, [required: true]]},
                          {:field, _, [:age, :integer]}
                        ]}
                   ]
                 ]},
                {:embeds_many, _,
                 [
                   :friends,
                   {:__aliases__, _, [:Friend]}
                 ]},
                {:embeds_many, _,
                 [
                   :pets,
                   [
                     do:
                       {:__block__, _,
                        [
                          {:field, _, [:name, :string, [required: true]]},
                          {:field, _, [:breed, :string]}
                        ]}
                   ]
                 ]}
              ]} = IntrospectionParams.__cozy_params_schema__(:original)

      assert {:__block__, _,
              [
                {:field, _, [:name, :string, [required: true]]},
                {:field, _, [:age, :integer]},
                {:embeds_one, _,
                 [
                   :job,
                   {:__aliases__, _, [:Job]}
                 ]},
                {:embeds_one, _,
                 [
                   :mate,
                   CozyParams.SchemaTest.IntrospectionParams.Mate,
                   [required: true]
                 ]},
                {:embeds_many, _,
                 [
                   :friends,
                   {:__aliases__, _, [:Friend]}
                 ]},
                {:embeds_many, _,
                 [
                   :pets,
                   CozyParams.SchemaTest.IntrospectionParams.Pets
                 ]}
              ]} = IntrospectionParams.__cozy_params_schema__(:transpiled)

      assert {:__block__, _,
              [
                {:field, _, [:name, :string]},
                {:field, _, [:age, :integer]},
                {:embeds_one, _,
                 [
                   :job,
                   {:__aliases__, _, [:Job]}
                 ]},
                {:embeds_one, _,
                 [
                   :mate,
                   CozyParams.SchemaTest.IntrospectionParams.Mate
                 ]},
                {:embeds_many, _,
                 [
                   :friends,
                   {:__aliases__, _, [:Friend]}
                 ]},
                {:embeds_many, _,
                 [
                   :pets,
                   CozyParams.SchemaTest.IntrospectionParams.Pets
                 ]}
              ]} = IntrospectionParams.__cozy_params_schema__(:ecto)
    end

    test "works with inline definitions" do
      alias GoodParamsWithInlineDefinitions, as: Params

      assert %Ecto.Changeset{
               valid?: false,
               errors: [mate: {"can't be blank", _}]
             } = Params.changeset(%Params{}, %{name: "Charlie"})

      assert %Ecto.Changeset{
               valid?: false,
               changes: %{
                 mate: %Ecto.Changeset{
                   errors: [name: {"can't be blank", _}]
                 }
               }
             } = Params.changeset(%Params{}, %{name: "Charlie", mate: %{}})

      assert %Ecto.Changeset{valid?: true} =
               Params.changeset(%Params{}, %{name: "Charlie", mate: %{name: "Lucy"}})

      assert %Ecto.Changeset{valid?: true} =
               Params.changeset(%Params{}, %{
                 name: "Charlie",
                 mate: %{name: "Lucy"},
                 pets: [%{name: "Snoopy"}]
               })
    end

    test "works with cross module definitions" do
      alias GoodParamsWithCrossModuleDefinitions, as: Params

      assert %Ecto.Changeset{
               valid?: false,
               errors: [mate: {"can't be blank", _}]
             } = Params.changeset(%Params{}, %{name: "Charlie"})

      assert %Ecto.Changeset{
               valid?: false,
               changes: %{
                 mate: %Ecto.Changeset{
                   errors: [name: {"can't be blank", _}]
                 }
               }
             } = Params.changeset(%Params{}, %{name: "Charlie", mate: %{}})

      assert %Ecto.Changeset{valid?: true} =
               Params.changeset(%Params{}, %{name: "Charlie", mate: %{name: "Lucy"}})

      assert %Ecto.Changeset{valid?: true} =
               Params.changeset(%Params{}, %{
                 name: "Charlie",
                 mate: %{name: "Lucy"},
                 pets: [%{name: "Snoopy"}]
               })
    end
  end
end
