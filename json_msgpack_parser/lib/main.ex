defmodule Main.CLI do
  def main(args) do
    {files_exists, files_not_exists} = Enum.split_with(args, &File.exists?/1)

    Enum.map(files_not_exists, &IO.puts(:stderr, [&1, " is not exists\r\n"]))

    Enum.map(files_exists, fn file_name ->
      {pid, ref} = spawn_monitor(fn -> open_file(file_name) end)

      receive do
        {:DOWN, ^ref, :process, ^pid, :normal} ->
          0

        {:DOWN, ^ref, :process, ^pid, _} ->
          IO.puts(
            "Invalid format or not implemented functionality of MessagePack in #{file_name}\r\n"
          )
      end
    end)

    0
  end

  defp open_file(file_name) do
    {:ok, content} = File.read(file_name)

    {new_file_name, new_content} =
      file_name
      |> String.split(".")
      |> List.pop_at(-1)
      |> parse_content(content)

    :ok =
      new_file_name
      |> Enum.join(".")
      |> File.write(new_content)
  end

  defp parse_content({"json", file_name}, content) do
    {rest_of_file, new_content} = JsonToMsgpack.parsing(content)

    "" = String.trim_leading(rest_of_file)

    {file_name ++ ["mp"], new_content}
  end

  defp parse_content({"mp", file_name}, content) do
    content
    |> MsgpackToJson.parsing()
    |> (fn {"", json} -> MsgpackToJson.pretty_printing(json) end).()
    |> (&{file_name ++ ["json"], &1}).()
  end
end
