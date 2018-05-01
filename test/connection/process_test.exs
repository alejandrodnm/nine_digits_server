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

  test "new items are stored in the ets table and are written to disk", %{
    ip: ip,
    port: port,
    file_path: file_path
  } do
    {:ok, socket} = :gen_tcp.connect(ip, port, [:binary, active: false])

    items =
      for n <- 1..3 do
        item = "12345678#{n}"
        :ok = :gen_tcp.send(socket, "#{item}\r\n")
        {:ok, "ok"} = :gen_tcp.recv(socket, 0)
        item
      end

    :gen_tcp.close(socket)

    joined_items = Enum.join(items, "\n") <> "\n"
    {:ok, ^joined_items} = File.read(file_path)
    assert :ets.lookup(:repo, items)
    assert :ets.info(:repo, :size) == 3
  end

  test "duplicated items increase the duplicates counter", %{
    ip: ip,
    port: port,
    file_path: file_path
  } do
    item = "123456789"

    1..3
    |> Task.async_stream(fn _ ->
      {:ok, socket} = :gen_tcp.connect(ip, port, [:binary, active: false])
      :ok = :gen_tcp.send(socket, "#{item}\r\n")
      {:ok, "ok"} = :gen_tcp.recv(socket, 0)
      :gen_tcp.close(socket)
    end)
    |> Enum.to_list()

    read_item = item <> "\n"
    {:ok, ^read_item} = File.read(file_path)
    assert :ets.lookup(:repo, item) == [{item, true}]
    assert :ets.info(:repo, :size) == 1
    assert :ets.lookup(:counter, :duplicates) == [{:duplicates, 2}]
  end
end
