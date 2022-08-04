defmodule CozyParams.Schema do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote do
      unquote(__use__(:ecto))
      import unquote(__MODULE__), only: [schema: 1]
    end
  end

  defp __use__(:ecto) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
    end
  end

  defmacro schema(do: block) do
    caller_module = __CALLER__.module
    Module.put_attribute(caller_module, :cozy_params_schema, block)

    quote do
      @primary_key false
      embedded_schema do
        unquote(block)
      end

      def __cozy_params_schema__(), do: @cozy_params_schema
    end
  end
end
