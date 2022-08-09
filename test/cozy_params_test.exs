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

    test "returns {:error, %Ecto.Changeset{}} when params are invalid" do
      defmodule DemoB do
        import CozyParams

        defparams :product_search do
          field :name, :string, required: true
        end
      end

      assert {:error, %Ecto.Changeset{valid?: false}} = DemoB.product_search(%{})
      assert {:error, %Ecto.Changeset{valid?: false}} = DemoB.product_search(%{}, type: :struct)
      assert {:error, %Ecto.Changeset{valid?: false}} = DemoB.product_search(%{}, type: :map)
    end
  end
end
