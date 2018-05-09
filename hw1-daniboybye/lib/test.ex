defmodule TestSuite.Test do
  @enforce_keys [:function]
  defstruct [:function, status: :pending, tags: []]

  @type status :: :pending | :passed | :failed | :skipped | :timed_out

  @type tags :: [atom()]

  @type t :: %__MODULE__{
          function: (() -> any),
          status: status,
          tags: tags
        }

  def list_of_atoms?(list) when is_list(list) do
    list
    |> Enum.reject(&is_atom/1)
    |> Kernel.==([])
  end

  def tag?(%__MODULE__{tags: tag}, options), do: tagp?(tag, options)

  defp tagp?(_, []), do: true

  defp tagp?(tag, [{:only, flag} | tail]), do: tag_match?(tag, flag) && tagp?(tag, tail)

  defp tagp?(tag, [{:exclude, flag} | tail]), do: !tag_match?(tag, flag) && tagp?(tag, tail)

  defp tagp?(tag,[_| tail]), do: tagp?(tag,tail)

  defp tag_match?(tags, flag), do: Enum.member?(tags, flag)

  def run_test(%__MODULE__{status: :passed} = test, _, _), do: test

  def run_test(%__MODULE__{} = test, time, options) do
    case tag?(test, options) do
      true -> check_time(test, time)
      _ -> %{test | status: :skipped}
    end
  end

  defp rapper_noexcept(test) do
    try do
      test.()
    rescue
      _ -> nil
    end
  end

  defp check_time(test, :infinity), do: run_testp(test, :infinity)

  defp check_time(test, time) when time > 0, do: run_testp(test, time)

  defp run_testp(%__MODULE__{function: f} = test, time) do
    task = Task.async(fn -> rapper_noexcept(f) end)

    case Task.yield(task, time) || Task.shutdown(task) do
      nil -> %__MODULE__{test | status: :timed_out}
      {:ok, x} when x in [nil, false] -> %__MODULE__{test | status: :failed}
      {:ok, _} -> %__MODULE__{test | status: :passed}
    end
  end

  def testToString(%__MODULE__{status: status}), do: statusToString(status)

  defp statusToString(:pending), do: "P"
  defp statusToString(:passed), do: "."
  defp statusToString(:failed), do: "F"
  defp statusToString(:skipped), do: "S"
  defp statusToString(:timed_out), do: "T"
end
