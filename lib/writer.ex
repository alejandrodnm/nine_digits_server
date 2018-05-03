defmodule Writter do
  @moduledoc """
  Process in charge of setting up and writting to the logger file
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_args) do
    Process.send_after(self(), :started, 0)
    {:ok, []}
  end

  def handle_info(:started, _) do
    {:ok, file_path} = FileHandler.register()

    file = File.open!(file_path, [:append, :delayed_write])
    {:noreply, [file: file]}
  end

  def append_line(server, item) do
    GenServer.cast(server, {:append, item <> "\n"})
  end

  def handle_cast({:append, item}, [file: file] = state) do
    IO.binwrite(file, item)
    {:noreply, state}
  end
end
