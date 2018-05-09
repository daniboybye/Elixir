defmodule MsgpackToJson do
  @moduledoc """
  when the file content is invalid 
  or contains objects for which there is no implementation,
  the error that will occur is FunctionClauseError
  """

  @behaviour Parser

  require Msgpack

  Msgpack.const()

  def parsing(<<@false_code, tail::binary>>), do: {tail, "false"}

  def parsing(<<@true_code, tail::binary>>), do: {tail, "true"}

  def parsing(<<@null_code, tail::binary>>), do: {tail, "null"}

  def parsing(<<@fixstr, n::5, str::bytes-size(n), tail::binary>>) do
    parsing_string(tail, str)
  end

  def parsing(<<@str8, n::8, str::bytes-size(n), tail::binary>>) do
    parsing_string(tail, str)
  end

  def parsing(<<@str16, n::16, str::bytes-size(n), tail::binary>>) do
    parsing_string(tail, str)
  end

  def parsing(<<@str32, n::32, str::bytes-size(n), tail::binary>>) do
    parsing_string(tail, str)
  end

  def parsing(<<@float64, number::float, tail::binary>>) do
    parsing_number(tail, number, Float)
  end

  def parsing(<<@int64, number::64, tail::binary>>) do
    parsing_number(tail, number, Integer)
  end

  def parsing(<<@fixmap, n::4, tail::binary>>) do
    MsgpackToJson.ArrayMap.parsing_map(tail, n)
  end

  def parsing(<<@map16, n::16, tail::binary>>) do
    MsgpackToJson.ArrayMap.parsing_map(tail, n)
  end

  def parsing(<<@map32, n::32, tail::binary>>) do
    MsgpackToJson.ArrayMap.parsing_map(tail, n)
  end

  def parsing(<<@fixarray, n::4, tail::binary>>) do
    MsgpackToJson.ArrayMap.parsing_array(tail, n)
  end

  def parsing(<<@array16, n::16, tail::binary>>) do
    MsgpackToJson.ArrayMap.parsing_array(tail, n)
  end

  def parsing(<<@array32, n::32, tail::binary>>) do
    MsgpackToJson.ArrayMap.parsing_array(tail, n)
  end

  @spec pretty_printing(str :: iodata()) :: iodata()
  def pretty_printing(str) when is_list(str) do
    List.flatten(str)
    |> pretty_printing(0, [])
  end

  def pretty_printing(str), do: str

  defp pretty_printing([], 0, res), do: Enum.reverse(res)

  defp pretty_printing([x | tail], n, res) when x in ["{", "["] do
    pretty_printing(tail, n + 1, [x | res])
  end

  defp pretty_printing(["\r\n", x | tail], n, res) when x in ["}", "]"] do
    List.duplicate(["\t"], n - 1)
    |> (&pretty_printing(tail, n - 1, [x, &1, "\r\n" | res])).()
  end

  defp pretty_printing(["\r\n" | tail], n, res) do
    List.duplicate(["\t"], n)
    |> (&pretty_printing(tail, n, [&1, "\r\n" | res])).()
  end

  defp pretty_printing([x | tail], n, res) do
    pretty_printing(tail, n, [x | res])
  end

  defp parsing_string(tail, str) do
    {tail, ["\"", str, "\""]}
  end

  defp parsing_number(tail, number, module) do
    number
    |> module.to_string
    |> (&{tail, &1}).()
  end
end
