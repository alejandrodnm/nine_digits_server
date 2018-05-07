defmodule NineDigits.Supervisor do
  @moduledoc """
  Top level supervisor.
  """
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {Repo, name: Repo},
      {Writer.Supervisor, name: Writer.Supervisor},
      {Server.Supervisor, name: Server.Supervisor},
      {Stats, name: Stats}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
