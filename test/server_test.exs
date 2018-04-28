defmodule SeverTest do
  use ExUnit.Case
  doctest NineDigits

  test "starts the tcp server" do
    {:ok, _} = Server.start_link()
    ip = Application.get_env(:nine_digits, :ip)
    port = Application.get_env(:nine_digits, :port)
    {:ok, _} = :gen_tcp.connect(ip, port, [:binary, active: false])
  end
end
