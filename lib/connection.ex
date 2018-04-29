require Logger

defmodule Connection do
  @moduledoc """
  Handles client connections
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(state) do
    Process.send_after(self(), :started, 0)
    {:ok, state}
  end

  @doc """
  Called immediately after process initialization. Gets the listening
  socket from Server and waits for new client connections
  """
  def handle_info(:started, _) do
    listen_socket = Server.listen_socket(Server)

    Logger.debug(fn ->
      "#{inspect(self())}: waiting connection"
    end)

    socket = accept_connection(listen_socket)
    state = [socket: socket, listen_socket: listen_socket]
    {:noreply, state}
  end

  def handle_info({:tcp, socket, packet}, state) do
    Logger.debug(fn ->
      "#{inspect(self())}: received #{packet}"
    end)

    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, state) do
    Logger.debug(fn ->
      "#{inspect(self())}: connection closed"
    end)

    socket =
      state
      |> Keyword.get(:listen_socket)
      |> accept_connection

    new_state = Keyword.put(state, :socket, socket)
    {:noreply, new_state}
  end

  def handle_info(
        {:tcp_error, _, reason},
        [listen_socket: listen_socket] = state
      ) do
    Logger.debug(fn ->
      "#{inspect(self())}: connection closed due to #{reason}"
    end)

    socket =
      state
      |> Keyword.get(:listen_socket)
      |> accept_connection

    new_state = Keyword.put(state, :socket, socket)
    {:noreply, new_state}
  end

  @spec accept_connection(port()) :: port()
  defp accept_connection(listen_socket) do
    # If it fails the supervisor will restart it
    {:ok, socket} = :gen_tcp.accept(listen_socket)

    Logger.debug(fn ->
      "#{inspect(self())}: connection stablished"
    end)

    socket
  end
end
