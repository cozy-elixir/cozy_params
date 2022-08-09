defmodule CozyParams.PhoenixController do
  @moduledoc """
  Providing macros for integrating with [Phoenix](https://github.com/phoenixframework/phoenix) controllers.

  Inspired by [elixir-maru/maru_params](https://github.com/elixir-maru/maru_params).

  ## Examples

  Extend just a controller:

  ```elixir
  defmodule DemoWeb.PageController do
    use DemoWeb, :controller
    use CozyParams.PhoenixController

    params :index do
      field :name, :string, required: true
    end

    def index(conn, params) do
      # + when external params is valid, `params` will be converted as a map with atom keys.
      # + when external params is invalid, an `{:error, %Ecto.Changeset{}}` will be returned,
      #   which allows developers to handle it in the fallback controller.
    end
  end
  ```

  Extend all controllers:

  ```elixir
  defmodule DemoWeb do
    # ...
    def controller do
      quote do
        use Phoenix.Controller, namespace: DemoWeb
        # ...

        use CozyParams.PhoenixController
      end
    end
  end

  defmodule DemoWeb.PageController do
    use DemoWeb, :controller

    params :index do
      field :name, :string, required: true
    end

    def index(conn, params) do
      # + when external params is valid, `params` will be converted as a map with atom keys.
      # + when external params is invalid, an `{:error, %Ecto.Changeset{}}` will be returned,
      #   which allows developers to handle it in the fallback controller.
    end
  end
  ```

  For more details of the schema definations in `do: block`, check out `CozyParams.Schema`.

  """
  @doc since: "0.1.0"

  defmacro __using__(_) do
    quote do
      Module.register_attribute(__MODULE__, :actions, accumulate: true)
      import unquote(__MODULE__), only: [params: 2]
      @before_compile unquote(__MODULE__)
    end
  end

  @doc """
  Defines params for a given `action`.
  """
  @doc since: "0.1.0"
  defmacro params(action, do: block) when is_atom(action) do
    module_name = to_module_name(__CALLER__.module, action)

    contents =
      quote do
        use CozyParams.Schema

        schema do
          unquote(block)
        end
      end

    Module.create(module_name, contents, Macro.Env.location(__CALLER__))

    quote do
      @actions {unquote(action), unquote(module_name)}
    end
  end

  defp to_module_name(caller_module, name) do
    namespace_for_cozy_params = __MODULE__

    Module.concat([caller_module, namespace_for_cozy_params, Macro.camelize("#{name}")])
  end

  defmacro __before_compile__(%Macro.Env{module: module}) do
    module
    |> Module.get_attribute(:actions)
    |> Enum.map(fn {action, module_name} ->
      quote do
        defoverridable [{unquote(action), 2}]

        def unquote(action)(conn, params) do
          with {:ok, params} <- apply(unquote(module_name), :from, [params, [type: :map]]) do
            super(conn, params)
          end
        end
      end
    end)
  end
end
