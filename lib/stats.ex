defmodule Stats do
  @moduledoc """
  Handles the stats and reporting of the application
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(opts) do
    {:ok, [unique: 0, duplicates: 0], 10_000}
  end

  def handle_info(:timeout, unique: old_unique, duplicates: old_duplicates) do
    duplicates = Repo.take_duplicates()
    unique = Repo.get_unique_count()
    new = unique - old_unique

    IO.binwrite(
      :stdio,
      "#{NaiveDateTime.utc_now()} - Received #{new} unique numbers, #{
        duplicates
      } duplicates. Unique total #{unique}\n"
    )

    {:noreply, [unique: unique, duplicates: duplicates], 10_000}
  end
end
