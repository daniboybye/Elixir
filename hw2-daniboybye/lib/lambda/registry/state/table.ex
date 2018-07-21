defmodule Lambda.Registry.State.Table do
  defstruct memoization: %{}, in_processing: %{}

  def fetch_cached(%__MODULE__{memoization: cache}, args) do
    case Map.fetch(cache, args) do
      {:ok, _} = x -> x
      :error -> {:error, :not_cached}
    end
  end

  def clear_cache(%__MODULE__{memoization: cache} = table, args) do
    cache
    |> Map.delete(args)
    |> (&%__MODULE__{table | memoization: &1}).()
  end

  def in_processing(%__MODULE__{in_processing: map}, args, time) do
    Map.fetch(map, {time, args})
  end

  def put_in_processing(%__MODULE__{in_processing: map} = table, args, time, ref) do
    map
    |> Map.put({time, args}, ref)
    |> (&%__MODULE__{table | in_processing: &1}).()
  end

  def remove_from_processing(%__MODULE__{in_processing: map} = table, args, time) do
    map
    |> Map.delete({time, args})
    |> (&%__MODULE__{table | in_processing: &1}).()
  end

  def save(%__MODULE__{memoization: cache} = table, args, {:ok, result}) do
    cache
    |> Map.put(args, result)
    |> (&%__MODULE__{table | memoization: &1}).()
  end

  def save(%__MODULE__{} = table, _, _), do: table
end
