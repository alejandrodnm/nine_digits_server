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
  @spec insert_new(String.t()) :: boolean
  def insert_new(item) do
    :ets.insert_new(:repo, {item, true})
  end

  @doc """
  Increase the given counter by 1
  """
  def increase_counter(:duplicates) do
    :ets.update_counter(:counter, :duplicates, 1, {:duplicates, 0})
  end
end
