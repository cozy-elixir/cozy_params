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

  describe "field/2 and field/3" do
    test "support all primitive types of Ecto" do
      defmodule ParamsWithAllEctoPrimitiveTypes do
        use CozyParams.Schema

        schema do
          field :id, :id, required: true
          field :binary_id, :binary_id, required: true
          field :integer, :integer, required: true
          field :float, :float, required: true
          field :boolean, :boolean, required: true
          field :string, :string, required: true
          field :binary, :string, required: true
          field :array_with_inner_type, {:array, :integer}, required: true
          field :map, :map, required: true
          field :map_with_inner_type, {:map, :float}, required: true
          field :decimal, :decimal, required: true
          field :date, :date, required: true
          field :time, :time, required: true
          field :time_usec, :time_usec, required: true
          field :naive_datetime, :naive_datetime, required: true
          field :naive_datetime_usec, :naive_datetime_usec, required: true
          field :utc_datetime, :utc_datetime, required: true
          field :utc_datetime_usec, :utc_datetime_usec, required: true
        end
      end

      alias ParamsWithAllEctoPrimitiveTypes, as: Params

      assert {:ok,
              %{
                id: 123,
                binary_id: "e7d3e3c9-9c8c-443a-99db-e21609304fb9",
                integer: 2234,
                float: 1.22,
                boolean: false,
                string: "hello world!",
                binary: "hello world!",
                array_with_inner_type: [1, 2, 3],
                map: %{pet: "dog"},
                map_with_inner_type: %{cat: 1.0, dog: 2.0, sheep: 3.0},
                decimal: Decimal.new("2.30"),
                date: ~D[2022-08-09],
                time: ~T[10:34:00],
                naive_datetime: ~N[2022-08-09 10:36:25],
                naive_datetime_usec: ~N[2022-08-09 10:36:25.648266],
                time_usec: ~T[10:34:21.489485],
                utc_datetime: ~U[2022-08-09 10:36:25Z],
                utc_datetime_usec: ~U[2022-08-09 10:36:25.648266Z]
              }} ==
               Params.from(
                 %{
                   id: 123,
                   binary_id: "e7d3e3c9-9c8c-443a-99db-e21609304fb9",
                   integer: "2234",
                   float: "1.22",
                   boolean: "false",
                   string: "hello world!",
                   binary: "hello world!",
                   array_with_inner_type: ["1", "2", "3"],
                   map: %{pet: "dog"},
                   map_with_inner_type: %{cat: "1", dog: "2", sheep: "3"},
                   decimal: "2.30",
                   date: "2022-08-09",
                   time: "10:34:00",
                   time_usec: "10:34:21.489485",
                   naive_datetime: "2022-08-09 10:36:25.648266",
                   naive_datetime_usec: "2022-08-09 10:36:25.648266",
                   utc_datetime: "2022-08-09 10:36:25.648266",
                   utc_datetime_usec: "2022-08-09 10:36:25.648266"
                 },
                 type: :map
               )
    end

    test "supports custom types of Ecto" do
      defmodule ParamsWithEctoCustomTypes do
        use CozyParams.Schema

        schema do
          field :uuid, Ecto.UUID, required: true
          field :enum, Ecto.Enum, values: [:cat, :dog, :sheep], required: true
        end
      end

      alias ParamsWithEctoCustomTypes, as: Params

      assert {:ok,
              %{
                uuid: "e7d3e3c9-9c8c-443a-99db-e21609304fb9",
                enum: :cat
              }} ==
               Params.from(
                 %{
                   uuid: "e7d3e3c9-9c8c-443a-99db-e21609304fb9",
                   enum: "cat"
                 },
                 type: :map
               )
    end

    test "supports option - :default" do
      defmodule ParamsWithDefaultOption do
        use CozyParams.Schema

        schema do
          field :age, :integer, default: 6
        end
      end

      alias ParamsWithDefaultOption, as: Params
      assert {:ok, %{age: 6}} = Params.from(%{})
    end

    # test "supports option - :autogenerate" do
    #   defmodule ParamsWithAutogenerateOption do
    #     use CozyParams.Schema

    #     schema do
    #       field :published_at, :utc_datetime,
    #         autogenerate: {DateTime, :new!, [~D[2016-05-24], ~T[13:26:08.003], "Etc/UTC"]}
    #     end
    #   end

    #   alias ParamsWithAutogenerateOption, as: Params
    #   assert {:ok, %{published_at: ~U[2016-05-24 13:26:08.003Z]}} = Params.from(%{})
    # end
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
