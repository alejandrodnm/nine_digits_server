require Logger

defmodule Server do
  @moduledoc """
  TCP server for receiving nine digits messages.
  """
  use GenServer
  @timeout Application.get_env(:nine_digits, :server_timeout, 5000)

  def start_link(opts) do
    ip = Application.get_env(:nine_digits, :ip)
    port = Application.get_env(:nine_digits, :port)

    GenServer.start_link(
      __MODULE__,
      [ip: ip, port: port],
      opts ++ [timeout: @timeout]
    )
  end

  @doc """
  Sets a socket on the given port and ip. If the connection is
  refused it waits some time and tries again, it will keep trying until
  the process is terminated by the `@timeout` timeout set on the
  `start_link` call.
  """
  def init([ip: ip, port: port] = args, retry_count \\ 1) do
    case :gen_tcp.listen(port, [
           :binary,
           active: false,
           reuseaddr: true,
           ip: ip,
           packet: :line
         ]) do
      {:ok, listen_socket} ->
        Logger.debug(fn ->
          "Accepting connections on ip #{ip_to_str(ip)} and port #{port}"
        end)

        {:ok, %{ip: ip, port: port, listen_socket: listen_socket}}

      {:error, reason} ->
        retry_in = 100 * retry_count

        Logger.error(
          "#{reason}: Couldn't open socket on ip #{ip_to_str(ip)} and port #{
            port
          } retrying in #{retry_in} ms"
        )

        :timer.sleep(retry_in)
        init(args, retry_count + 1)
    end
  end

  @doc """
  Returns the listen socket used for accepting connections
  """
  @spec listen_socket(GenServer.server()) :: port()
  def listen_socket(server) do
    GenServer.call(server, {:listen_socket})
  end

  def handle_call(
        {:listen_socket},
        _from,
        %{listen_socket: listen_socket} = state
      ) do
    {:reply, listen_socket, state}
  end

  @spec ip_to_str(tuple()) :: String.t()
  defp ip_to_str(ip) do
    ip
    |> Tuple.to_list()
    |> Enum.join(".")
  end
end
