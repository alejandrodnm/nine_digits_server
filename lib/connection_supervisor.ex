defmodule Connection.Supervisor do
  @moduledoc """
  Supervises the concurrent tcp connections, if one fails is restarted
  so another user can connect.
  """
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Starts as many connection proccesses as the concurrency level.
  The concurrency level is set in the config and defaults to 5.
  """
  def init(:ok) do
    concurrency = Application.get_env(:nine_digits, :concurrency, 5)

    children =
      for n <- 1..concurrency do
        %{
          id: {Connection, n},
          start:
            {Connection, :start_link,
             [[name: String.to_atom("Connection#{n}")], n]}
        }
      end

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 6)
  end
end
