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
    stripped_block = strip_ast(block)

    quote do
      @primary_key false
      embedded_schema do
        unquote(stripped_block)
      end

      def __cozy_params_schema__(), do: @cozy_params_schema
    end
  end

  # strip cozy_params only options, or Ecto will report invalid option error.
  defp strip_ast(ast) do
    Macro.prewalk(ast, fn
      {call, meta, [name, type, opts]} when call in [:field, :embeds_one, :embeds_many] ->
        {call, meta, [name, type, reject_unsupported_opts(opts)]}

      other ->
        other
    end)
  end

  defp reject_unsupported_opts(opts) when is_list(opts) do
    unsupported_opts = [:required]
    Enum.reject(opts, fn {k, _v} -> k in unsupported_opts end)
  end
end
