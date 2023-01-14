defmodule CozyParams.Schema do
  @moduledoc ~S"""
  Provides macros for defining schemas which is used for casting and validating params.

  > Due to limitations of implementation, it's impossible to document every supported
  > macros within `@doc`. Because of that, I will try to best to document them
  > within `@moduledoc`.

  ## Available macros

  `CozyParams.Schema` provides a subset of macros supported by Ecto, In addition,
  it makes some changes on `embeds_one` and `embeds_many`.

  In a nutshell, all available macros are:

  1. `schema(do: block)`
  2. `field(name, type, opts \\ [])`
     - available `opts`:
       - `:default`
       - `:required` - default: `false`
       - `:pre_cast` - specify a unary function to process data before casting
  3. `embeds_one(name, opts \\ [], do: block)`
     - available `opts`:
       - `:required` - default: `false`
  4. `embeds_one(name, schema, opts \\ [])`
     - available `opts`:
       - `:required` - default: `false`
  5. `embeds_many(name, opts \\ [], do: block)`
     - available `opts`:
       - `:required` - default: `false`
  6. `embeds_many(name, schema, opts \\ [])`
     - available `opts`:
       - `:required` - default: `false`

  > `type` argument will be passed to `Ecto.Schema`, so it supports all the types supported
  > by `Ecto.Schema` in theory.
  > Read *Types and casting* section of `Ecto.Schema` to get more information.

  ## Examples

  There're 2 ways to define a schema:
  1. use inline syntax
  2. use extra modules

  ### Define a schema contains embedded fields in inline syntax:

  ```elixir
  defmodule PersonParams do
    use CozyParams.Schema

    schema do
      field :name, :string, required: true
      field :age, :integer
      field :wishlist, {:array, :string}, pre_cast: &String.split(&1, ~r/,\s*/)

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

  PersonParams.from(%{
    name: "Charlie",
    mate: %{
      name: "Lucy"
    },
    wishlist: "table,chair,computer"
  })
  ```


  ### Define a schema contains embedded fields with extra modules:

  ```elixir
  defmodule PersonParams do
    use CozyParams.Schema

    defmodule Mate do
      use CozyParams.Schema

      schema do
        field :name, :string, required: true
        field :age, :integer
        field :wishlist, {:array, :string}, pre_cast: &String.split(&1, ~r/,\s*/)
      end
    end

    defmodule Pet do
      use CozyParams.Schema

      schema do
        field :name, :string, required: true
        field :breed, :string
      end
    end

    schema do
      field :name, :string, required: true
      field :age, :integer
      embeds_one :mate, Mate, required: true
      embeds_many :pets, Pet
    end
  end

  PersonParams.from(%{
    name: "Charlie",
    mate: %{
      name: "Lucy"
    },
    wishlist: "table,chair,computer"
  })
  ```

  ## About the generated functions

  `schema/1` will create 2 functions automatically:

  1. `changeset/2` which is overridable.
  2. `from/1` which will be called by high-level abstractions, such as `CozyParams`.

  ## Reflection

  Schemas will generate the following functions that can be used for runtime
  introspection of the schema:

  + `__cozy_params_schema__/0`
  + `__cozy_params_schema__/1`
  + `__cozy_params_changeset__/0`
  + `__cozy_params_changeset__/1`

  All possible calls:

  + `__cozy_params_schema__()` - an alias of `__cozy_params_schema__(:metadata)`.
  + `__cozy_params_schema__(:metadata)` - returns the metadata of current schema.
  + `__cozy_params_schema__(:original_ast)` - returns the original AST passed to `schema/1`.
  + `__cozy_params_schema__(:transpiled_ast)` - returns the transpiled AST used by `cozy_params`.
  + `__cozy_params_schema__(:ecto_ast)` - returns the AST used by Ecto.
  + `__cozy_params_changeset__()` - an alias of `__cozy_params_changeset__(:metadata)`.
  + `__cozy_params_changeset__(:metadata)` - returns the metadata used by `CozyParams.Changeset`.

  """
  @moduledoc since: "0.1.0"

  alias CozyParams.Schema.AST

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      import unquote(__MODULE__), only: [schema: 1]
    end
  end

  @doc since: "0.1.0"
  # Disable credo check of cyclomatic complexity
  # credo:disable-for-next-line
  defmacro schema(do: block) do
    caller_module = __CALLER__.module
    caller_line = __CALLER__.line

    block = AST.as_block(block)

    AST.validate_block!(block)
    Module.put_attribute(caller_module, :cozy_params_schema_original_ast, block)

    {transpiled_block, modules_to_be_created} = AST.transpile_block(caller_module, block)
    Module.put_attribute(caller_module, :cozy_params_schema_transpiled_ast, transpiled_block)

    ecto_block = AST.as_ecto_block(transpiled_block)
    Module.put_attribute(caller_module, :cozy_params_schema_ecto_ast, ecto_block)

    schema_metadata = AST.extract_metadata(block)
    Module.put_attribute(caller_module, :cozy_params_schema_metadata, schema_metadata)

    changeset_metadata = to_changeset_metadata(schema_metadata)
    Module.put_attribute(caller_module, :cozy_params_changeset_metadata, changeset_metadata)

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
      if line = Module.get_attribute(__MODULE__, :cozy_params_schema_defined) do
        raise "schema already defined for #{inspect(__MODULE__)} on line #{line}"
      end

      @cozy_params_schema_defined unquote(caller_line)

      @primary_key false
      embedded_schema do
        unquote(ecto_block)
      end

      def changeset(struct, params) do
        CozyParams.Changeset.cast_and_validate(
          struct,
          params,
          @cozy_params_changeset_metadata
        )
      end

      defoverridable changeset: 2

      def from(params) do
        __MODULE__
        |> struct
        |> changeset(params)
        |> CozyParams.Changeset.apply_action(@cozy_params_changeset_metadata)
      end

      def __cozy_params_schema__(), do: __cozy_params_schema__(:metadata)
      def __cozy_params_schema__(:metadata), do: @cozy_params_schema_metadata
      def __cozy_params_schema__(:original_ast), do: @cozy_params_schema_original_ast
      def __cozy_params_schema__(:transpiled_ast), do: @cozy_params_schema_transpiled_ast
      def __cozy_params_schema__(:ecto_ast), do: @cozy_params_schema_ecto_ast

      def __cozy_params_changeset__(), do: __cozy_params_changeset__(:metadata)
      def __cozy_params_changeset__(:metadata), do: @cozy_params_changeset_metadata
    end
  end

  defp to_changeset_metadata(schema_metadata) do
    alias CozyParams.Changeset

    Enum.reduce(schema_metadata, Changeset.new_metadata(), fn
      {:field, name, opts}, metadata ->
        metadata =
          if opts[:required],
            do: Changeset.set_metadata(metadata, :fields_required, name),
            else: Changeset.set_metadata(metadata, :fields_optional, name)

        metadata =
          if pre_cast_func = opts[:pre_cast],
            do: Changeset.set_metadata(metadata, :fields_to_be_pre_casted, {name, pre_cast_func}),
            else: metadata

        if Keyword.has_key?(opts, :default),
          do: Changeset.set_metadata(metadata, :fields_with_default, name),
          else: metadata

      {:embeds, name, opts}, metadata ->
        if opts[:required],
          do: Changeset.set_metadata(metadata, :embeds_required, name),
          else: Changeset.set_metadata(metadata, :embeds_optional, name)

      _, metadata ->
        metadata
    end)
  end
end
