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
  2. inject `product_search/1` into current module. And, this function
     will call `Demo.CozyParams.ProductSearch.from/1` internally.

  For more details of the schema definitions in `do: block`, check out `CozyParams.Schema`.

  ## Error handling

  When external params are invalid, `{:error, params_changeset: %Ecto.Changeset{}}`
  will be returned, which allows developers to match this pattern for handling errors.

  If the error messages is required, `CozyParams.get_error_messages/1` would be helpful.
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
      def unquote(name)(params) do
        unquote(module_name).from(params)
      end
    end
  end

  defp to_module_name(caller_module, name) do
    namespace_for_cozy_params = __MODULE__

    Module.concat([caller_module, namespace_for_cozy_params, Macro.camelize("#{name}")])
  end

  @doc """
  Extract error messages from `%Ecto.Changeset{}`.
  """
  @doc since: "0.1.0"
  def get_error_messages(%Ecto.Changeset{} = changeset) do
    get_error_messages(changeset, &default_msg/1)
  end

  @doc """
  Extract error messages from `%Ecto.Changeset{}` with a given function.

  The `msg_func` will be passed to `Ecto.Changeset.traverse_errors/2`, read doc of
  `Ecto.Changeset.traverse_errors/2` for more information.
  """
  @doc since: "1.1.0"
  def get_error_messages(%Ecto.Changeset{changes: changes} = changeset, msg_func) do
    errors_in_current_changset = Ecto.Changeset.traverse_errors(changeset, msg_func)

    errors_in_nested_changeset =
      changes
      |> Stream.filter(fn {_k, v} -> is_struct(v, Ecto.Changeset) end)
      |> Enum.map(fn {k, v} -> {k, get_error_messages(v)} end)

    Enum.into(
      errors_in_nested_changeset,
      errors_in_current_changset
    )
  end

  defp default_msg({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
