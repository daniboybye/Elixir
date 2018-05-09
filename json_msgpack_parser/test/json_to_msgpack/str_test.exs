defmodule JsonToMsgpack.StringTest do
  use ExUnit.Case
  doctest JsonToMsgpack.String

  defp help_test(list) do
    list
    |> List.foldl(<<>>, fn x, y ->
      y <> <<x::8>>
    end)
  end

  test "parsing empty string" do
    assert JsonToMsgpack.String.parsing("\"\"dani") == {"dani", [<<160::8>>, ""]}
  end

  test "parsing string with escape quotes" do
    assert JsonToMsgpack.String.parsing("\"dani\\\"boy\"") ==
             {"", [<<169::8>>, help_test([100, 97, 110, 105, 92, 34, 98, 111, 121])]}
  end

  test "parsing ASCII" do
    assert JsonToMsgpack.String.parsing("\"Hello World\"") ==
             {"",
              [
                <<171::8>>,
                help_test([72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100])
              ]}
  end

  test "parsing UFT-8" do
    assert JsonToMsgpack.String.parsing("\"ДАНИ\"") ==
             {"",
              [
                <<168::8>>,
                help_test([208, 148, 208, 144, 208, 157, 208, 152])
              ]}
  end

  test "parsing \"null\"" do
    assert JsonToMsgpack.String.parsing("\"null\"") ==
             {"",
              [
                <<164::8>>,
                help_test([110, 117, 108, 108])
              ]}
  end
end
