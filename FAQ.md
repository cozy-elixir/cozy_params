# FAQ

## How to expand the capabilities of schemas?

By default, `CozyParams` just:

- cast types.
- validate required fields.

But, people usually expect more.

The easiest way is to override `changeset/2` in a schema. For example:

```elixir
defmodule GoodParamsWithInlineSyntax do
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

  def changeset(struct, params) do
    struct
    |> super(params)
    |> Ecto.Changeset.validate_* # ...
  end
end
```

A harder way is to extend `CozyParams.Schema` at AST level, which requires you to improve `CozyParams.Schema.AST`.

## How to handle the errors returned by `CozyParams`?

All checking functions of `CozyParams` will return `{:error, %Ecto.Changest{}}` as error.

You can pattern match the data structure, and convert the changeset as error messages by using `CozyParams.get_error_messages/1`.

For example, in a Phoenix project, you can do that in the fallback controller:

```elixir
defmodule DemoWeb.FallbackController do
  use DemoWeb, :controller

  # ...

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    messages = CozyParams.get_error_messages(changeset)
    # ...
  end

  # ...
end
```
