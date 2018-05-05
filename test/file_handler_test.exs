defmodule FileHandlerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  setup do
    file_path = Application.get_env(:nine_digits, :file_path)
    [file_path: file_path]
  end

  test "creates the empty file log", %{file_path: file_path} do
    on_exit(&TestHelper.restart_application_if_not_started/0)

    capture_log(fn -> Application.stop(:nine_digits) end)
    File.write(file_path, "not empty")
    Application.start(:nine_digits)
    assert File.exists?(file_path)
    {:ok, ""} = File.read(file_path)
  end

  test "register, assign and release a writter" do
    FileHandler.register_writer()
    assert FileHandler.get_unasigned() == [self()]
    assert FileHandler.assign_writer() == self()
    assert FileHandler.get_unasigned() == []
    assert self() == FileHandler.get_registered() |> Map.get(self())
    FileHandler.release_writer()
    assert FileHandler.get_unasigned() == [self()]
  end
end
