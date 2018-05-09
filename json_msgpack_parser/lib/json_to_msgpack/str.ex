defmodule JsonToMsgpack.String do
  @behaviour Parser

  require Msgpack

  Msgpack.const()

  @pow2_5 :math.pow(2, 5)
  @pow2_8 :math.pow(2, 8)
  @pow2_16 :math.pow(2, 16)
  @pow2_32 :math.pow(2, 32)

  def parsing(<<"\"", bin::binary>>) do
    bin
    |> extract_string([])
    |> (fn [str, tail] ->
          {tail, json_string_to_msgpack(str, byte_size(str))}
        end).()
  end

  defp json_string_to_msgpack(str, len) when len < @pow2_5 do
    [<<@fixstr, len::5>>, str]
  end

  defp json_string_to_msgpack(str, len) when len < @pow2_8 do
    [@str8, <<len::8>>, str]
  end

  defp json_string_to_msgpack(str, len) when len < @pow2_16 do
    [@str16, <<len::16>>, str]
  end

  defp json_string_to_msgpack(str, len) when len < @pow2_32 do
    [@str32, <<len::32>>, str]
  end

  defp extract_string(<<"\"", tail::binary>>, res) do
    res
    |> Enum.reverse()
    # without "join" will need modification in the tests
    |> Enum.join("")
    |> (&[&1, tail]).()
  end

  defp extract_string(<<"\\\"", tail::binary>>, res) do
    extract_string(tail, ["\\\"" | res])
  end

  defp extract_string(<<x::utf8, tail::binary>>, res) do
    extract_string(tail, [<<x::utf8>> | res])
  end
end
