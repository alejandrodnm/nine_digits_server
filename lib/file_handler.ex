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
        {:ok, [file: file_path, free: [], registered: %{}]}

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

  # Change name to register_worker
  def register do
    GenServer.call(__MODULE__, :register)
  end

  # Change name to register
  def assign_writter do
    GenServer.call(__MODULE__, :assign)
  end

  def unregister do
    GenServer.call(__MODULE__, :unregister)
  end

  def handle_call(
        :register,
        {pid, tag},
        file: file,
        free: free,
        registered: registered
      ) do
    new_state = [file: file, free: [pid | free], registered: registered]
    {:reply, {:ok, file}, new_state}
  end

  def handle_call(
        :assign,
        {pid, tag},
        file: file,
        free: [writter | free],
        registered: registered
      ) do
    new_state = [
      file: file,
      free: free,
      registered: Map.put(registered, pid, writter)
    ]

    {:reply, {:ok, writter}, new_state}
  end

  def handle_call(
        :assign,
        {pid, tag},
        state
      ) do
    {:reply, {:ok, :ok}, state}
  end

  def handle_call(
        :unregister,
        {pid, tag},
        file: file,
        free: free,
        registered: registered
      ) do
    {writter, new_registered} = Map.pop(registered, pid)
    new_state = [file: file, free: [writter | free], registered: new_registered]
    {:reply, :ok, new_state}
  end
end
