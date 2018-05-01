defmodule FileHandlerTest do
  use ExUnit.Case

  setup do
    file_path = Application.get_env(:nine_digits, :file_path)
    [file_path: file_path]
  end

  test "creates the empty file log", %{file_path: file_path} do
    on_exit(&TestHelper.restart_application_if_not_started/0)

    Application.stop(:nine_digits)
    File.write(file_path, "not empty")
    Application.start(:nine_digits)
    assert File.exists?(file_path)
    {:ok, ""} = File.read(file_path)
  end

  test "appends an item to file", %{file_path: file_path} do
    TestHelper.clean_state()
    item = "item1"
    :ok = FileHandler.append_line(FileHandler, item)
    :pong = FileHandler.ping(FileHandler)
    {:ok, read_item} = File.read(file_path)
    assert item <> "\n" == read_item
  end

  test "appends 3 item to file", %{file_path: file_path} do
    TestHelper.clean_state()

    items =
      for n <- 1..3 do
        item = "item#{n}"
        :ok = FileHandler.append_line(FileHandler, item)
        item
      end

    :pong = FileHandler.ping(FileHandler)
    joined_items = Enum.join(items, "\n") <> "\n"
    {:ok, ^joined_items} = File.read(file_path)
  end
end
