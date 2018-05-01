defmodule LoadTest do
  use ExUnit.Case
  @moduletag :load_test

  defp run_worker(i) do
    ip = Application.get_env(:nine_digits, :ip)
    port = Application.get_env(:nine_digits, :port)

    {:ok, socket} =
      :gen_tcp.connect(ip, port, [:binary, active: false, nodelay: true])

    run_worker(i * 200_000_000, socket)
  end

  def run_worker(i, socket) do
    item = Integer.to_string(i)
    padded_item = String.pad_leading(item, 9, "0")
    :ok = :gen_tcp.send(socket, "#{padded_item}\r\n")
    run_worker(i + 1, socket)
  end

  setup do
    Application.stop(:nine_digits)
    Application.start(:nine_digits)
  end

  test "connect 5 clients and send different items for 10 secods" do
    [0]
    |> Task.async_stream(&run_worker/1)
    |> Stream.run()

    :timer.sleep(10_000)
    Application.stop(:nine_digits)
  end
end
