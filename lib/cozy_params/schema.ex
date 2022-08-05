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
    Module.put_attribute(caller_module, :cozy_params_schema_origin, block)

    ecto_block =
      block
      |> transpile_shortcuts()
      |> strip_invalid_ecto_options()

    Module.put_attribute(caller_module, :cozy_params_schema_ecto, ecto_block)

    quote do
      @primary_key false
      embedded_schema do
        unquote(ecto_block)
      end

      def __cozy_params_schema__(:origin), do: @cozy_params_schema_origin
      def __cozy_params_schema__(:ecto), do: @cozy_params_schema_ecto
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

  # Transpile shortcuts for `embeds_one` and `embeds_many`.
  #
  # For example, following code it's not supported by Ecto, but it's supported by cozy_params, but
  #
  # embeds_one :address, required: true do
  #   field :latitude, :float, required: true
  #   field :longtitude, :float, required: true
  # end
  #
  # It will be transpiled as:
  #
  # embeds_one :address, Address, required: true do
  #   field :latitude, :float, required: true
  #   field :longtitude, :float, required: true
  # end
  #
  # which is supported by Ecto.
  #
  defp transpile_shortcuts(ast) do
    Macro.prewalk(ast, fn
      {:embeds_one, meta, [field, [do: _] = do_block]} ->
        {:embeds_one, meta, [field, {:__aliases__, [], [camelize_field(field)]}, do_block]}

      {:embeds_one, meta, [field, opts, [do: _] = do_block]} when is_list(opts) ->
        {:embeds_one, meta, [field, {:__aliases__, [], [camelize_field(field)]}, opts, do_block]}

      {:embeds_many, meta, [field, [do: _] = do_block]} ->
        {:embeds_many, meta, [field, {:__aliases__, [], [camelize_field(field)]}, do_block]}

      {:embeds_many, meta, [field, opts, [do: _] = do_block]} when is_list(opts) ->
        {:embeds_many, meta, [field, {:__aliases__, [], [camelize_field(field)]}, opts, do_block]}

      other ->
        other
    end)
  end

  defp camelize_field(field) do
    field
    |> Atom.to_string()
    |> Macro.camelize()
    |> String.to_atom()
  end

  # Strip cozy_params only options, or Ecto will report invalid option error.
  defp strip_invalid_ecto_options(ast) do
    Macro.prewalk(ast, fn
      {:field, meta, [field, type, opts]} ->
        {:field, meta, reject_unless_args([field, type, reject_unsupported_opts(opts)])}

      {:embeds_one, meta, [field, schema, opts_or_do_block]} ->
        {:embeds_one, meta,
         reject_unless_args([field, schema, reject_unsupported_opts(opts_or_do_block)])}

      {:embeds_one, meta, [field, schema, opts, [do: _] = do_block]} ->
        {:embeds_one, meta,
         reject_unless_args([field, schema, reject_unsupported_opts(opts), do_block])}

      {:embeds_many, meta, [field, schema, opts_or_do_block]} ->
        {:embeds_many, meta,
         reject_unless_args([field, schema, reject_unsupported_opts(opts_or_do_block)])}

      {:embeds_many, meta, [field, schema, opts, [do: _] = do_block]} ->
        {:embeds_many, meta,
         reject_unless_args([field, schema, reject_unsupported_opts(opts), do_block])}

      other ->
        other
    end)
  end

  def reject_unless_args(args) do
    Enum.reject(args, &(&1 == nil))
  end

  defp reject_unsupported_opts(opts) when is_list(opts) do
    unsupported_opts = [:required]
    opts = Enum.reject(opts, fn {k, _v} -> k in unsupported_opts end)

    cond do
      length(opts) == 0 -> nil
      opts -> opts
    end
  end
end
