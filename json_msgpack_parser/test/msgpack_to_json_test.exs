defmodule MsgpackToJsonTest do
  use ExUnit.Case
  doctest MsgpackToJson

  test "loss of information" do
    json_string = "{
      \"int\": {
        \"a\": [
          [],
          \"2w\"
        ]
      },
      \"floФФ\": 0.5,
      \"дани\": true,
      \"null\": null,
      \"string\": \"foo bar\",
      \"array\": [
        \"foo\",
        \"bar\"
      ],
      \"object\": {
        \"foo\": 1,
        \"baz\": 0.5
      }
    }"

    {empty_space, msgpack} = JsonToMsgpack.parsing(json_string)

    assert "" == String.trim_leading(empty_space)

    flat_join = fn str -> List.flatten(str) |> Enum.join("") end

    {"", json_after_transform} =
      msgpack
      |> flat_join.()
      |> MsgpackToJson.parsing()

    f = &String.replace(&1, ~r/( |\n|\t|\r)/, "")

    assert f.(json_string) == json_after_transform |> flat_join.() |> f.()

    IO.puts("\n\tPretty printing test\n\n")

    json_after_transform
    |> MsgpackToJson.pretty_printing()
    |> IO.puts()
  end
end
