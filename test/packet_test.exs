defmodule PacketTest do
  use ExUnit.Case, async: true
  doctest Packet

  setup do
    :ets.delete_all_objects(:repo)
    :ets.delete_all_objects(:counter)
    :ok
  end
end
