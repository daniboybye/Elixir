defmodule MsgpackToJson.ArrayMapTest do
  use ExUnit.Case
  doctest MsgpackToJson.ArrayMap

  defp test_help(list, n, fun) do
    {tail, res} =
      list
      |> List.foldl(<<>>, fn x, y -> y <> <<x::8>> end)
      |> fun.(n)

    List.flatten(res)
    |> Enum.join("")
    |> String.replace(~r/( |\n|\t|\r)/, "")
    |> (&{tail, &1}).()
  end

  test "parsing empty map" do
    assert test_help([], 0, &MsgpackToJson.ArrayMap.parsing_map/2) == {"", "{}"}
  end

  test "parsing empty array" do
    assert test_help([], 0, &MsgpackToJson.ArrayMap.parsing_array/2) == {"", "[]"}
  end

  test "parsing array" do
    assert [195, 194, 192, 195]
           |> test_help(4, &MsgpackToJson.ArrayMap.parsing_array/2) ==
             {"", "[true,false,null,true]"}
  end

  test "parsing map" do
    assert [162, 49, 50, 192, 161, 110, 195]
           |> test_help(2, &MsgpackToJson.ArrayMap.parsing_map/2) ==
             {"", "{\"12\":null,\"n\":true}"}
  end

  test "parsing complicated map" do
    assert [
             163,
             105,
             110,
             116,
             146,
             146,
             144,
             164,
             100,
             97,
             110,
             105,
             192,
             165,
             102,
             108,
             111,
             97,
             116,
             203,
             63,
             224,
             0,
             0,
             0,
             0,
             0,
             0,
             167,
             98,
             111,
             111,
             108,
             101,
             97,
             110,
             195,
             164,
             110,
             117,
             108,
             108,
             192,
             166,
             115,
             116,
             114,
             105,
             110,
             103,
             167,
             102,
             111,
             111,
             32,
             98,
             97,
             114,
             165,
             97,
             114,
             114,
             97,
             121,
             146,
             163,
             102,
             111,
             111,
             163,
             98,
             97,
             114,
             166,
             111,
             98,
             106,
             101,
             99,
             116,
             130,
             163,
             102,
             111,
             111,
             146,
             128,
             145,
             128,
             163,
             98,
             97,
             122,
             203,
             63,
             224,
             0,
             0,
             0,
             0,
             0,
             0
           ]
           |> test_help(7, &MsgpackToJson.ArrayMap.parsing_map/2) ==
             {"",
              "{
              \"int\": [
                [
                  [],
                  \"dani\"
                ],
                null
              ],
              \"float\": 0.5,
              \"boolean\": true,
              \"null\": null,
              \"string\": \"foo bar\",
              \"array\": [
                \"foo\",
                \"bar\"
              ],
              \"object\": {
                \"foo\": [
                  {},
                  [
                    {}
                  ]
                ],
                \"baz\": 0.5
              }}"
              |> String.replace(~r/( |\n|\t|\r)/, "")}
  end
end
