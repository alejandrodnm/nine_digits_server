defmodule Repo do
  @moduledoc """
  Stores and manages writes of new items

  Creates two ets tables, `:repo` where the unique numbers are stored
  and `:counter` that contains a single element:

  {:counter, <new> integer, <duplicates> integer>}
  """
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn ->
      repo = :ets.new(:repo, [:set, :public, :named_table])
      counter = :ets.new(:counter, [:set, :public, :named_table])
      :ets.insert(:counter, {:counter, 0, 0})
      [repo: repo, counter: counter]
    end)
  end

  @doc """
  Returns the new and duplicates counters and resets them
  """
  @spec take_stats :: [new: integer, duplicates: integer]
  def take_stats do
    [{:counter, new, duplicates}] = :ets.take(:counter, :counter)
    :ets.insert_new(:counter, {:counter, 0, 0})
    [new: new, duplicates: duplicates]
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
  @spec insert_new(String.t()) :: boolean
  def insert_new(item) do
    :ets.insert_new(:repo, {item, true})
  end

  @doc """
  Increase the given counter by 1
  """
  @spec increase_counter(:new | :duplicates) :: integer
  def increase_counter(:new) do
    :ets.update_counter(:counter, :counter, {2, 1}, {:counter, 0, 0})
  end

  def increase_counter(:duplicates) do
    :ets.update_counter(:counter, :counter, {3, 1}, {:counter, 0, 0})
  end
end
