require Logger

defmodule Load do
  @moduledoc """
  Executes a load test, it creates 5 concurrent connections and
  starts sending a random quantity of random numbers per connection.
  When a connection reaches its maximum quantity, it closes the connection
  and starts the process again.

  This module is to be used with docker-compose, that's why the host is
  hardcoded to "server".
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
    host =
      case System.get_env("NINE_DIGITS_HOST") do
        nil ->
          {127, 0, 0, 1}

        host_name ->
          String.to_charlist(host_name)
      end

    case :gen_tcp.connect(host, 4000, [
           :binary,
           active: false
         ]) do
      {:ok, socket} ->
        run_random_worker(socket, :rand.uniform(2_000_000))

      {:error, reason} ->
        Logger.error(
          "Could not connect reason #{reason}. Retrying in 2 seconds"
        )

        :timer.sleep(2000)
        run_random_worker(0)
    end
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
end

Load.random_load()
