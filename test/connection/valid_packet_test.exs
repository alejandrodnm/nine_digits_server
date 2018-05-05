defmodule Connection.ValidPacketTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  setup do
    capture_log(fn -> Application.stop(:nine_digits) end)
    Application.start(:nine_digits)
    file_path = Application.get_env(:nine_digits, :file_path)
    ip = Application.get_env(:nine_digits, :ip)
    port = Application.get_env(:nine_digits, :port)
    [ip: ip, port: port, file_path: file_path]
  end

  defp ping_connections_writers do
    Connection.Supervisor
    |> Supervisor.which_children()
    |> Enum.map(fn {_, child, _, _} ->
      :pong = Connection.ping(child)
    end)
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
    ping_connections_writers()
    assert :ets.lookup(:repo, items)
    assert :ets.info(:repo, :size) == 3

    {"", file_data} =
      file_path
      |> File.read!()
      |> String.split("\n")
      |> Enum.sort()
      |> List.pop_at(0)

    assert length(file_data) == 3

    assert items |> Enum.map(&String.to_integer/1) |> Enum.sort() ==
             file_data |> Enum.map(&String.to_integer/1)
  end

  test "duplicated items increase the duplicates counter", %{
    ip: ip,
    port: port,
    file_path: file_path
  } do
    item = 123_456_789

    1..3
    |> Enum.map(fn _ ->
      {:ok, socket} = :gen_tcp.connect(ip, port, [:binary, active: false])
      :ok = :gen_tcp.send(socket, "#{item}\r\n")
      {:ok, "ok"} = :gen_tcp.recv(socket, 0)
      :gen_tcp.close(socket)
    end)

    ping_connections_writers()
    assert :ets.lookup(:repo, item) == [{item}]
    assert :ets.info(:repo, :size) == 1
    assert :ets.lookup(:counter, :duplicates) == [{:duplicates, 2}]
    assert {:ok, "#{item}\n"} == File.read(file_path)
  end

  test "sending a terminate stops the application", %{
    ip: ip,
    port: port
  } do
    self_pid = self()

    Application.put_env(:nine_digits, :terminate, fn ->
      send(self_pid, :terminate)
    end)

    log =
      capture_log(fn ->
        {:ok, socket} = :gen_tcp.connect(ip, port, [:binary, active: false])
        :ok = :gen_tcp.send(socket, "terminate\r\n")
        assert_receive :terminate
      end)

    assert log =~ ~r/GenServer #PID<\d+.\d+.\d+> terminating/
  end
end
