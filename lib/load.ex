defmodule Load do
  @moduledoc """
  Executes load tests
  """

  def load do
    start = DateTime.utc_now()

    [0]
    |> Task.async_stream(&run_worker/1, timeout: :infinity, max_concurrency: 5)
    |> Stream.run()

    finish = DateTime.utc_now()
    IO.inspect(DateTime.diff(finish, start, :millisecond))
  end

  defp run_worker(i) do
    ip = Application.get_env(:nine_digits, :ip)
    port = Application.get_env(:nine_digits, :port)

    {:ok, socket} = :gen_tcp.connect(ip, port, [:binary, active: false])

    start = i * 200_000_000
    run_worker(start, start + 2_000_000, socket)
  end

  def run_worker(i, max, socket) when i < max do
    item = Integer.to_string(i)
    padded_item = String.pad_leading(item, 9, "0")
    :ok = :gen_tcp.send(socket, "#{padded_item}\r\n")
    run_worker(i + 1, max, socket)
  end

  def run_worker(i, max, socket) do
    :ok
  end
end
