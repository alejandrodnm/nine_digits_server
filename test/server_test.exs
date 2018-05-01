defmodule SeverTest do
  use ExUnit.Case

  setup do
    ip = Application.get_env(:nine_digits, :ip)
    port = Application.get_env(:nine_digits, :port)
    [ip: ip, port: port]
  end

  test "accept connections", %{ip: ip, port: port} do
    {:ok, socket} = :gen_tcp.connect(ip, port, [:binary, active: false])
    :ok = :gen_tcp.close(socket)
  end

  test "retries until it binds the port and accepts connections", %{
    ip: ip,
    port: port
  } do
    Application.stop(:nine_digits)

    {:ok, listen_socket} =
      :gen_tcp.listen(port, [
        :binary,
        active: false,
        reuseaddr: true,
        ip: ip
      ])

    {:error,
     {{:shutdown, {:failed_to_start_child, Server, :timeout}},
      {NineDigits.Application, :start, [:normal, []]}}} =
      Application.start(:nine_digits)

    :ok = :gen_tcp.close(listen_socket)
    :ok = Application.start(:nine_digits)
    {:ok, socket} = :gen_tcp.connect(ip, port, [:binary, active: false])
    :ok = :gen_tcp.close(socket)

    on_exit(fn ->
      :ok = :gen_tcp.close(listen_socket)

      unless List.keymember?(
               Application.started_applications(),
               :nine_digits,
               0
             ) do
        :ok = Application.start(:nine_digits)
      end
    end)
  end
end
