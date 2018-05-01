defmodule NineDigits.State.Supervisor do
  @moduledoc """
  Top level supervisor
  """
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {FileHandler, name: FileHandler},
      {Repo, name: Repo}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
