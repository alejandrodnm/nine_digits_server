defmodule Connection.PacketValidationTest do
  use ExUnit.Case

  setup do
    ip = Application.get_env(:nine_digits, :ip)
    port = Application.get_env(:nine_digits, :port)
    {:ok, socket} = :gen_tcp.connect(ip, port, [:binary, active: false])

    # Close the socket on exit
    on_exit(fn ->
      :gen_tcp.close(socket)
    end)

    [socket: socket]
  end

  test "send non digit message with length == 9 and != terminate, server closes connection",
       %{socket: socket} do
    :ok = :gen_tcp.send(socket, "asdfghjkl\n")
    {:error, :closed} = :gen_tcp.recv(socket, 0)
  end

  test "send non digits message with length > 9, server closes connection", %{
    socket: socket
  } do
    :ok = :gen_tcp.send(socket, "asdfghjklz\n")
    {:error, :closed} = :gen_tcp.recv(socket, 0)
  end

  test "send message to server with length > 11 and no CRLF, server closes connection",
       %{
         socket: socket
       } do
    :ok = :gen_tcp.send(socket, "123456789012")
    {:error, :closed} = :gen_tcp.recv(socket, 0)
  end
end
