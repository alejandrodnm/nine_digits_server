defmodule Stats do
  @moduledoc """
  Handles the stats and reporting of the application
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(opts) do
    {:ok, [new: 0, duplicates: 0], 10_000}
  end

  def handle_info(:timeout, new: old_new, duplicates: old_duplicates) do
    [new: new, duplicates: duplicates] = Repo.take_stats()
    unique_total = Repo.get_unique_count()

    IO.binwrite(
      :stdio,
      "Received #{new} unique numbers, #{duplicates} duplicates. Unique total #{
        unique_total
      }"
    )

    {:noreply, [new: new, duplicates: duplicates], 10_000}
  end
end
