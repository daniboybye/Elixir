defmodule Parser do
  @moduledoc """
  the result is the pair of the rest of the content and a valid object
  """
  @callback parsing(arg :: binary()) :: {binary(), iodata()}
end
