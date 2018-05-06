defmodule StatsTest do
  use ExUnit.Case

  setup do
    TestHelper.clean_state()
    Process.group_leader(Process.whereis(Stats), self())
    :ok
  end

  defp assert_io(new_unique, duplicates, total_unique) do
    send(Stats, :timeout)

    {:ok, regex} =
      Regex.compile(
        ~S"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d+ - " <>
          "Received #{new_unique} unique numbers, #{duplicates} duplicates." <>
          " Unique total #{total_unique}"
      )

    receive do
      {:io_request, _, reply_as, {:put_chars, _, msg}} ->
        assert Regex.match?(regex, msg)
        send(Stats, {:io_reply, reply_as, :ok})

      _ ->
        flunk()
    end
  end

  test "check empty stats" do
    assert_io(0, 0, 0)
  end

  test "check 3 unique numbers" do
    :ets.insert(:repo, [{1}, {2}, {3}])
    assert_io(3, 0, 3)
  end

  test "check 3 duplicate numbers" do
    :ets.insert(:counter, {:duplicates, 3})
    assert_io(0, 3, 0)
  end

  test "check 3 new unique and 6 numbers total" do
    :ets.insert(:repo, [{1}, {2}, {3}])
    assert_io(3, 0, 3)
    :ets.insert(:repo, [{4}, {5}, {6}])
    assert_io(3, 0, 6)
  end
end
