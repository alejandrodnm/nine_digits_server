defmodule Repo do
  @moduledoc ~S"""
  Stores and manages writes of new items

  Creates two ets tables, `:repo` where the unique numbers are stored
  and `:counter` that contains a single element, a tuple
  `{:duplicates, integer()}` with the count of duplicate nine digits
  items received.
  """
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn ->
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
    end)
  end

  @doc """
  Returns the new and duplicates counters and resets them
  """
  @spec take_duplicates :: integer
  def take_duplicates do
    [{:duplicates, duplicates}] = :ets.take(:counter, :duplicates)
    :ets.insert_new(:counter, {:duplicates, 0})
    duplicates
  end

  @doc """
  Returns the number of unique numbers stored in the table
  """
  @spec get_unique_count :: integer
  def get_unique_count do
    :ets.info(:repo, :size)
  end

  @doc """
  Inserts the item if it's not already on the table
  """
  @spec insert_new(integer) :: boolean
  def insert_new(item) do
    :ets.insert_new(:repo, {item})
  end

  @doc """
  Increase the given counter by 1
  """
  @spec increase_duplicates_counter :: integer
  def increase_duplicates_counter do
    :ets.update_counter(:counter, :duplicates, 1, {:duplicates, 0})
  end
end
