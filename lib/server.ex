require Logger

defmodule Server do
  @moduledoc """
  TCP server for receiving nine digits messages.
  """
  use GenServer

  def start_link(opts) do
    ip = Application.get_env(:nine_digits, :ip)
    port = Application.get_env(:nine_digits, :port)
    GenServer.start_link(__MODULE__, [ip: ip, port: port], opts)
  end

  @doc """
  Sets a socket on the port defined on the config
  """
  def init(ip: ip, port: port) do
    case :gen_tcp.listen(port, [
           :binary,
           active: true,
           reuseaddr: true
         ]) do
      {:ok, listen_socket} ->
        Logger.debug(fn ->
          "Accepting connections on ip #{ip_to_str(ip)} and port #{port}"
        end)

        {:ok, %{ip: ip, port: port, listen_socket: listen_socket}}

      {:error, reason} = err ->
        Logger.error(
          "#{reason}: Couldn't open socket on ip #{ip_to_str(ip)} and port #{
            port
          }"
        )

        {:stop, reason}
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
