defmodule CozyParams.PhoenixControllerTest do
  use ExUnit.Case
  doctest CozyParams.PhoenixController

  describe "params/2" do
    test "works as expected - params' keys will be converted to atoms" do
      defmodule DemoWeb.PageAController do
        use CozyParams.PhoenixController

        params :index do
          field :name, :string, required: true
        end

        def index(conn, params) do
          {conn, params}
        end
      end

      alias DemoWeb.PageAController, as: Controller
      assert {:conn, %{name: "Charlie"}} = Controller.index(:conn, %{"name" => "Charlie"})
    end

    test "returns {:error, params_changeset: %Ecto.Changeset{}} when params are invalid" do
      defmodule DemoWeb.PageBController do
        use CozyParams.PhoenixController

        params :index do
          field :name, :string, required: true
        end

        def index(conn, params) do
          {conn, params}
        end
      end

      alias DemoWeb.PageBController, as: Controller

      assert {:error, params_changeset: %Ecto.Changeset{valid?: false}} =
               Controller.index(:conn, %{})
    end
  end
end
