defmodule FileHandler do
  @moduledoc """
  Takes care of initializing the `number.log` file on start and manages
  the pool of `Writers`.

  Whenever a `Writer` is initialized it sunbscribes itself to the
  `FileHandler` by calling `register_writer/0`, after it's
  registered, `Connection` workers can ask to be assigend a `Writer`
  using `assign_writer/0` and can release them with `release_writer/0`.
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

  @doc """
  Registers a new `Writer` to the pool
  """
  def register_writer do
    GenServer.call(__MODULE__, :register)
  end

  @doc """
  Assigns a `Writer` to the calling process
  """
  def assign_writer do
    GenServer.call(__MODULE__, :assign)
  end

  @doc """
  Releases the `Writer` associated to the calling process and moves it
  to the free pool.
  """
  def release_writer do
    GenServer.call(__MODULE__, :release)
  end

  @doc """
  Returns a list with pool of unasigned `Writers`
  """
  def get_unasigned do
    GenServer.call(__MODULE__, :unasigned)
  end

  def get_registered do
    GenServer.call(__MODULE__, :registered)
  end

  def handle_call(
        :unasigned,
        _,
        [_file, {:free, free}, _registered] = state
      ) do
    {:reply, free, state}
  end

  def handle_call(
        :registered,
        _,
        [_file, _free, {:registered, registered}] = state
      ) do
    {:reply, registered, state}
  end

  def handle_call(
        :register,
        {pid, _tag},
        file: file,
        free: free,
        registered: registered
      ) do
    new_state = [file: file, free: [pid | free], registered: registered]
    {:reply, file, new_state}
  end

  def handle_call(
        :assign,
        {pid, _tag},
        file: file,
        free: [writer | free],
        registered: registered
      ) do
    new_state = [
      file: file,
      free: free,
      registered: Map.put(registered, pid, writer)
    ]

    {:reply, writer, new_state}
  end

  def handle_call(
        :release,
        {pid, _tag},
        file: file,
        free: free,
        registered: registered
      ) do
    {writer, new_registered} = Map.pop(registered, pid)
    new_state = [file: file, free: [writer | free], registered: new_registered]
    {:reply, :ok, new_state}
  end
end
