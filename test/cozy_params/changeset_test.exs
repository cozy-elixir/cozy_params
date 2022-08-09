defmodule CozyParams.ChangesetTest do
  use ExUnit.Case
  doctest CozyParams.Schema

  describe "error_messages/1" do
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
             } == CozyParams.Changeset.get_error_messages(changeset)
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
               CozyParams.Changeset.get_error_messages(changeset)
    end
  end
end
