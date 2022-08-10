defmodule CozyParamsTest do
  use ExUnit.Case
  doctest CozyParams

  describe "defparams/2" do
    test "works as expected" do
      defmodule DemoA do
        import CozyParams

        defparams :product_search do
          field :name, :string, required: true
        end
      end

      assert {:ok, %_{name: "Charlie"}} = DemoA.product_search(%{"name" => "Charlie"})

      assert {:ok, %_{name: "Charlie"}} =
               DemoA.product_search(%{"name" => "Charlie"}, type: :struct)

      assert {:ok, %{name: "Charlie"}} = DemoA.product_search(%{"name" => "Charlie"}, type: :map)
    end

    test "returns {:error, params_changeset: %Ecto.Changeset{}} when params are invalid" do
      defmodule DemoB do
        import CozyParams

        defparams :product_search do
          field :name, :string, required: true
        end
      end

      assert {:error, params_changeset: %Ecto.Changeset{valid?: false}} =
               DemoB.product_search(%{})

      assert {:error, params_changeset: %Ecto.Changeset{valid?: false}} =
               DemoB.product_search(%{}, type: :struct)

      assert {:error, params_changeset: %Ecto.Changeset{valid?: false}} =
               DemoB.product_search(%{}, type: :map)
    end
  end

  describe "get_error_messages/1" do
    test "works with defparams/2" do
      defmodule DemoC do
        import CozyParams

        defparams :product_search do
          field :name, :string, required: true
        end
      end

      assert {:error, params_changeset: changeset} = DemoC.product_search(%{})
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
end
