defmodule JsonToMsgpack do
  @moduledoc """
  when the file content is invalid
  the error that will occur is FunctionClauseError
  """
  @behaviour Parser

  require Msgpack

  Msgpack.const()

  def parsing(<<x::utf8, tail::binary>>) when <<x::utf8>> in @empty_space do
    parsing(tail)
  end

  def parsing(<<"null", tail::binary>>), do: {tail, @null_code}

  def parsing(<<"false", tail::binary>>), do: {tail, @false_code}

  def parsing(<<"true", tail::binary>>), do: {tail, @true_code}

  def parsing(<<"{", _::binary>> = json) do
    JsonToMsgpack.Object.parsing(json)
  end

  def parsing(<<x::utf8, _::binary>> = json) when <<x::utf8>> in @digits do
    JsonToMsgpack.Number.parsing(json)
  end

  def parsing(<<"\"", _::binary>> = json) do
    JsonToMsgpack.String.parsing(json)
  end

  def parsing(<<"[", _::binary>> = json) do
    JsonToMsgpack.List.parsing(json)
  end
end
