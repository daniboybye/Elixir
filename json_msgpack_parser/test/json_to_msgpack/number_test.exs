defmodule JsonToMsgpack.NumberTest do
  use ExUnit.Case
  doctest JsonToMsgpack.Number

  defp help_test(list) do
    list
    |> List.foldl(<<>>, fn x, y -> y <> <<x::8>> end)
  end

  test "parsing Integer64" do
    assert JsonToMsgpack.Number.parsing("123") ==
             {"", [<<211::8>>, help_test([0, 0, 0, 0, 0, 0, 0, 123])]}
  end

  test "parsing Float64" do
    assert JsonToMsgpack.Number.parsing("12.03") ==
             {"", [<<203::8>>, help_test([64, 40, 15, 92, 40, 245, 194, 143])]}
  end

  test "parsing Negative integer" do
    assert JsonToMsgpack.Number.parsing("-123.1") ==
             {"", [<<203::8>>, help_test([192, 94, 198, 102, 102, 102, 102, 102])]}
  end

  test "parsing Float64 with e" do
    res = {"", [<<203::8>>, help_test([63, 26, 54, 226, 235, 28, 67, 45])]}

    assert JsonToMsgpack.Number.parsing("1.0e-4") == res
    assert JsonToMsgpack.Number.parsing("1.0E-4") == res
    assert JsonToMsgpack.Number.parsing("0.0001") == res
  end
end
