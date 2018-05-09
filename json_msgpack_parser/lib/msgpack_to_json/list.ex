defmodule MsgpackToJson.ArrayMap do
  use Bitwise, only_operators: true

  @spec parsing_array(msg :: binary(), n :: non_neg_integer()) :: {binary(), iodata()}
  def parsing_array(msg, n), do: parsing(msg, ["\r\n", "["], n, false)

  @spec parsing_map(msg :: binary(), n :: non_neg_integer()) :: {binary(), iodata()}
  def parsing_map(msg, n), do: parsing(msg, ["\r\n", "{"], 2 * n, true)

  defp parsing(msgpack, result, 0, flag) do
    json_syntax(flag)
    |> (&[&1 | result]).()
    |> Enum.reverse()
    |> (&{msgpack, &1}).()
  end

  defp parsing(msgpack, result, n, flag) do
    MsgpackToJson.parsing(msgpack)
    |> (fn {tail, json} ->
          parsing(tail, [json_syntax(n, flag), json | result], n - 1, flag)
        end).()
  end

  defp json_syntax(1, _), do: "\r\n"

  defp json_syntax(n, true) when (n &&& 1) == 0, do: ": "

  defp json_syntax(_, _), do: [",", "\r\n"]

  defp json_syntax(true), do: "}"

  defp json_syntax(false), do: "]"
end
