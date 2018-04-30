defmodule FileHandlerTest do
  use ExUnit.Case

  setup do
    file_path = Application.get_env(:nine_digits, :file_path)
    [file_path: file_path]
  end

  defp clean_state do
    Application.stop(:nine_digits)
    Application.start(:nine_digits)
  end

  test "creates the empty file log", %{file_path: file_path} do
    Application.stop(:nine_digits)
    File.write(file_path, "not empty")
    Application.start(:nine_digits)
    assert File.exists?(file_path)
    {:ok, ""} = File.read(file_path)
  end

  test "appends an item to file", %{file_path: file_path} do
    clean_state()
    item = "item1"
    :ok = FileHandler.append_line(FileHandler, item)
    {:ok, read_item} = File.read(file_path)
    assert item <> "\n" == read_item
  end

  test "appends 3 item to file", %{file_path: file_path} do
    clean_state()

    items =
      for n <- 1..3 do
        item = "item#{n}"
        :ok = FileHandler.append_line(FileHandler, item)
        item
      end

    joined_items = Enum.join(items, "\n") <> "\n"
    {:ok, ^joined_items} = File.read(file_path)
  end
end
