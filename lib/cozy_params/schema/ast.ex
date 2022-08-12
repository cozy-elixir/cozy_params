defmodule CozyParams.Schema.AST do
  @moduledoc """
  Process the AST of `cozy_params`.
  """

  @doc """
  Make sure that the AST is always a block.
  """
  def as_block({call, meta, _} = ast) when call != :__block__ do
    {:__block__, meta, [ast]}
  end

  def as_block(ast), do: ast

  @doc """
  Validate if the block meets `cozy_params`'s requirements.

  Although `cozy_params` try its best to emulate the API of `Ecto.Schema`, but it
  doesn't mean that every API of `Ecto.Schema` is supported by `cozy_params`.

  Because of that, `cozy_params` validates the calls before proceeding.
  """
  def validate_block!({:__block__, _meta, args}) do
    Enum.each(args, fn
      {:field, _meta, [_name, _type]} ->
        :ok

      {:field, _meta, [_name, _type, opts]} = ast
      when is_list(opts) ->
        validate_opts!(ast, opts)

      {:embeds_one, _meta, [_name, {:__aliases__, _, _}]} ->
        :ok

      {:embeds_one, _meta, [_name, {:__aliases__, _, _}, opts]} = ast
      when is_list(opts) ->
        validate_opts!(ast, opts)

      {:embeds_one, _meta, [_name, [do: _]]} ->
        :ok

      {:embeds_one, _meta, [_name, opts, [do: _]]} = ast
      when is_list(opts) ->
        validate_opts!(ast, opts)

      {:embeds_many, _meta, [_name, {:__aliases__, _, _}]} ->
        :ok

      {:embeds_many, _meta, [_name, {:__aliases__, _, _}, opts]} = ast
      when is_list(opts) ->
        validate_opts!(ast, opts)

      {:embeds_many, _meta, [_name, [do: _]]} ->
        :ok

      {:embeds_many, _meta, [_name, opts, [do: _]]} = ast
      when is_list(opts) ->
        validate_opts!(ast, opts)

      ast ->
        raise ArgumentError, "invalid macro #{format_fa(ast)} of cozy_params"
    end)
  end

  defp validate_opts!({:field, _, _} = ast, opts) do
    supported_opt_names = [
      # general
      :default,

      # Ecto.Enum
      :values,

      # cozy_params only
      :required,
      :pre_cast
    ]

    Enum.each(opts, fn opt ->
      do_validate_opt!(ast, opt, supported_opt_names)
    end)
  end

  defp validate_opts!(ast, opts) do
    supported_opt_names = [:required]

    Enum.each(opts, fn opt ->
      do_validate_opt!(ast, opt, supported_opt_names)
    end)
  end

  defp do_validate_opt!(ast, {:pre_cast = name, func_ast}, _supported_names) do
    {func, []} = Code.eval_quoted(func_ast)

    unless is_function(func, 1) do
      raise ArgumentError,
            Enum.join(
              [
                "invalid value of option #{inspect(name)} for #{format_fa(ast)} of cozy_params",
                "it must be a unary function"
              ],
              ", "
            )
    end
  end

  defp do_validate_opt!(ast, {name, _}, supported_names) do
    unless name in supported_names do
      raise ArgumentError,
            "invalid option #{inspect(name)} for #{format_fa(ast)} of cozy_params"
    end
  end

  defp format_fa({call, _meta, args}) do
    "#{call}/#{length(args)}"
  end

  @doc """
  Transpile shortcuts of `embeds_one` and `embeds_many`.

  `cozy_params` will transpile code like following one:

  ```elixir
  embeds_one :address, required: true do
    field :latitude, :float, required: true
    field :longtitude, :float, required: true
  end
  ```

  to Ecto supported code:

  ```elixir
  defmodule Address do
    use CozyParams.Schema

    schema do
      field :latitude, :float, required: true
      field :longtitude, :float, required: true
    end
  end

  embeds_one :address, Address
  ```

  """
  def transpile_block(caller_module, {:__block__, meta, args}) do
    {args, modules_to_be_created} =
      Enum.map_reduce(args, [], fn
        # embeds_one name do
        #   ...
        # end
        #
        # embeds_many name do
        #   ...
        # end
        {call, meta, [name, [do: block]]}, acc
        when call in [:embeds_one, :embeds_many] ->
          module_name = to_module_name(caller_module, name)

          {
            {call, meta, [name, module_name]},
            [{module_name, block} | acc]
          }

        # embeds_one name, opts do
        #   ...
        # end
        #
        # embeds_many name, opts do
        #   ...
        # end
        {call, meta, [name, opts, [do: block]]}, acc
        when call in [:embeds_one, :embeds_many] and is_list(opts) ->
          module_name = to_module_name(caller_module, name)

          {
            {call, meta, [name, module_name, opts]},
            [{module_name, block} | acc]
          }

        other, acc ->
          {other, acc}
      end)

    {{:__block__, meta, args}, modules_to_be_created}
  end

  defp to_module_name(caller_module, name) do
    name =
      name
      |> Atom.to_string()
      |> Macro.camelize()
      |> String.to_atom()

    Module.concat(caller_module, name)
  end

  @doc """
  Transform `cozy_params` supported AST to Ecto supported AST.

  Currently, this function will:
  + drop options which are supported by `cozy_params` only. Or, Ecto will report
    invalid option errors.
  """
  def as_ecto_block({:__block__, _meta, _args} = block) do
    Macro.prewalk(block, fn
      original_ast = {:field, _meta, [_name, _type]} ->
        original_ast

      {:field, meta, [name, type, opts]} ->
        {:field, meta, drop_empty_opts([name, type, drop_unsupported_opts(opts)])}

      original_ast = {:embeds_one, _meta, [_name, _schema]} ->
        original_ast

      {:embeds_one, meta, [name, schema, opts]} ->
        {:embeds_one, meta, drop_empty_opts([name, schema, drop_unsupported_opts(opts)])}

      original_ast = {:embeds_many, _meta, [_name, _schema]} ->
        original_ast

      {:embeds_many, meta, [name, schema, opts]} ->
        {:embeds_many, meta, drop_empty_opts([name, schema, drop_unsupported_opts(opts)])}

      other ->
        other
    end)
  end

  defp drop_empty_opts(args) do
    Enum.reject(args, &(&1 == nil))
  end

  defp drop_unsupported_opts(opts) when is_list(opts) do
    unsupported_opts = [:required, :pre_cast]
    opts = Enum.reject(opts, fn {k, _v} -> k in unsupported_opts end)

    cond do
      length(opts) == 0 -> nil
      opts -> opts
    end
  end

  @doc """
  Extract metadata from AST.
  """
  def extract_metadata({:__block__, _, args}) do
    args
    |> Enum.reduce([], fn
      {:field, _, [name, _type]}, acc ->
        [{:field, name, required: false} | acc]

      {:field, _, [name, _type, opts]}, acc ->
        [{:field, name, opts} | acc]

      {call, _, [name, [do: _]]}, acc
      when call in [:embeds_one, :embeds_many] ->
        [{:embeds, name, required: false} | acc]

      {call, _, [name, opts, [do: _]]}, acc
      when call in [:embeds_one, :embeds_many] ->
        [{:embeds, name, opts} | acc]

      {call, _, [name, _schema]}, acc
      when call in [:embeds_one, :embeds_many] ->
        [{:embeds, name, required: false} | acc]

      {call, _, [name, _schema, opts]}, acc
      when call in [:embeds_one, :embeds_many] ->
        [{:embeds, name, opts} | acc]

      _, acc ->
        acc
    end)
    |> Enum.reverse()
  end
end
