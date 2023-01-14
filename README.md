# CozyParams

[![CI](https://github.com/cozy-elixir/cozy_params/actions/workflows/ci.yml/badge.svg)](https://github.com/cozy-elixir/cozy_params/actions/workflows/ci.yml)

Provides Ecto-like API for casting and validating params.

## Why another package?

There are some packages in the community:

| NAME                                                      | Based on Ecto? | Use Ecto-like API? |
| --------------------------------------------------------- | -------------- | ------------------ |
| [params](https://github.com/vic/params)                   | YES            | NO                 |
| [maru_params](https://github.com/elixir-maru/maru_params) | NO             | NO                 |
| [tarams](https://github.com/bluzky/tarams)                | NO             | NO                 |
| ...                                                       |                |                    |

But, they don't fit my requirements. The package in my dream should:

- be based on [Ecto](https://github.com/elixir-ecto/ecto) which is robust and battle-tested.
- use Ecto-like API, which eliminates friction when working on casting params and modeling data source at the same time.

## Installation

Add `cozy_params` to the list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cozy_params, version}
  ]
end
```

(Optional) And, it's encouraged to setup `.formatter.exs` for `cozy_params`:

```elixir
[
  import_deps: [
    # ...
    :cozy_params
  ],
  # ...
]
```

## Overview

- `CozyParams` - provides macros for general usage.
- `CozyParams.Schema` - provides macros for defining schemas directly.

An example integrating with Phoenix:

```elixir
defmodule DemoWeb.PageController do
  use DemoWeb, :controller
  import CozyParams

  action_fallback DemoWeb.FallbackController

  defparams :product_search do
    field :name, :string, required: true

    embeds_many :tags do
      field :name, :string, required: true
    end
  end

  def index(conn, params) do
    with {:ok, data} <- product_search(params) do
      # ...
    end
  end
end

defmodule DemoWeb.FallbackController do
  use DemoWeb, :controller

  # ...

  # handle errors for cozy_params
  def call(conn, {:error, params_changeset: %Ecto.Changeset{} = changeset}) do
    messages = CozyParams.get_error_messages(changeset)
    # render messages in HTML, JSON, etc.
  end

  # handle errors for normal changsets from Ecto.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    # ...
  end

  # ...
end
```

Visit [HexDocs](https://hexdocs.pm/cozy_params) for more details.

## License

Apache License 2.0
