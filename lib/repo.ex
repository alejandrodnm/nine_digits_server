defmodule Repo do
  @moduledoc ~S"""
  Stores and manages writes of new items.

  Creates two ets tables, `:repo` where the unique numbers are stored
  and `:counter` that contains a single element, a tuple
  `{:duplicates, integer()}` with the count of duplicate nine digits
  items received.

  On init it cleans the file that keeps the list of unique numbers.
  """
  use Agent

  def start_link(opts) do
    Agent.start_link(
      fn ->
        # Delete the file that holds the results. The `Writer`s will
        # create it on init.
        file_path = Application.get_env(:nine_digits, :file_path)

        case File.rm(file_path) do
          {:error, :enoent} -> :ok
          :ok -> :ok
        end

        repo =
          :ets.new(:repo, [
            :set,
            :public,
            :named_table,
            {:write_concurrency, true}
          ])

        counter =
          :ets.new(:counter, [
            :set,
            :public,
            :named_table,
            {:write_concurrency, true}
          ])

        :ets.insert(:counter, {:duplicates, 0})
        [repo: repo, counter: counter]
      end,
      opts
    )
  end

  @doc """
  Returns the new and duplicates counters and resets them.
  """
  @spec take_duplicates :: integer
  def take_duplicates do
    [{:duplicates, duplicates}] = :ets.take(:counter, :duplicates)
    :ets.insert_new(:counter, {:duplicates, 0})
    duplicates
  end

  @doc """
  Returns the number of unique numbers stored in the table.
  """
  @spec get_unique_count :: integer
  def get_unique_count do
    :ets.info(:repo, :size)
  end

  @doc """
  Inserts `item` if it's not already on the table. If `item` was
  inserted returns `true` otherwise returns `false`.
  """
  @spec insert_new(integer) :: boolean
  def insert_new(item) do
    :ets.insert_new(:repo, {item})
  end

  @doc """
  Increase the duplicates counter by 1.
  """
  @spec increase_duplicates_counter :: integer
  def increase_duplicates_counter do
    :ets.update_counter(:counter, :duplicates, 1, {:duplicates, 0})
  end
end
