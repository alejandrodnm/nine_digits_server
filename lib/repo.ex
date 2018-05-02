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
      shards =
        0..9
        |> Enum.map(fn i ->
          :ets.new(String.to_atom("shard_#{i}"), [
            :set,
            :public,
            :named_table,
            {:write_concurrency, true}
          ])
        end)

      counter =
        :ets.new(:counter, [
          :set,
          :public,
          :named_table,
          {:write_concurrency, true}
        ])

      :ets.insert(:counter, {:duplicates, 0})
      [shards: shards, counter: counter]
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
    0..9
    |> Enum.reduce(0, fn i, acc ->
      :ets.info(String.to_existing_atom("shard_#{i}"), :size) + acc
    end)
  end

  @doc """
  Inserts the item if it's not already on the table
  """
  @spec insert_new(String.t()) :: boolean
  def insert_new(item) do
    i = String.first(item)
    :ets.insert_new(String.to_existing_atom("shard_" <> i), {item, true})
  end

  @doc """
  Increase the given counter by 1
  """
  def increase_counter(:duplicates) do
    :ets.update_counter(:counter, :duplicates, 1, {:duplicates, 0})
  end
end
