defmodule CozyParams.Changeset.Metadata do
  defstruct fields_to_be_pre_casted: [],
            fields_required: [],
            fields_optional: [],
            embeds_required: [],
            embeds_optional: []
end

defmodule CozyParams.Changeset do
  @moduledoc false

  alias CozyParams.Changeset.Metadata

  @doc false
  def cast_and_validate(struct, params, %Metadata{
        fields_to_be_pre_casted: fields_to_be_pre_casted,
        fields_required: fields_required,
        fields_optional: fields_optional,
        embeds_required: embeds_required,
        embeds_optional: embeds_optional
      }) do
    params =
      params
      |> convert_atom_key_to_string_key()
      |> pre_cast(fields_to_be_pre_casted)

    struct
    |> Ecto.Changeset.cast(params, fields_required ++ fields_optional)
    |> Ecto.Changeset.validate_required(fields_required)
    |> cast_embeds(embeds_required, required: true)
    |> cast_embeds(embeds_optional)
  end

  defp convert_atom_key_to_string_key(params) do
    Enum.into(params, %{}, fn
      {k, v} when is_atom(k) -> {to_string(k), v}
      {k, v} -> {k, v}
    end)
  end

  defp pre_cast(params, fields_to_be_pre_casted) do
    fields_to_be_pre_casted
    |> Stream.map(fn
      {k, v} when is_atom(k) -> {to_string(k), v}
      {k, v} -> {k, v}
    end)
    |> Enum.reduce(params, fn {field, func_ast}, acc ->
      if Map.has_key?(params, field) do
        {func, []} = Code.eval_quoted(func_ast)
        update_in(acc, [field], fn value -> apply(func, [value]) end)
      else
        params
      end
    end)
  end

  @doc false
  def apply_action(changeset) do
    changeset
    |> Ecto.Changeset.apply_action(:validate)
    |> case do
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
  def set_metadata(metadata, path, name)
      when path in [
             :fields_required,
             :fields_optional,
             :embeds_required,
             :embeds_optional
           ] and is_atom(name) do
    push_to(metadata, [path], name)
  end

  @doc false
  def set_metadata(metadata, :fields_to_be_pre_casted = path, {name, _pre_cast} = value)
      when is_atom(name) do
    push_to(metadata, [path], value)
  end

  defp push_to(metadata, paths, value) when is_list(paths) do
    paths = Enum.map(paths, &Access.key(&1))
    {_, new} = get_and_update_in(metadata, paths, &{&1, [value | &1]})
    new
  end
end
