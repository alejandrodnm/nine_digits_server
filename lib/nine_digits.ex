require Logger

defmodule NineDigits do
  @moduledoc """
  Parses packets, validates and saves input. Returns the corresponding
  messages to the connections.
  """

  def process_packet(packet) do
    splited = Regex.split(~r/(\r\n|\n)/, packet)
    process_packet(splited, :ok)
  end

  def process_packet(_, :terminate) do
    :terminate
  end

  def process_packet(_, :error) do
    :error
  end

  def process_packet([""], :ok) do
    :ok
  end

  def process_packet([item], :ok) do
    {:ok, item}
  end

  def process_packet([item | items], :ok) do
    status =
      if String.length(item) == 9 do
        try do
          process_valid_item(String.to_integer(item))
          :ok
        rescue
          ArgumentError ->
            if item == "terminate", do: :terminate, else: :error
        end
      else
        :error
      end

    process_packet(items, status)
  end

  @spec process_valid_item(String.t()) :: :ok
  defp process_valid_item(item) do
    if Repo.insert_new(item) do
      # FIXME
      # FileHandler.append_line(FileHandler, item)
      :ok
    else
      Repo.increase_counter(:duplicates)
      :ok
    end
  end
end
