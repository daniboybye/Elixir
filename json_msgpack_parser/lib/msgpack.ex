defmodule Msgpack do
  defmacro const() do
    quote do
      @true_code <<195::8>>
      @false_code <<194::8>>
      @null_code <<192::8>>
      @code_int8 208
      @int64 <<@code_int8 + 3::8>>
      @float64 <<203::8>>
      @fixmap <<8::4>>
      @map16 <<222::8>>
      @map32 <<223::8>>
      @fixarray <<9::4>>
      @array16 <<220::8>>
      @array32 <<221::8>>
      @fixstr <<5::3>>
      @code_str8 217
      @str8 <<@code_str8::8>>
      @str16 <<@code_str8 + 1::8>>
      @str32 <<@code_str8 + 2::8>>
      @empty_space ["\n", "\r", " ", "\t"]
      @digits ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "-"]
    end
  end
end
