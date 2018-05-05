require Logger

defmodule Connection do
  @moduledoc """
  Handles a single client connections, retrieves the listen socket
  from `Server`. The accepting connection process has a timeout of 4
  seconds, when triggered it enqueues a new accept connection message,
  this is to avoid blocking forever in case the supervisor sends it
  a message.

  This module is in charge of requesting a `Writer` to the `FileHandler`
  module an keeps it in it's state, this is to increase throughput when
  writing to disk.

  Once a connection is established with a client if `@idle_timeout`
  (defaults to 5000) ms pass without receiving a message, the connection
  will be close.
  """
  use GenServer

  @tcp_response Application.get_env(:nine_digits, :tcp_response, false)
  @idle_timeout Application.get_env(:nine_digits, :idle_timeout, 5000)
  @typep state :: [
           listen_socket: port(),
           socket: port(),
           partial_item: String.t(),
           writer: pid
         ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def ping(server) do
    GenServer.call(server, :ping)
  end

  def init(_args) do
    writer = FileHandler.assign_writer()
    send(self(), :accept_connection)

    {:ok,
     [
       listen_socket: nil,
       socket: nil,
       partial_item: "",
       writer: writer
     ]}
  end

  def terminate(a, b) do
    FileHandler.unregister()
    :ok
  end

  @doc """
  Gets the listening socket from `Server` if required, and Waits for
  new client connections. Once a connection is established if
  `@idle_timeout` (defaults to 5000) ms pass without receiving a
  message, the connection will be close.
  """
  def handle_info(:accept_connection, [
        {:listen_socket, nil},
        {:socket, nil} = socket,
        {:partial_item, ""} = partial_item,
        writer
      ]) do
    listen_socket = Server.listen_socket(Server)

    handle_accept_connection([
      {:listen_socket, listen_socket},
      socket,
      partial_item,
      writer
    ])
  end

  def handle_info(
        :accept_connection,
        [
          _listen_socket,
          {:socket, nil},
          {:partial_item, ""},
          _writer
        ] = state
      ) do
    handle_accept_connection(state)
  end

  @doc """
  """
  def handle_info(
        {:tcp, _socket, packet},
        [
          listen_socket,
          socket: socket,
          partial_item: partial_item,
          writer: writer
        ] = state
      ) do
    :inet.setopts(socket, active: :once)

    case Packet.parse_and_save(partial_item <> packet, writer) do
      :ok ->
        if @tcp_response do
          :gen_tcp.send(socket, "ok")
        end

        {:noreply,
         [listen_socket, socket: socket, partial_item: "", writer: writer],
         @idle_timeout}

      {:ok, new_partial_item} ->
        if @tcp_response do
          :gen_tcp.send(socket, "ok")
        end

        {:noreply,
         [
           listen_socket,
           socket: socket,
           partial_item: new_partial_item,
           writer: writer
         ], @idle_timeout}

      :terminate ->
        Application.get_env(:nine_digits, :terminate, &:init.stop/0).()
        {:stop, :terminate, state}

      :error ->
        :ok = :gen_tcp.close(socket)
        send(self(), :accept_connection)

        {:noreply,
         [listen_socket, socket: nil, partial_item: "", writer: writer]}
    end
  end

  def handle_info(:timeout, state) do
    clean_and_restart_connection(state, "idle client")
  end

  def handle_info({:tcp_closed, _}, state) do
    clean_and_restart_connection(state, "client closed connection")
  end

  def handle_info({:tcp_error, _, reason}, state) do
    clean_and_restart_connection(state, reason)
  end

  def handle_call(:ping, _, [_, _, _, {:writer, writer}] = state) do
    {:reply, Writer.ping(writer), state}
  end

  defp handle_accept_connection(
         [
           {:listen_socket, listen_socket},
           {:socket, nil} = socket,
           {:partial_item, ""} = partial_item,
           writer
         ] = state
       ) do
    Logger.debug(fn ->
      "#{inspect(self())}: waiting connection"
    end)

    case accept_connection(listen_socket) do
      {:ok, new_socket} ->
        {:noreply,
         [
           {:listen_socket, listen_socket},
           {:socket, new_socket},
           partial_item,
           writer
         ], @idle_timeout}

      {:error, :closed} ->
        send(self(), :accept_connection)
        {:noreply, [{:listen_socket, nil}, socket, partial_item, writer]}

      {:error, :timeout} ->
        send(self(), :accept_connection)
        {:noreply, state}
    end
  end

  # Accept connection or timeout after 4 seconds
  @spec accept_connection(port()) :: {:ok, port()} | {:error, atom}
  defp accept_connection(listen_socket) do
    case :gen_tcp.accept(listen_socket, 4000) do
      {:ok, socket} = response ->
        :inet.setopts(socket, active: :once)

        Logger.debug(fn ->
          "#{inspect(self())}: connection established"
        end)

        response

      error ->
        error
    end
  end

  @spec clean_and_restart_connection(state, String.t()) :: {:noreply, state}
  defp clean_and_restart_connection(
         [listen_socket, {:socket, socket}, _, writer],
         reason
       ) do
    Logger.debug(fn ->
      "#{inspect(self())}: connection closed due to #{reason}"
    end)

    :gen_tcp.close(socket)
    send(self(), :accept_connection)
    {:noreply, [listen_socket, {:socket, nil}, {:partial_item, ""}, writer]}
  end
end
