require Logger

defmodule NineDigits do
  @moduledoc """
  Parses packets, validates and saves input. Returns the corresponding
  messages to the connections.
  """

  def process_packet(packet) do
    process_packet(Regex.split(~r/(\r\n|\n)/, packet), :ok)
  end

  def process_packet(_, :terminate) do
    :terminate
  end

  def process_packet(_, :error) do
    :error
  end

  def process_packet([], :ok) do
    :ok
  end

  def process_packet([], {:ok, partial_item}) do
    {:ok, partial_item}
  end

  def process_packet([""], :ok) do
    :ok
  end

  def process_packet([item], :ok) do
    {:ok, item}
  end

  def process_packet([item | items], :ok) do
    status =
      case Regex.named_captures(
             ~r/^((?<item>[0-9]{9})|(?<terminate>terminate))$/,
             item
           ) do
        %{"item" => item, "terminate" => ""} ->
          Logger.debug(fn ->
            "#{inspect(self())}: valid packet #{item}"
          end)

          process_valid_item(item)
          :ok

        %{"terminate" => "terminate", "item" => ""} ->
          :terminate

        nil ->
          Logger.debug(fn ->
            "#{inspect(self())}: invalid item #{item} closing connection"
          end)

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
