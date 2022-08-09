# CozyParams

[![Actions Status](https://github.com/c4710n/cozy_params/workflows/build/badge.svg)](https://github.com/c4710n/cozy_params/actions)

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

Add `cozy_params` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cozy_params, "~> 0.1.0"}
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
- For better integration with other libraries:
  - `CozyParams.PhoenixController` - providing macros for integrating with [Phoenix](https://github.com/phoenixframework/phoenix) controllers.
  - ...
- `CozyParams.Schema` - the module at lowest level. Generally, you don't use it directly.

Visit [HexDocs](https://hexdocs.pm/cozy_params) for more details.

## uhhh... I don't like it

You can try:

- [params](https://github.com/vic/params)
- [maru_params](https://github.com/elixir-maru/maru_params)
- [tarams](https://github.com/bluzky/tarams)
- [`params.ex` from imranismail](https://gist.github.com/imranismail/eb60c709b230c1cbf344553888b9387d)

Find more at [hex.pm](https://hex.pm/packages?search=params&sort=recent_downloads).

## License

Apache License 2.0
