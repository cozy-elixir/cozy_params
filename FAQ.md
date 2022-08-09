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
