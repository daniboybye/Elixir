defmodule Lambda do
  def register(module, func) when is_atom(module) and is_atom(func) do
    GenServer.cast(Lambda.Registry, {:register, module, func})
  end

  def unregister(module, func) when is_atom(module) and is_atom(func) do
    GenServer.cast(Lambda.Registry, {:unregister, module, func})
  end

  def run(module, func, args, time \\ 5_000)

  def run(module, func, args, :infinity = x) do
    do_run(module, func, args, x, x)
  end

  def run(module, func, args, time) when is_integer(time) and time > 0 do
    do_run(module, func, args, time, time + 500)
  end

  defp do_run(module, func, args, time, timeout_server)
       when is_atom(module) and is_atom(func) and is_list(args) do
    GenServer.call(
      Lambda.Registry,
      {:run, module, func, args, time},
      max(timeout_server, 6_000)  
    )
  end

  def fetch_cached(module, func, args)
      when is_atom(module) and is_atom(func) and is_list(args) do
    GenServer.call(
      Lambda.Registry, 
      {:fetch_cached, module, func, args}
    )
  end

  def clear_cache(module, func) when is_atom(module) and is_atom(func) do
    GenServer.cast(Lambda.Registry, {:clear_cache, module, func})
  end

  def clear_cache(module, func, args) when is_atom(module) and is_atom(func) and is_list(args) do
    GenServer.cast(Lambda.Registry, {:clear_cache, module, func, args})
  end
end
