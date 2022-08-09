# CozyParams

[![Actions Status](https://github.com/c4710n/cozy_params/workflows/build/badge.svg)](https://github.com/c4710n/cozy_params/actions)

Provides Ecto-like API for casting and validating params.

## Why?

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

The package can be installed by adding `cozy_params` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cozy_params, "~> 0.1.0"}
  ]
end
```

And, it's encouraged to setup `.formatter.exs` for `cozy_params`:

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

- At the lowest level, `CozyParams.Schema` does all the hard work. (Generally, you have no need to use it)
- At the high level, `CozyParams` provides neat macros for developers' happiness.
- For better integration with other libraries, following modules are provided:
  - `CozyParams.PhoenixController`
  - ...

## Usage

### define a params module with inline syntax

```elixir
defmodule Params do
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
```

### define a params module with extra modules

```elixir
defmodule GoodParamsWithCrossModuleDefinitions do
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
```

## `CozyParams.Schema`

1. `schema(do: block)`
2. `field(name, type, opts \\ [])`
   - available `opts`:
     - `:default`
     - `:autogenerate`
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

## `CozyParams.PhoenixController`

```elixir
defmodule DemoWeb.PageController do
  use DemoWeb, :controller
  use CozyParams.PhoenixController
end
```

Helper for [Phoenix](https://github.com/phoenixframework/phoenix)

## Helper for extracting error messages from `%Ecto.Changeset{}`

TODO

## License

Apache License 2.0
