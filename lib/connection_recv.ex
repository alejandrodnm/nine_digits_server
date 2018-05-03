require Logger

defmodule ConnectionRecv do
  @moduledoc """
  Handles client accepted connections. If the Server if shutdown, the
  connections will be restared and request the new listen_socket to the
  new Server.
  """
  import ExProf.Macro
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

    # FIXME with a timeout
    socket = accept_connection(listen_socket)
    start = DateTime.utc_now()
    do_recv(socket, "", :ok)
    finish = DateTime.utc_now()
    IO.inspect(DateTime.diff(finish, start, :millisecond))
    # {:ok, writter} = FileHandler.assign_writter()

    # {:noreply, [socket: socket, partial_item: "", writter: :ok, start: start],
    #  @idle_timeout}
    {:stop, :stop}
  end

  # def terminate(reason, state) do
  #   FileHandler.unregister()
  #   reason
  # end

  def do_recv(socket, partial_item, writter) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, packet} ->
        {records, result} =
          profile do
            NineDigits.Regex.process_packet(partial_item <> packet, writter)
          end

        case result do
          :ok ->
            if @tcp_response do
              :gen_tcp.send(socket, "ok")
            end

            do_recv(socket, "", writter)

          {:ok, new_partial_item} ->
            if @tcp_response do
              :gen_tcp.send(socket, "ok")
            end

            do_recv(socket, new_partial_item, writter)

          :terminate ->
            Application.get_env(:nine_digits, :terminate, &:init.stop/0).()
            {:stop, :terminate}

          :error ->
            :ok = :gen_tcp.close(socket)
            {:stop, :invalid_packet}
        end

      {:error, :closed} ->
        :ok

      {:error, :einval} ->
        IO.inspect("EINVAL")
        do_recv(socket, partial_item, writter)
    end
  end

  @doc """
  Handles messages from the clients, packets received must be 9 digits
  followed by a carriage return, otherwise the connection will be close.

  After receiving a valid packet if the doesn't send a message after
  @idle_timeout ms the connection will be close.
  """
  def handle_info(
        {:tcp, _socket, packet},
        [
          socket: socket,
          partial_item: partial_item,
          writter: writter,
          start: start
        ] = state
      ) do
    # :inet.setopts(socket, active: :once)

    {:noreply,
     [
       socket: socket,
       partial_item: partial_item,
       writter: writter,
       start: start
     ], @idle_timeout}

    # case NineDigits.process_packet(partial_item <> packet, writter) do
    #   :ok ->
    #     if @tcp_response do
    #       :gen_tcp.send(socket, "ok")
    #     end

    #     {:noreply, [socket: socket, partial_item: "", writter: writter],
    #      @idle_timeout}

    #   {:ok, new_partial_item} ->
    #     if @tcp_response do
    #       :gen_tcp.send(socket, "ok")
    #     end

    #     {:noreply,
    #      [socket: socket, partial_item: new_partial_item, writter: writter],
    #      @idle_timeout}

    #   :terminate ->
    #     Application.get_env(:nine_digits, :terminate, &:init.stop/0).()
    #     {:stop, :terminate, state}

    #   :error ->
    #     :ok = :gen_tcp.close(socket)
    #     {:stop, :invalid_packet, state}
    # end
  end

  def handle_info(:timeout, state) do
    Logger.debug(fn ->
      "#{inspect(self())}: connection closed due to timeout"
    end)

    {:stop, :tcp_closed, state}
  end

  def handle_info(
        {:tcp_closed, _},
        [
          socket: socket,
          partial_item: partial_item,
          writter: writter,
          start: start
        ] = state
      ) do
    Logger.debug(fn ->
      "#{inspect(self())}: connection closed"
    end)

    finish = DateTime.utc_now()
    IO.inspect(DateTime.diff(finish, start, :millisecond))
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
end
