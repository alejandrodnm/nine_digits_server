require Logger

defmodule NineDigits do
  @moduledoc """
  Parses packets, validates and saves input. Returns the corresponding
  messages to the connections.
  """

  def process_packet(packet, writter) do
    splited = Regex.split(~r/(\r\n|\n)/, packet)
    process_packet(splited, :ok, writter)
  end

  def process_packet(_, :terminate, _) do
    :terminate
  end

  def process_packet(_, :error, _) do
    :error
  end

  def process_packet([""], :ok, _) do
    :ok
  end

  def process_packet([item], :ok, _) do
    {:ok, item}
  end

  def process_packet([item | items], :ok, writter) do
    status =
      if String.length(item) == 9 do
        cond do
          {item_integer, ""} = Integer.parse(item) ->
            process_valid_item(item, item_integer, writter)

          "terminate" == item ->
            :terminate

          true ->
            :error
        end
      else
        :error
      end

    process_packet(items, status, writter)
  end

  # @spec process_valid_item(String.t(), pid) :: :ok
  defp process_valid_item(item, item_integer, writter) do
    if Repo.insert_new(item_integer) do
      Writter.append_line(writter, item)
    else
      Repo.increase_counter(:duplicates)
    end

    :ok
  end
end
