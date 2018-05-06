require Logger

defmodule Stats do
  @moduledoc """
  Handles the stats and reporting of the application. Every 10 seconds
  it will timeout and write to `stdio` with the count of the newly
  recived nine digits number, the count of newly received duplicates
  and the total uniquer numbers.
  """
  use GenServer
  @timeout 10_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_opts) do
    {:ok, [unique: 0], @timeout}
  end

  def handle_info(:timeout, unique: old_unique) do
    duplicates = Repo.take_duplicates()
    unique = Repo.get_unique_count()
    new = unique - old_unique

    IO.binwrite(
      :stdio,
      "#{NaiveDateTime.utc_now()} - Received #{new} unique numbers, #{
        duplicates
      } duplicates. Unique total #{unique}\n"
    )

    {:noreply, [unique: unique], @timeout}
  end
end
