defmodule CozyParams.Changeset do
  @moduledoc false

  def cast(struct, params, opts \\ []) do
    required_fields = Keyword.fetch!(opts, :required_fields)
    optional_fields = Keyword.fetch!(opts, :optional_fields)

    required_embeds = Keyword.fetch!(opts, :required_embeds)
    optional_embeds = Keyword.fetch!(opts, :optional_embeds)

    struct
    |> Ecto.Changeset.cast(params, required_fields ++ optional_fields)
    |> Ecto.Changeset.validate_required(required_fields)
    |> cast_embeds(required_embeds, required: true)
    |> cast_embeds(optional_embeds)
  end

  defp cast_embeds(changeset, names, opts \\ []) do
    Enum.reduce(names, changeset, fn name, acc ->
      Ecto.Changeset.cast_embed(acc, name, opts)
    end)
  end
end
