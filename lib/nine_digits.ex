require Logger

defmodule NineDigits do
  @moduledoc """
  Parses packets, validates and saves input. Returns the corresponding
  messages to the connections.
  """

  def process_packet(packet, writter) do
    splited = Regex.split(~r/(\r\n|\n)/, packet)
    process_packet(splited, :ok, writter, [])
  end

  def process_packet(_, :terminate, writter, buffer) do
    Writter.append_line(writter, Enum.join(buffer, "\n"))
    :terminate
  end

  def process_packet(_, :error, writter, buffer) do
    Writter.append_line(writter, Enum.join(buffer, "\n"))
    :error
  end

  def process_packet([""], :ok, writter, buffer) do
    Writter.append_line(writter, Enum.join(buffer, "\n"))
    :ok
  end

  @doc """
  If the partial item has a length bigger than 9 then it's an
  invalid packet and we don't have to parse the rest.
  """
  def process_packet([item], :ok, writter, buffer) do
    Writter.append_line(writter, Enum.join(buffer, "\n"))

    if String.length(item) > 9 do
      :error
    else
      {:ok, item}
    end
  end

  def process_packet([item | items], :ok, writter, buffer) do
    {status, new_buffer} =
      if String.length(item) == 9 do
        cond do
          {item_integer, ""} = Integer.parse(item) ->
            case process_valid_item(item_integer) do
              :new ->
                {:ok, [item_integer | buffer]}

              :duplicates ->
                {:ok, buffer}
            end

          "terminate" == item ->
            {:terminate, buffer}

          true ->
            {:error, buffer}
        end
      else
        {:error, buffer}
      end

    process_packet(items, status, writter, new_buffer)
  end

  # @spec process_valid_item(String.t(), pid) :: :ok
  defp process_valid_item(item) do
    if Repo.insert_new(item) do
      :new
    else
      Repo.increase_counter(:duplicates)
      :duplicates
    end
  end
end
