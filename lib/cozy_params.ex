defmodule CozyParams do
  @moduledoc """
  Expose more user friendly API for underlying modules.
  """
  @moduledoc since: "0.1.0"

  @doc """
  Defines a function for casting and validating params.

  > Essentially, this macro is just a shortcut for using `CozyParams.Schema`.

  Inspired by [vic/params](https://github.com/vic/params).

  ## Examples

  ```elixir
  defmodule Demo do
    import CozyParams

    defparams :product_search do
      field :name, :string, required: true
    end

    def search(params) do
      with {:ok, data} <- product_search(params) do
        # process data
      end
    end
  end
  ```

  Above `defparams :product_search do: block` will:
  1. create a module `Demo.CozyParams.ProductSearch` automatically.
  2. inject `product_search/1` and `product_search/2` into current module. And, these
     two functions will call `Demo.CozyParams.ProductSearch.from` internally.

  For more details of the schema definations in `do: block`, check out `CozyParams.Schema`.

  > `defparams` can be used in any module, not limited to Phoenix controllers.
  >
  > In order to demonstrate this point, above example is using an normal `Demo` module,
  > instead of a Phoenix controller.
  >
  > For better integration with Phoenix controllers, check out `CozyParams.PhoenixController`.

  """
  @doc since: "0.1.0"
  defmacro defparams(name, do: block) when is_atom(name) do
    module_name = to_module_name(__CALLER__.module, name)

    contents =
      quote do
        use CozyParams.Schema

        schema do
          unquote(block)
        end
      end

    Module.create(module_name, contents, Macro.Env.location(__CALLER__))

    quote do
      def unquote(name)(params, opts \\ []) do
        unquote(module_name).from(params, opts)
      end
    end
  end

  defp to_module_name(caller_module, name) do
    namespace_for_cozy_params = __MODULE__

    Module.concat([caller_module, namespace_for_cozy_params, Macro.camelize("#{name}")])
  end
end
