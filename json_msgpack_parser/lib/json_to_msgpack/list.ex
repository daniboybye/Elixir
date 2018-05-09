defmodule JsonToMsgpack.List do
  @behaviour Parser

  require Msgpack

  Msgpack.const()

  @pow2_4 :math.pow(2, 4)
  @pow2_16 :math.pow(2, 16)
  @pow2_32 :math.pow(2, 32)

  def parsing(<<"[", tail::binary>>), do: parsing(tail, [], 0)

  defp parsing(<<"]", tail::binary>>, char_data, len) do
    Enum.reverse(char_data)
    |> (&{tail, [msgpack_array_size_coding(len) | &1]}).()
  end

  defp parsing(<<",", tail::binary>>, char_data, len) do
    parsing_element(tail, char_data, len)
  end

  defp parsing(<<x::utf8, tail::binary>>, char_data, len) when <<x::utf8>> in @empty_space do
    parsing(tail, char_data, len)
  end

  defp parsing(<<json_str::binary>>, [], 0), do: parsing_element(json_str, [], 0)

  defp parsing_element(json_str, char_data, len) do
    JsonToMsgpack.parsing(json_str)
    |> (fn {json_str1, msgpack} -> parsing(json_str1, [msgpack | char_data], len + 1) end).()
  end

  defp msgpack_array_size_coding(len) when len < @pow2_4 do
    <<@fixarray, len::4>>
  end

  defp msgpack_array_size_coding(len) when len < @pow2_16 do
    <<@array16, len::16>>
  end

  defp msgpack_array_size_coding(len) when len < @pow2_32 do
    <<@array32, len::32>>
  end
end
