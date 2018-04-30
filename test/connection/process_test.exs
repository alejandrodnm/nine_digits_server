defmodule Connection.ProcessTest do
  use ExUnit.Case

  setup do
    Application.stop(:nine_digits)
    Application.start(:nine_digits)
    file_path = Application.get_env(:nine_digits, :file_path)
    ip = Application.get_env(:nine_digits, :ip)
    port = Application.get_env(:nine_digits, :port)
    [ip: ip, port: port, file_path: file_path]
  end

  test "new items are stored in the ets table, increase the counter and are written to disk",
       %{
         ip: ip,
         port: port,
         file_path: file_path
       } do
    items =
      for n <- 1..3 do
        "12345678#{n}"
      end

    # We create 3 separate connections and run the execution on parallel
    items
    |> Task.async_stream(fn item ->
      {:ok, socket_} = :gen_tcp.connect(ip, port, [:binary, active: false])
      :ok = :gen_tcp.send(socket_, "#{item}\r\n")
      {:ok, "ok"} = :gen_tcp.recv(socket_, 0)
      :gen_tcp.close(socket_)
    end)
    |> Enum.to_list()

    joined_items = Enum.join(items, "\n") <> "\n"
    {:ok, ^joined_items} = File.read(file_path)
    assert :ets.lookup(:repo, items)
    assert :ets.info(:repo, :size) == 3
  end

  test "duplicated items only increase the counter", %{
    ip: ip,
    port: port,
    file_path: file_path
  } do
    {:ok, socket} = :gen_tcp.connect(ip, port, [:binary, active: false])
    item = "123456789"
    :ok = :gen_tcp.send(socket, "#{item}\r\n")
    {:ok, "ok"} = :gen_tcp.recv(socket, 0)
    :ok = :gen_tcp.send(socket, "#{item}\r\n")
    {:ok, "ok"} = :gen_tcp.recv(socket, 0)
    :gen_tcp.close(socket)
    read_item = item <> "\n"
    {:ok, ^read_item} = File.read(file_path)
    assert :ets.lookup(:repo, item) == [{item, true}]
    assert :ets.info(:repo, :size) == 1
  end
end
