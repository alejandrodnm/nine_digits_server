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

    {:ok, socket} = :gen_tcp.accept(listen_socket)

    Logger.debug(fn ->
      "#{inspect(self())}: connection stablished"
    end)

    {:noreply, [socket: socket, listen_socket: listen_socket]}
  end

  def handle_info({:tcp, socket, packet}, state) do
    Logger.debug(fn ->
      "#{inspect(self())}: received #{packet}"
    end)

    :gen_tcp.send(socket, "message recived")
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, state) do
    Logger.debug(fn ->
      "#{inspect(self())}: connection closed"
    end)

    {:noreply, state}
  end

  def handle_info({:tcp_error, _, reason}, state) do
    Logger.debug(fn ->
      "#{inspect(self())}: connection closed due to #{reason}"
    end)

    {:noreply, state}
  end
end
