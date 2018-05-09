defmodule TestSuite do
  defstruct tests: [], ran: false

  def new(), do: %__MODULE__{}

  def new(func, tags \\ []), do: new() |> add(func, tags)

  def add(test, func, tags \\ [])

  def add(test, func, tag) when is_atom(tag) do
    add(test, func, [tag])
  end

  def add(test, func, tags) when is_function(func, 0) do
    add(test, [func], tags)
  end

  def add(%__MODULE__{tests: list}, func, tags) when is_list(func) do
    true = __MODULE__.Test.list_of_atoms?(tags)
    
    %__MODULE__{tests: do_add(list, func, tags)}
  end

  defp do_add(list, [], _), do: list

  defp do_add(list, [hfunc | tfunc], tags) when is_function(hfunc, 0) do
    do_add([%__MODULE__.Test{function: hfunc, tags: tags} | list], tfunc, tags)
  end

  defp filter_state(%__MODULE__{tests: list}, value) do
    %__MODULE__{tests: Enum.filter(list, fn %__MODULE__.Test{status: st} -> st == value end)}
  end

  def passed(test), do: filter_state(test, :passed)

  def skipped(test), do: filter_state(test, :skipped)

  def failed(test), do: filter_state(test, :failed)

  def timed_out(test), do: filter_state(test, :timed_out)

  def pending(test), do: filter_state(test, :pending)

  def size(%__MODULE__{tests: list}, options \\ []) do
    Enum.filter(list, &__MODULE__.Test.tag?(&1, options)) |> Kernel.length()
  end

  def ran?(%__MODULE__{ran: flag}) do
    flag
  end

  defp key?({lhs, _}, rhs), do: lhs == rhs

  defp reject_key(keyword, key), do: Enum.reject(keyword, &key?(&1, key))

  defp find_positive_number(keyword, key) do
    Enum.find(keyword, nil, fn {_, y} = pair -> key?(pair, key) && y > 0 end)
  end

  defp runp(test, time, options) do
    case find_positive_number(options, :parallel) do
      {_, tasks} -> runp(test, time, tasks, reject_key(options, :parallel))
      nil -> runp(test, time, 1, options)
    end
  end

  defp runp(%__MODULE__{tests: list} = test, time, tasks, options) do
    chunk_size = test |> size |> div(tasks) |> Kernel.+(1)

    list
    |> Enum.chunk_every(chunk_size)
    |> Enum.map(
      &Task.async(fn -> Enum.map(&1, fn t -> __MODULE__.Test.run_test(t, time, options) end) end)
    )
    |> Enum.flat_map(&Task.await(&1, calc_time_for_tests(chunk_size,time)))
    |> (&%__MODULE__{tests: &1, ran: true}).()
  end

  defp calc_time_for_tests(_,:infinity), do: :infinity

  defp calc_time_for_tests(n,time), do: (n+1)*time

  def run(test, options \\ []) do
    case find_positive_number(options, :timeout) do
      {_, time} -> runp(test, time, reject_key(options, :timeout))
      nil -> runp(test, 5_000, options)
    end
  end

  def reset(%__MODULE__{tests: tests}) do
    %__MODULE__{tests: Enum.map(tests, &%{&1 | status: :pending})}
  end

  defimpl Inspect do
    defp h(str, 0), do: str <> ""
    defp h(str, _), do: str <> ":"

    defp add_test([_ | []]), do: " test"
    defp add_test(_), do: " tests"

    def inspect(%TestSuite{tests: tests} = test, _) do
      size = TestSuite.size(test)

      "#TestSuite<"
      |> Kernel.<>(inspect(size))
      |> Kernel.<>(add_test(tests))
      |> h(size)
      |> (fn base -> List.foldr(tests, base, &(&2 <> TestSuite.Test.testToString(&1))) end).()
      |> Kernel.<>(">")
    end
  end
end
