defmodule JsonToMsgpack.Object do
  @behaviour Parser

  require Msgpack

  Msgpack.const()

  @pow2_4 :math.pow(2, 4)
  @pow2_16 :math.pow(2, 16)
  @pow2_32 :math.pow(2, 32)

  def parsing(<<"{", tail::binary>>) do
    parsing(tail, [], 0)
  end

  defp parsing(<<"}", tail::binary>>, char_data, len) do
    Enum.reverse(char_data)
    |> (&{tail, [msgpack_map_size_coding(len) | &1]}).()
  end

  defp parsing(<<x::utf8, tail::binary>>, char_data, len) when <<x::utf8>> in @empty_space do
    parsing(tail, char_data, len)
  end

  defp parsing(<<",", tail::binary>>, char_data, len) do
    json_object_element_to_msgpack(tail, char_data, len)
  end

  defp parsing(json_str, [], 0) do
    json_object_element_to_msgpack(json_str, [], 0)
  end

  defp json_object_element_to_msgpack(json_str, char_data, len) do
    {json_str1, key} = extract_key(json_str)

    {json_str2, value} = extract_value(json_str1)

    parsing(json_str2, [value, key | char_data], len + 1)
  end

  defp extract_key(json) do
    String.trim_leading(json)
    |> JsonToMsgpack.String.parsing()
  end

  defp extract_value(json) do
    String.trim_leading(json)
    |> (fn <<":", x::binary>> -> x end).()
    |> JsonToMsgpack.parsing()
  end

  defp msgpack_map_size_coding(len) when len < @pow2_4 do
    <<@fixmap, len::4>>
  end

  defp msgpack_map_size_coding(len) when len < @pow2_16 do
    [@map16, <<len::16>>]
  end

  defp msgpack_map_size_coding(len) when len < @pow2_32 do
    [@map32, <<len::32>>]
  end
end
