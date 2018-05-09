defmodule JsonToMsgpack.ObjectTest do
  use ExUnit.Case
  doctest JsonToMsgpack.Object

  defp help_test(list) do
    list
    |> List.foldl(<<>>, fn x, y ->
      y <> <<x::8>>
    end)
  end

  test "parsing empty object" do
    assert JsonToMsgpack.Object.parsing("{}") == {"", [<<128::8>>]}
    assert JsonToMsgpack.Object.parsing("{   }") == {"", [<<128::8>>]}
  end

  test "parsing object with one element" do
    assert JsonToMsgpack.Object.parsing("{\"null\": null}") ==
             {"",
              [
                <<129::8>>,
                [
                  <<164::8>>,
                  help_test([110, 117, 108, 108])
                ],
                <<192::8>>
              ]}
  end

  test "parsing object" do
    assert JsonToMsgpack.Object.parsing("{
  \"true\"  : true,
  \"false\"   : false
}") ==
             {"",
              [
                <<130::8>>,
                [
                  <<164::8>>,
                  help_test([116, 114, 117, 101])
                ],
                <<195::8>>,
                [
                  <<165::8>>,
                  help_test([102, 97, 108, 115, 101])
                ],
                <<194::8>>
              ]}
  end
end
