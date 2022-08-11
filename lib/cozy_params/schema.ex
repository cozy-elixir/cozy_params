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

  Define a schema contains embedded fields in inline syntax:

  ```elixir
  defmodule PersonParams do
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

  PersonParams.from(%{})
  ```


  Define a schema contains embedded fields with extra modules:

  ```elixir
  defmodule PersonParams do
    use CozyParams.Schema

    defmodule Mate do
      use CozyParams.Schema

      schema do
        field :name, :string, required: true
        field :age, :integer
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

  PersonParams.from(%{})
  ```

  ## About the generated functions

  `schema/1` will create 2 functions automatically:

  1. `changeset/2` which is overridable.
  2. `from/1` / `from/2` which will be called by high-level abstractions, such as
     `CozyParams`.

  You can specify the type of return value of `from/2`:

  ```elixir
  PersonParams.from(%{}, type: :struct) # %PersonParams{}
  PersonParams.from(%{}, type: :map)    # %{}
  ```

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
  defmacro schema(do: block) do
    caller_module = __CALLER__.module
    caller_line = __CALLER__.line

    block = AST.as_block(block)

    AST.validate_block!(block)
    Module.put_attribute(caller_module, :cozy_params_schema_original, block)

    {transpiled_block, modules_to_be_created} = AST.transpile_block(caller_module, block)
    Module.put_attribute(caller_module, :cozy_params_schema_transpiled, transpiled_block)

    ecto_block = AST.as_ecto_block(transpiled_block)
    Module.put_attribute(caller_module, :cozy_params_schema_ecto, ecto_block)

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

      def from(params, opts \\ []) do
        type = Keyword.get(opts, :type, :struct)

        __MODULE__
        |> struct
        |> changeset(params)
        |> CozyParams.Changeset.apply_action(type)
      end

      def __cozy_params_schema__(), do: __cozy_params_schema__(:metadata)
      def __cozy_params_schema__(:metadata), do: @cozy_params_schema_metadata
      def __cozy_params_schema__(:original), do: @cozy_params_schema_original
      def __cozy_params_schema__(:transpiled), do: @cozy_params_schema_transpiled
      def __cozy_params_schema__(:ecto), do: @cozy_params_schema_ecto

      def __cozy_params_changeset__(), do: __cozy_params_changeset__(:metadata)
      def __cozy_params_changeset__(:metadata), do: @cozy_params_changeset_metadata
    end
  end

  defp to_changeset_metadata(schema_metadata) do
    alias CozyParams.Changeset

    Enum.reduce(schema_metadata, Changeset.new_metadata(), fn
      {:field, name, opts}, metadata ->
        if opts[:required],
          do: Changeset.set_metadata(metadata, :fields_required, name),
          else: Changeset.set_metadata(metadata, :fields_optional, name)

      {:embeds, name, opts}, metadata ->
        if opts[:required],
          do: Changeset.set_metadata(metadata, :embeds_required, name),
          else: Changeset.set_metadata(metadata, :embeds_optional, name)

      _, metadata ->
        metadata
    end)
  end
end
