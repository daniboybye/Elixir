defmodule JsonToMsgpack.Number do
  @behaviour Parser

  require Msgpack

  Msgpack.const()

  @chars_in_number ["e", "E", "."]

  def parsing(<<x::utf8, _::binary>> = bin) when <<x::utf8>> in @digits do
    {is_float, number_length} = json_number_to_msgpack(bin, false, 0)
    {str_number, tail} = String.split_at(bin, number_length)

    {tail, json_number_to_msgpack(is_float, str_number)}
  end

  defp json_number_to_msgpack(true, str) do
    [@float64, <<String.to_float(str)::float>>]
  end

  defp json_number_to_msgpack(false, str) do
    [@int64, <<String.to_integer(str)::64>>]
  end

  defp json_number_to_msgpack(<<x::utf8, bin::binary>>, flag, len) when <<x::utf8>> in @digits do
    json_number_to_msgpack(bin, flag, len + 1)
  end

  defp json_number_to_msgpack(<<x::utf8, bin::binary>>, _, len)
       when <<x::utf8>> in @chars_in_number do
    json_number_to_msgpack(bin, true, len + 1)
  end

  defp json_number_to_msgpack(_, flag, len), do: {flag, len}
end
