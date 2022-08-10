# FAQ

## How to integrate with Phoenix?

### casting and validating params

```elixir
defmodule DemoWeb.PageController do
  use DemoWeb, :controller
  import CozyParams

  defparams :product_search do
    field :name, :string, required: true
  end

  def index(conn, params) do
    with {:ok, data} <- product_search(params) do
      # when external params are invalid, `{:error, params_changeset: %Ecto.Changeset{}}`
      # will be returned.
    end
  end
end
```

### error handling

As mentioned above, when external params are invalid, `{:error, params_changeset: %Ecto.Changeset{}}` will be returned, which allows developers to match this pattern in the fallback controller, and convert the changeset as error messages by using `CozyParams.get_error_messages/1`.

For example:

```elixir
defmodule DemoWeb.PageController do
  use DemoWeb, :controller
  import CozyParams

  action_fallback DemoWeb.FallbackController

  defparams :product_search do
    field :name, :string, required: true
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

## How to expand the capabilities of schemas?

By default, `CozyParams` just:

- casts types of fields.
- validates presence of fields.

But, people usually expect more, such as validating format, etc.

The easiest way is to override `changeset/2` in a schema. For example:

```elixir
defmodule SampleParams do
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
