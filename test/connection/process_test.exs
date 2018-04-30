defmodule Connection.ProcessTest do
  use ExUnit.Case

  setup do
    Application.stop(:nine_digits)
    Application.start(:nine_digits)
    file_path = Application.get_env(:nine_digits, :file_path)
    ip = Application.get_env(:nine_digits, :ip)
    port = Application.get_env(:nine_digits, :port)
    {:ok, socket} = :gen_tcp.connect(ip, port, [:binary, active: false])

    # Close the socket on exit
    on_exit(fn ->
      :gen_tcp.close(socket)
    end)

    [socket: socket, file_path: file_path]
  end

  test "new items are stored in the ets table, increase the counter and are written to disk",
       %{
         socket: socket,
         file_path: file_path
       } do
    item = "123456789"
    :ok = :gen_tcp.send(socket, "#{item}\r\n")
    {:ok, "ok"} = :gen_tcp.recv(socket, 0)
    read_item = item <> "\n"
    {:ok, ^read_item} = File.read(file_path)
    assert :ets.lookup(:repo, item) == [{item, true}]
    assert :ets.info(:repo, :size) == 1
  end

  test "duplicated items only increase the counter", %{
    socket: socket,
    file_path: file_path
  } do
    item = "123456789"
    :ok = :gen_tcp.send(socket, "#{item}\r\n")
    {:ok, "ok"} = :gen_tcp.recv(socket, 0)
    :ok = :gen_tcp.send(socket, "#{item}\r\n")
    {:ok, "ok"} = :gen_tcp.recv(socket, 0)
    read_item = item <> "\n"
    {:ok, ^read_item} = File.read(file_path)
    assert :ets.lookup(:repo, item) == [{item, true}]
    assert :ets.info(:repo, :size) == 1
  end
end
