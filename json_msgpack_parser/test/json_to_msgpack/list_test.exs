defmodule JsonToMsgpack.ListTest do
  use ExUnit.Case
  doctest JsonToMsgpack.List

  test "parsing empty array" do
    assert(JsonToMsgpack.List.parsing("[]") == {"", [<<144::8>>]})
  end

  test "parsing array with one element" do
    assert(JsonToMsgpack.List.parsing("[null]") == {"", [<<145::8>>, <<192::8>>]})
  end

  test "parsing fixarray" do
    assert(
      JsonToMsgpack.List.parsing("[true, false, null]") ==
        {"", [147, 195, 194, 192] |> Enum.map(&<<&1::8>>)}
    )
  end
end
