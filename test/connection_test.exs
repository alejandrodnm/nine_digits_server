defmodule ConnectionTest do
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

  test "send non number message, server closes connection", %{socket: socket} do
    :ok = :gen_tcp.send(socket, "Hello Ainara\n")
    {:error, :closed} = :gen_tcp.recv(socket, 0)
  end

  test "send message to server without carriage return, server closes connection",
       %{socket: socket} do
    :ok = :gen_tcp.send(socket, "123456789")
    {:error, :closed} = :gen_tcp.recv(socket, 0)
  end

  test "send message to server with length < 9, server closes connection", %{
    socket: socket
  } do
    :ok = :gen_tcp.send(socket, "12345678\n")
    {:error, :closed} = :gen_tcp.recv(socket, 0)
  end

  test "send message to server with length > 9, server closes connection", %{
    socket: socket
  } do
    :ok = :gen_tcp.send(socket, "1234567890\n")
    {:error, :closed} = :gen_tcp.recv(socket, 0)
  end

  test "send message to server with data after the carriage return, server closes connection",
       %{
         socket: socket
       } do
    :ok = :gen_tcp.send(socket, "123456789\r\n0123456789\n")
    {:error, :closed} = :gen_tcp.recv(socket, 0)
  end
end
