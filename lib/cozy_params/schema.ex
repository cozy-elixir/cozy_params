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
    validate_ast!(block)

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

  @supported_ecto_macro_names [:field, :embeds_one, :embeds_many]
  @unsupported_ecto_macro_names [:belongs_to, :has_one, :has_many, :many_to_many, :timestamp]

  defp validate_ast!(ast) do
    Macro.prewalk(ast, fn
      {name, _meta, [_field, _type | _]} when name in @unsupported_ecto_macro_names ->
        raise ArgumentError, message(:unsupported, {name, @supported_ecto_macro_names})

      other ->
        other
    end)
  end

  defp message(:unsupported, {bad_call, supported_calls}) do
    supported_calls_line =
      supported_calls
      |> Enum.map(&inspect/1)
      |> Enum.join(", ")

    "unsupported macro - #{inspect(bad_call)}, only #{supported_calls_line} are supported"
  end

  # strip cozy_params only options, or Ecto will report invalid option error.
  defp strip_ast(ast) do
    Macro.prewalk(ast, fn
      {name, meta, [field, type, opts]} when name in @supported_ecto_macro_names ->
        {name, meta, [field, type, reject_unsupported_opts(opts)]}

      other ->
        other
    end)
  end

  defp reject_unsupported_opts(opts) when is_list(opts) do
    unsupported_opts = [:required]
    Enum.reject(opts, fn {k, _v} -> k in unsupported_opts end)
  end
end
