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
  def get_error_messages(%Ecto.Changeset{changes: changes} = changeset) do
    errors_in_current_changset =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)

    errors_in_nested_changeset =
      changes
      |> Stream.filter(fn {_k, v} -> is_struct(v, Ecto.Changeset) end)
      |> Enum.map(fn {k, v} -> {k, get_error_messages(v)} end)

    Enum.into(
      errors_in_nested_changeset,
      errors_in_current_changset
    )
  end
end
