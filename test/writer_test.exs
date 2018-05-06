defmodule WriterTest do
  use ExUnit.Case

  setup do
    TestHelper.clean_state()
    writer = get_writer()
    file_path = Application.get_env(:nine_digits, :file_path)
    [file_path: file_path, writer: writer]
  end

  defp get_writer do
    {{_, child, _, _}, _} =
      Writer.Supervisor
      |> Supervisor.which_children()
      |> List.pop_at(0)

    child
  end

  test "appends an item to file", %{file_path: file_path, writer: writer} do
    item = "item1"
    :ok = Writer.append_line(writer, item)
    :pong = Writer.ping(writer)
    {:ok, read_item} = File.read(file_path)
    assert item <> "\n" == read_item
  end

  test "appends 3 item to file", %{file_path: file_path, writer: writer} do
    items =
      for n <- 1..3 do
        item = "item#{n}"
        :ok = Writer.append_line(writer, item)
        item
      end

    :pong = Writer.ping(writer)
    joined_items = Enum.join(items, "\n") <> "\n"
    {:ok, ^joined_items} = File.read(file_path)
  end
end
