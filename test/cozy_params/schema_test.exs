defmodule CozyParams.SchemaTest do
  use ExUnit.Case
  doctest CozyParams.Schema

  defmodule GoodParamsWithInlineSyntax do
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

  defmodule GoodParamsWithExtraModules do
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

    test "works with inline syntax" do
      alias GoodParamsWithInlineSyntax, as: Params

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

    test "works with extra modules" do
      alias GoodParamsWithExtraModules, as: Params

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

    test "is forbidden to call twice" do
      assert_raise RuntimeError,
                   ~r/^schema already defined for CozyParams.SchemaTest.ParamsThatCallSchemaTwice.*/,
                   fn ->
                     defmodule ParamsThatCallSchemaTwice do
                       use CozyParams.Schema

                       schema do
                         field :name, :string
                       end

                       schema do
                         field :name, :string
                       end
                     end
                   end
    end
  end

  describe "changeset/2" do
    test "is overridable" do
      defmodule ParamsWithOveridedChangeset do
        use CozyParams.Schema

        schema do
          field :name, :string, required: true
        end

        def changeset(struct, params) do
          struct
          |> super(params)
          |> Ecto.Changeset.validate_format(:name, ~r/@/)
        end
      end

      alias ParamsWithOveridedChangeset, as: Params

      assert {:error,
              %Ecto.Changeset{
                valid?: false,
                errors: [name: {"has invalid format", [validation: :format]}]
              }} = Params.from(%{name: "Charlie"})

      assert {:ok,
              %{
                name: "@Charlie"
              }} = Params.from(%{name: "@Charlie"})
    end
  end
end
