defmodule Load do
  @moduledoc """
  Executes load tests
  """

  def load do
    0..4
    |> Task.async_stream(&run_worker/1, timeout: 10_000)
    |> Stream.run()
  end

  defp run_worker(i) do
    ip = Application.get_env(:nine_digits, :ip)
    port = Application.get_env(:nine_digits, :port)

    {:ok, socket} = :gen_tcp.connect(ip, port, [:binary, active: false])

    run_worker(i * 200_000_000, socket)
  end

  def run_worker(i, socket) do
    item = Integer.to_string(i)
    padded_item = String.pad_leading(item, 9, "0")
    :ok = :gen_tcp.send(socket, "#{padded_item}\r\n")
    run_worker(i + 1, socket)
  end
end
