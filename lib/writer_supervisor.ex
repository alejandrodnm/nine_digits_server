defmodule Writer.Supervisor do
  @moduledoc """
  Supervises the pool of `Writer`.
  """
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Starts as many `Writer` proccesses as the concurrency level.
  The concurrency level is set in the config and defaults to 5
  """
  def init(:ok) do
    concurrency = Application.get_env(:nine_digits, :concurrency, 5)

    children =
      for n <- 1..concurrency do
        %{
          id: {Writer, n},
          start: {Writer, :start_link, [[name: String.to_atom("Writer#{n}")]]}
        }
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
