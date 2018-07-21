defmodule Lambda.Registry.State do
  alias __MODULE__.Table

  defstruct tables: %{}, lambda_in_processing: %{}

  def get_table(%__MODULE__{tables: tables}, module, func) do
    Map.get(tables, {module, func})
  end

  @doc """
    if the function has already been registered, nothing will change
  """
  def register(%__MODULE__{tables: tables} = state, module, func) do
    tables
    |> Map.put_new({module, func}, %Table{})
    |> (&%__MODULE__{state | tables: &1}).()
  end

  @doc """
    if the function unregister while processing
    this will not affect the returned result,
    it will not keep
  """
  def unregister(%__MODULE__{tables: tables} = state, module, func) do
    tables
    |> Map.delete({module, func})
    |> (&%__MODULE__{state | tables: &1}).()
  end

  def fetch_cached(%__MODULE__{} = state, module, func, args) do
    state
    |> get_table(module, func)
    |> fetch_cached(args)
  end

  def fetch_cached(nil, _), do: {:error, :not_registered}

  def fetch_cached(table, args), do: Table.fetch_cached(table, args)

  def clear_cache(%__MODULE__{tables: tables} = state, module, func) do
    tables
    |> map_update({module, func}, %Table{})
    |> (&%__MODULE__{state | tables: &1}).()
  end

  def clear_cache(%__MODULE__{tables: tables} = state, module, func, args) do
    tables
    |> map_update_lazy({module, func}, &Table.clear_cache(&1, args))
    |> (&%__MODULE__{state | tables: &1}).()
  end

  def run(
        %__MODULE__{tables: tables, lambda_in_processing: map},
        table,
        module,
        func,
        args,
        time,
        from
      ) do
    %Task{ref: ref, pid: pid} =
      Task.Supervisor.async_nolink(
        Lambda.TaskSupervisor,
        module, func, args
      )

    Task.Supervisor.start_child(
        Lambda.TaskSupervisor,
        fn ->
        Process.sleep(time) 
        Process.exit(pid, :kill) 
        end
      )
    
    table
    |> Table.put_in_processing(args, time, ref)
    |> (&Map.put(tables, {module, func}, &1)).()
    |> (&%__MODULE__{
          tables: &1,
          lambda_in_processing: Map.put(map, ref, [from, {module, func, args, time}])
        }).()
  end

  def add_in_processing(%__MODULE__{lambda_in_processing: map} = state, ref, from) do
    map
    |> Map.update!(ref, &[from | &1])
    |> (&%__MODULE__{state | lambda_in_processing: &1}).()
  end

  def handle_result(%__MODULE__{tables: tables, lambda_in_processing: map} = state, ref, result) do
    with {list, map} <- Map.pop(map, ref),
         {{module, func, args, time}, recipients} <- List.pop_at(list, -1),
         _ <- Enum.map(recipients, &GenServer.reply(&1, result)) do
      tables
      |> map_update_lazy(
        {module, func},
        &(Table.remove_from_processing(&1, args, time)
          |> Table.save(args, result))
      )
      |> (&%__MODULE__{tables: &1, lambda_in_processing: map}).()
    else
      {nil, _} -> state
    end
  end

  defp map_update_lazy(map, key, func) do
    case Map.fetch(map, key) do
      {:ok, x} -> %{map | key => func.(x)}
      :error -> map
    end
  end

  defp map_update(map, key, new_value) do
    map_update_lazy(map, key, fn _ -> new_value end)
  end
end
