require Logger

defmodule Connection do
  @moduledoc """
  Handles client accepted connections. If the Server if shutdown, the
  connections will be restared and request the new listen_socket to the
  new Server.
  """
  use GenServer

  # if true the connections will send a response to the
  # clients after procesing an item
  @tcp_response Application.get_env(:nine_digits, :tcp_response, false)
  @idle_timeout Application.get_env(:nine_digits, :idle_timeout, 5000)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_args) do
    Process.send_after(self(), :started, 0)
    {:ok, []}
  end

  @doc """
  Called immediately after process initialization. Gets the listening
  socket from Server and waits for new client connections.

  If the client connects and doesn't send a message after @idle_timeout ms
  the connection will be close.
  """
  def handle_info(:started, _) do
    listen_socket = Server.listen_socket(Server)

    Logger.debug(fn ->
      "#{inspect(self())}: waiting connection"
    end)

    socket = accept_connection(listen_socket)
    {:noreply, [socket: socket], @idle_timeout}
  end

  @doc """
  Handles messages from the clients, packets received must be 9 digits
  followed by a carriage return, otherwise the connection will be close.

  After receiving a valid packet if the doesn't send a message after
  @idle_timeout ms the connection will be close.
  """
  def handle_info({:tcp, _socket, packet}, [socket: socket] = state) do
    Logger.debug(fn ->
      "#{inspect(self())}: received #{packet}"
    end)

    case Regex.named_captures(~r/^(?<item>[0-9]{9})(\r\n|\r|\n)$/, packet) do
      %{"item" => item} ->
        Logger.debug(fn ->
          "#{inspect(self())}: valid packet #{item}"
        end)

        process_item(item)

        if @tcp_response do
          :gen_tcp.send(socket, "ok")
        end

        {:noreply, state, @idle_timeout}

      nil ->
        Logger.debug(fn ->
          "#{inspect(self())}: invalid packet #{packet} closing connection"
        end)

        :ok = :gen_tcp.close(socket)
        {:stop, :invalid_packet, state}
    end
  end

  def handle_info(:timeout, state) do
    Logger.debug(fn ->
      "#{inspect(self())}: connection closed due to timeout"
    end)

    {:stop, :tcp_closed, state}
  end

  def handle_info({:tcp_closed, _}, state) do
    Logger.debug(fn ->
      "#{inspect(self())}: connection closed"
    end)

    {:stop, :tcp_closed, state}
  end

  def handle_info({:tcp_error, _, reason}, state) do
    Logger.debug(fn ->
      "#{inspect(self())}: connection closed due to #{reason}"
    end)

    {:stop, reason, state}
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

  @spec process_item(String.t()) :: :ok
  defp process_item(item) do
    if Repo.insert_new(item) do
      FileHandler.append_line(FileHandler, item)
      Repo.increase_counter(:new)
      :ok
    else
      Repo.increase_counter(:duplicates)
      :ok
    end
  end
end
