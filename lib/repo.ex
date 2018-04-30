defmodule Repo do
  @moduledoc """
  Stores and manages writes of new nine digits items
  """
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> :ets.new(:repo, [:set, :public, :named_table]) end)
  end
end
