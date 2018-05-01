defmodule FileHandler do
  @moduledoc """
  Process in charge of setting up and writting to the logger file
  """
  use GenServer

  def start_link(opts) do
    file_path = Application.get_env(:nine_digits, :file_path)
    GenServer.start_link(__MODULE__, [file_path: file_path], opts)
  end

  @doc """
  Removes the file if it exists and returns a newly open file ready to
  be written.
  """
  def init(file_path: file_path) do
    case remove_file(file_path) do
      :ok ->
        case File.open(file_path, [:append, :delayed_write, :raw]) do
          {:ok, file} ->
            {:ok, [file: file]}

          {:error, reason} ->
            {:stop, "#{reason} error when opening `#{file_path}`"}
        end

      {:error, reason} ->
        {:stop, "#{reason} error when deleting `#{file_path}`"}
    end
  end

  @spec remove_file(String.t()) :: :ok | {:error, String.t()}
  defp remove_file(file_path) do
    case File.rm(file_path) do
      {:error, :enoent} -> :ok
      {:error, _reason} = err -> err
      :ok -> :ok
    end
  end

  @doc """
  Appends the given item to the end of the file.
  """
  @spec append_line(GenServer.server(), String.t()) :: :ok
  def append_line(server, item) do
    # GenServer.call(server, {:append, item <> "\n"})
    :ok
  end

  def ping(server) do
    GenServer.call(server, :ping)
  end

  def handle_call({:append, item}, _, [file: file] = state) do
    IO.binwrite(file, item)
    {:reply, :ok, state}
  end

  def handle_call(:ping, _from, state) do
    {:reply, :pong, state}
  end
end
