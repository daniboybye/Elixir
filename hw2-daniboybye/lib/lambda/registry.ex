defmodule Lambda.Registry do
  use GenServer

  alias __MODULE__.State

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(_), do: {:ok, %State{}}

  def handle_call({:run, module, func, args, time}, from, state) do
    table = State.get_table(state, module, func)
    
    with {:error, :not_cached} <- State.fetch_cached(table, args),
         {:ok, pid} <- State.Table.in_processing(table, args, time) do
      state
      |> State.add_in_processing(pid, from)
      |> (&{:noreply, &1}).()
    else
      {:error, :not_registered} = x ->
        {:reply, x, state}

      {:ok, _} = x ->
        {:reply, x, state}

      :error ->
        state
        |> State.run(table, module, func, args, time, from)
        |> (&{:noreply, &1}).()
    end
  end

  def handle_call({:fetch_cached, module, func, args}, _from, state) do
    state
    |> State.fetch_cached(module, func, args)
    |> (&{:reply, &1, state}).()
  end

  def handle_cast({:register, module, func}, state) do
    state
    |> State.register(module, func)
    |> (&{:noreply, &1}).()
  end

  def handle_cast({:unregister, module, func}, state) do
    state
    |> State.unregister(module, func)
    |> (&{:noreply, &1}).()
  end

  def handle_cast({:clear_cache, module, func}, state) do
    state
    |> State.clear_cache(module, func)
    |> (&{:noreply, &1}).()
  end

  def handle_cast({:clear_cache, module, func, args}, state) do
    state
    |> State.clear_cache(module, func, args)
    |> (&{:noreply, &1}).()
  end

  def handle_info({:DOWN, _ref, :process, _pid, :normal}, state) do
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, :killed}, state) do
    IO.puts(2)
    state
    |> State.handle_result(ref, :timeout)
    |> (&{:noreply, &1}).()
  end

  def handle_info({:DOWN, ref, :process, _pid, _}, state) do
    state
    |> State.handle_result(ref, {:error, :execution_error})
    |> (&{:noreply, &1}).()
  end

  def handle_info({ref, result}, state) do
    state
    |> State.handle_result(ref, {:ok, result})
    |> (&{:noreply, &1}).()
  end
end
