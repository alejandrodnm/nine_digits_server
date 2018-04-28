require Logger

defmodule Server do
  @moduledoc """
  TCP server for receiving nine digits messages.
  """
  use GenServer

  def start_link do
    ip = Application.get_env(:nine_digits, :ip)
    port = Application.get_env(:nine_digits, :port)
    GenServer.start_link(__MODULE__, [ip: ip, port: port], [])
  end

  @doc """

  """
  @spec ip_to_str(tuple()) :: String.t()
  defp ip_to_str(ip) do
    ip
    |> Tuple.to_list()
    |> Enum.join(".")
  end

  def init(ip: ip, port: port) do
    case :gen_tcp.listen(port, [
           :binary,
           packet: :line,
           active: true,
           reuseaddr: true
         ]) do
      {:ok, listen_socket} ->
        Logger.info(
          "Accepting connections on ip #{ip_to_str(ip)} and port #{port}"
        )

        {:ok, listen_socket}

      {:error, reason} ->
        Logger.error(
          "#{reason}: Couldn't open socket on ip #{ip_to_str(ip)} and port #{
            port
          }"
        )

        {:error, reason}
    end
  end
end
