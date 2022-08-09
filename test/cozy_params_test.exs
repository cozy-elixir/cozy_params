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

  describe "CozyParams.Changeset.get_error_messages/1" do
    test "is delegated by CozyParams" do
      defmodule DemoC do
        import CozyParams

        defparams :product_search do
          field :name, :string, required: true
        end
      end

      assert {:error, params_changeset: changeset} = DemoC.product_search(%{})
      assert %{name: ["can't be blank"]} == CozyParams.get_error_messages(changeset)
    end
  end
end
