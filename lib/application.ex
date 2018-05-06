defmodule NineDigits.Application do
  @moduledoc """
  NineDigits application, it starts the supervision tree.
  """
  use Application
  alias NineDigits.Supervisor

  def start(_type, _args) do
    Supervisor.start_link(name: NineDigits.Supervisor)
  end
end
