defmodule Server.Supervisor do
  @moduledoc """
  Supervisor for `Server` and the `Connection` pool.
  """
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {Server, name: Server},
      {Connection.Supervisor, name: Connection.Supervisor}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
