require Logger

defmodule Connection do
  @moduledoc """
  Handles client accepted connections. If the Server if shutdown, the
  connections will be restared and request the new listen_socket to the
  new Server.
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

  @doc """
  Handles messages from the clients, packets received must be 9 digits
  followed by a carriage return, otherwise the connection will be close.
  """
  def handle_info(
        {:tcp, _socket, packet},
        [socket: socket, listen_socket: listen_socket] = state
      ) do
    Logger.debug(fn ->
      "#{inspect(self())}: received #{packet}"
    end)

    case Regex.named_captures(~r/^(?<item>[0-9]{9})(\r\n|\r|\n)$/, packet) do
      %{"item" => item} ->
        Logger.debug(fn ->
          "#{inspect(self())}: valid packet #{item}"
        end)

        process_item(item)

        # On the test environment we block for a response to avoid
        # race conditions on assertions
        if Mix.env() == :test do
          :gen_tcp.send(socket, "ok")
        end

        {:noreply, state}

      nil ->
        Logger.debug(fn ->
          "#{inspect(self())}: invalid packet #{packet} closing connection"
        end)

        :ok = :gen_tcp.close(socket)
        new_socket = accept_connection(listen_socket)

        {:noreply, [socket: new_socket, listen_socket: listen_socket]}
    end
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

  def handle_info({:tcp_error, _, reason}, state) do
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

  @spec process_item(String.t()) :: :ok
  defp process_item(item) do
    # FIXME Update the current counter

    if :ets.insert_new(:repo, {item, true}) do
      FileHandler.append_line(FileHandler, item)
      :ok
    else
      :ok
    end
  end
end
