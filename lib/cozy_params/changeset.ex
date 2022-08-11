defmodule CozyParams.Changeset.Metadata do
  defstruct fields_required: [],
            fields_optional: [],
            embeds_required: [],
            embeds_optional: []
end

defmodule CozyParams.Changeset do
  @moduledoc false

  alias CozyParams.Changeset.Metadata

  @doc false
  def cast_and_validate(struct, params, %Metadata{
        fields_required: fields_required,
        fields_optional: fields_optional,
        embeds_required: embeds_required,
        embeds_optional: embeds_optional
      }) do
    struct
    |> Ecto.Changeset.cast(params, fields_required ++ fields_optional)
    |> Ecto.Changeset.validate_required(fields_required)
    |> cast_embeds(embeds_required, required: true)
    |> cast_embeds(embeds_optional)
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

  @doc false
  def new_metadata(), do: %Metadata{}

  @doc false
  def set_metadata(metadata, key, name)
      when key in [
             :fields_required,
             :fields_optional,
             :embeds_required,
             :embeds_optional
           ] and is_atom(name) do
    push_to(metadata, [key], name)
  end

  defp push_to(metadata, paths, value) when is_list(paths) do
    paths = Enum.map(paths, &Access.key(&1))
    {_, new} = get_and_update_in(metadata, paths, &{&1, [value | &1]})
    new
  end
end
