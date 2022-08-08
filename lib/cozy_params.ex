defmodule CozyParams do
  @moduledoc """
  Expose more user friendly API for underlying modules.
  """

  @doc """
  Defines a function for casting params.

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

  """
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
