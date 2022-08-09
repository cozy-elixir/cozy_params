defmodule CozyParams.Schema do
  @moduledoc false

  alias CozyParams.Schema.AST

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      import unquote(__MODULE__), only: [schema: 1]
    end
  end

  defmacro schema(do: block) do
    caller_module = __CALLER__.module

    block = AST.as_block(block)

    AST.validate_block!(block)
    Module.put_attribute(caller_module, :cozy_params_schema_original, block)

    {transpiled_block, modules_to_be_created} = AST.transpile_block(caller_module, block)
    Module.put_attribute(caller_module, :cozy_params_schema_transpiled, transpiled_block)

    ecto_block = AST.as_ecto_block(transpiled_block)
    Module.put_attribute(caller_module, :cozy_params_schema_ecto, ecto_block)

    %{
      required: required_fields,
      optional: optional_fields
    } = AST.extract_fields(block)

    Module.put_attribute(caller_module, :required_fields, required_fields)
    Module.put_attribute(caller_module, :optional_fields, optional_fields)

    %{
      required: required_embeds,
      optional: optional_embeds
    } = AST.extract_embeds(block)

    Module.put_attribute(caller_module, :required_embeds, required_embeds)
    Module.put_attribute(caller_module, :optional_embeds, optional_embeds)

    for {module_name, module_schema_block} <- modules_to_be_created do
      contents =
        quote do
          use unquote(__MODULE__)

          schema do
            unquote(module_schema_block)
          end
        end

      Module.create(module_name, contents, Macro.Env.location(__CALLER__))
    end

    quote do
      @primary_key false

      embedded_schema do
        unquote(ecto_block)
      end

      def changeset(struct, params) do
        CozyParams.Changeset.cast_and_validate(struct, params,
          required_fields: @required_fields,
          optional_fields: @optional_fields,
          required_embeds: @required_embeds,
          optional_embeds: @optional_embeds
        )
      end

      defoverridable changeset: 2

      def from(params, opts \\ []) do
        type = Keyword.get(opts, :type, :struct)

        __MODULE__
        |> struct
        |> changeset(params)
        |> CozyParams.Changeset.validate(type)
      end

      def __cozy_params_schema__(), do: __cozy_params_schema__(:original)
      def __cozy_params_schema__(:original), do: @cozy_params_schema_original
      def __cozy_params_schema__(:transpiled), do: @cozy_params_schema_transpiled
      def __cozy_params_schema__(:ecto), do: @cozy_params_schema_ecto
    end
  end
end
