defmodule Writer do
  @moduledoc """
  Process in charge of setting up and writting to the logger file
  """
  use GenServer

  @file_options Application.get_env(:nine_digits, :file_options, [
                  :delayed_write
                ])

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  @doc false
  def ping(server) do
    GenServer.call(server, :ping)
  end

  def init(_args) do
    file =
      FileHandler.register_writer()
      |> File.open!([:append] ++ @file_options)

    {:ok, [file: file]}
  end

  @doc """
  Writes the givem `text` to the file, adding a line break at the end.
  """
  @spec append_line(pid, String.t()) :: :ok
  def append_line(server, text) do
    GenServer.cast(server, {:append, text <> "\n"})
  end

  def handle_cast({:append, text}, [file: file] = state) do
    IO.binwrite(file, text)
    {:noreply, state}
  end

  def handle_call(:ping, _, state) do
    {:reply, :pong, state}
  end
end
