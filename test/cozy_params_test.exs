defmodule CozyParamsTest do
  use ExUnit.Case
  doctest CozyParams

  describe "defparams/2" do
    test "returns a map" do
      defmodule DemoA1 do
        import CozyParams

        defparams :product_search do
          field :name, :string, required: true
          field :age, :integer
        end
      end

      {:ok, return_value} = DemoA1.product_search(%{"name" => "Charlie"})
      assert is_map(return_value)
      refute is_struct(return_value)
    end

    test "rejects nil values" do
      defmodule DemoA2 do
        import CozyParams

        defparams :product_search do
          field :name, :string, required: true
          field :age, :integer
        end
      end

      assert {:ok, %{name: "Charlie"} = return_value} =
               DemoA2.product_search(%{"name" => "Charlie"})

      refute Map.has_key?(return_value, :age)
    end

    test "preserves nil values when the `:default` option is specified" do
      defmodule DemoA3 do
        import CozyParams

        defparams :product_search do
          field :name, :string, required: true
          field :age, :integer, default: nil
        end
      end

      assert {:ok, %{name: "Charlie", age: nil}} = DemoA3.product_search(%{"name" => "Charlie"})
    end

    test "returns {:error, params_changeset: %Ecto.Changeset{}} when params are invalid" do
      defmodule DemoB1 do
        import CozyParams

        defparams :product_search do
          field :name, :string, required: true
        end
      end

      assert {:error, params_changeset: %Ecto.Changeset{valid?: false}} =
               DemoB1.product_search(%{})
    end
  end

  describe "get_error_messages/1" do
    test "works with defparams/2" do
      defmodule DemoC1 do
        import CozyParams

        defparams :product_search do
          field :name, :string, required: true
        end
      end

      assert {:error, params_changeset: changeset} = DemoC1.product_search(%{})
      assert %{name: ["can't be blank"]} == CozyParams.get_error_messages(changeset)
    end

    test "works with a plain changeset" do
      defmodule ParamsA do
        use CozyParams.Schema

        schema do
          field :name, :string, required: true
          field :age, :integer
        end
      end

      assert {:error, params_changeset: changeset} = ParamsA.from(%{})

      assert %{
               name: ["can't be blank"]
             } == CozyParams.get_error_messages(changeset)
    end

    test "works with nested changesets" do
      defmodule ParamsB do
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

      assert {:error, params_changeset: changeset} = ParamsB.from(%{mate: %{}, pets: [%{}, %{}]})

      assert %{
               mate: %{name: ["can't be blank"]},
               name: ["can't be blank"],
               pets: [
                 %{name: ["can't be blank"]},
                 %{name: ["can't be blank"]}
               ]
             } ==
               CozyParams.get_error_messages(changeset)
    end
  end

  describe "get_error_messages/2" do
    test "works with custom msg_func" do
      defmodule DemoD do
        import CozyParams

        defparams :product_search do
          field :name, :string, required: true
        end

        def translate_error({"can't be blank", _opts}), do: "は必須項目です"
      end

      assert {:error, params_changeset: changeset} = DemoD.product_search(%{})

      assert %{name: ["は必須項目です"]} ==
               CozyParams.get_error_messages(changeset, &DemoD.translate_error/1)
    end
  end
end
