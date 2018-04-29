defmodule SeverTest do
  use ExUnit.Case

  test "accept connections" do
    ip = Application.get_env(:nine_digits, :ip)
    port = Application.get_env(:nine_digits, :port)
    {:ok, socket} = :gen_tcp.connect(ip, port, [:binary, active: false])
    :ok = :gen_tcp.close(socket)
  end

  test "send message to server" do
    ip = Application.get_env(:nine_digits, :ip)
    port = Application.get_env(:nine_digits, :port)
    {:ok, socket} = :gen_tcp.connect(ip, port, [:binary, active: false])
    :ok = :gen_tcp.send(socket, "Hello Ainara\n")
    :ok = :gen_tcp.close(socket)
  end
end
