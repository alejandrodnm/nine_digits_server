defmodule SeverTest do
  use ExUnit.Case
  doctest Server
  import ExUnit.CaptureLog

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
    capture_log(fn -> Application.stop(:nine_digits) end)

    {:ok, listen_socket} =
      :gen_tcp.listen(port, [
        :binary,
        active: false,
        reuseaddr: true,
        ip: ip
      ])

    log =
      capture_log(fn ->
        {:error,
         {{:shutdown,
           {:failed_to_start_child, Server.Supervisor,
            {:shutdown, {:failed_to_start_child, Server, :timeout}}}},
          {NineDigits.Application, :start, [:normal, []]}}} =
          Application.start(:nine_digits)
      end)

    assert String.contains?(
             log,
             "Couldn't open socket on ip #{Server.ip_to_str(ip)} and port #{
               port
             } retrying"
           )

    assert String.contains?(
             log,
             "Application nine_digits exited: " <>
               "NineDigits.Application.start(:normal, []) returned an error: " <>
               "shutdown: failed to start child: Server"
           )

    :ok = :gen_tcp.close(listen_socket)
    :ok = Application.start(:nine_digits)
    {:ok, socket} = :gen_tcp.connect(ip, port, [:binary, active: false])
    :ok = :gen_tcp.close(socket)

    on_exit(fn ->
      :ok = :gen_tcp.close(listen_socket)
      TestHelper.restart_application_if_not_started()
    end)
  end
end
