require Logger

defmodule Load do
  @moduledoc """
  Executes load tests
  """

  def random_load do
    0..4
    |> Task.async_stream(
      &run_random_worker/1,
      timeout: :infinity,
      max_concurrency: 5
    )
    |> Stream.run()
  end

  defp run_random_worker(_) do
    ip = Application.get_env(:nine_digits, :ip)
    port = Application.get_env(:nine_digits, :port)
    {:ok, socket} = :gen_tcp.connect(ip, port, [:binary, active: false])
    run_random_worker(socket, :rand.uniform(2_000_000))
  end

  defp run_random_worker(socket, 0) do
    :gen_tcp.close(socket)
    run_random_worker(0)
  end

  defp run_random_worker(socket, n) do
    item = Integer.to_string(:rand.uniform(999_999_999))
    padded_item = String.pad_leading(item, 9, "0")
    :ok = :gen_tcp.send(socket, "#{padded_item}\r\n")
    run_random_worker(socket, n - 1)
  end

  def unique_load do
    0..4
    |> Task.async_stream(&run_worker/1, timeout: :infinity, max_concurrency: 5)
    |> Stream.run()
  end

  defp run_worker(i) do
    ip = Application.get_env(:nine_digits, :ip)
    port = Application.get_env(:nine_digits, :port)

    {:ok, socket} = :gen_tcp.connect(ip, port, [:binary, active: false])

    start_time = DateTime.utc_now()
    start = i * 200_000_000
    run_worker(start, start + 2_000_000, socket, start_time)
  end

  def run_worker(i, max, socket, start) when i < max do
    item = Integer.to_string(i)
    padded_item = String.pad_leading(item, 9, "0")
    :ok = :gen_tcp.send(socket, "#{padded_item}\r\n")
    run_worker(i + 1, max, socket, start)
  end

  def run_worker(_, _, _, start) do
    finish = DateTime.utc_now()
    Logger.info("#{DateTime.diff(finish, start, :millisecond)}")
    :ok
  end
end
