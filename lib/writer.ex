defmodule Writer do
  @moduledoc """
  Process in charge of setting up and writting to the logger file
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_args) do
    file =
      FileHandler.register()
      |> File.open!([:append, :delayed_write])

    {:ok, [file: file]}
  end

  def append_line(server, item) do
    GenServer.cast(server, {:append, item <> "\n"})
  end

  def handle_cast({:append, item}, [file: file] = state) do
    IO.binwrite(file, item)
    {:noreply, state}
  end
end
