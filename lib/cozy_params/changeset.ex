defmodule CozyParams.Changeset do
  @moduledoc false

  @doc false
  def cast_and_validate(struct, params, opts \\ []) do
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

  @doc false
  def apply_action(changeset, :struct) do
    changeset
    |> Ecto.Changeset.apply_action(:validate)
    |> case do
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, params_changeset: changeset}

      other ->
        other
    end
  end

  @doc false
  def apply_action(changeset, :map) do
    changeset
    |> Ecto.Changeset.apply_action(:validate)
    |> case do
      {:ok, struct} ->
        {:ok,
         struct
         |> Map.from_struct()
         |> Map.delete(:__meta__)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, params_changeset: changeset}

      other ->
        other
    end
  end

  defp cast_embeds(changeset, names, opts \\ []) do
    Enum.reduce(names, changeset, fn name, acc ->
      Ecto.Changeset.cast_embed(acc, name, opts)
    end)
  end
end
