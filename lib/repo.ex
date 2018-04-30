defmodule Repo do
  @moduledoc """
  Stores and manages writes of new nine digits items
  """
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn ->
      repo = :ets.new(:repo, [:set, :public, :named_table])
      counter = :ets.new(:counter, [:set, :public, :named_table])
      :ets.insert(counter, [{:new, 0}, {:duplicates, 0}])
      [repo: repo, counter: counter]
    end)
  end
end
