defmodule Packet do
  @moduledoc """
  This module parses tcp packets, extracts the nine digits numbers and
  stores unique copies in ETS tables through the `Repo` module, and
  to disk through the `Writer` module.

  ETS tables provide atomic operation for insertion and updating,
  allowing concurrent writes from multiple processes instead of
  relying on a centralize write handler.
  """

  @doc ~S"""
  Parses the given `packet`, retrieves nine digits numbers and
  stores the result in the corresponding ETS table, and in disk
  using `writer` pid.

  Packets can contain a single line message or multiple messages as if
  they were merged by Nagle's algorithm Ex."123456789/r/n987654321/r/n".

  When a packet is received it's split at the CRLF ("\r\n") or LF ("\n")
  occurrences, the resulting parts go through a simple parsing process.
  If the message is in fact a nine digits number we try to insert it
  in the ETS table with `Repo.insert_new/1` which returns false if the
  number is already stored in the table, in which case we increase the
  duplicates number counter.

      iex> {:ok, writer} = Writer.start_link([])
      iex> Packet.parse_and_save("123456789\r\n987654321\n", writer)
      :ok
      iex> :ets.match_object(:repo, :"_")
      [{123456789}, {987654321}]

  If an incomplete message arrives it is returned to the caller as
  `{:ok, String.t()}` to keep it until it receives the missing piece.

      iex> {:ok, writer} = Writer.start_link([])
      iex> Packet.parse_and_save("123456789\r\n98765", writer)
      {:ok, "98765"}
      iex> :ets.match_object(:repo, :"_")
      [{123456789}]

  Duplicate messages are not stored an increase the duplicate counter.

      iex> {:ok, writer} = Writer.start_link([])
      iex> Packet.parse_and_save("123456789\n123456789\n123456789\n", writer)
      :ok
      iex> :ets.match_object(:repo, :"_")
      [{123456789}]
      iex> :ets.lookup(:counter, :duplicates)
      [duplicates: 2]

  Receiving the message "terminate" breaks the process and returns
  `:terminate`.

      iex> {:ok, writer} = Writer.start_link([])
      iex> Packet.parse_and_save("123456789\nterminate\n987654321\n", writer)
      :terminate
      iex> :ets.match_object(:repo, :"_")
      [{123456789}]

  Receiving an incorrect message breaks the process and returns
  `:error`.

      iex> {:ok, writer} = Writer.start_link([])
      iex> Packet.parse_and_save("123456789\nAinara\n987654321\n", writer)
      :error
      iex> :ets.match_object(:repo, :"_")
      [{123456789}]

  """
  @spec parse_and_save(String.t(), pid) ::
          :ok | {:ok, String.t()} | :error | :terminate
  def parse_and_save(packet, writer) do
    # When splitting at the CRLF if the message is whole we will get
    # "123456789\r\n" -> ["123456789", ""]
    #
    # If it's incomplete "123456789\r\n12" -> ["123456789", "12"]. This
    # will help us pattern match the end of the list on complete or
    # incomplete messages.
    split = Regex.split(~r/(\r\n|\n)/, packet)
    parse(:ok, split, writer, [])
  end

  @spec parse(
          :ok | :terminate | :error,
          list(String.t()),
          pid,
          list(String.t())
        ) :: :ok | {:ok, String.t()} | :terminate | :error
  defp parse(:ok, [""], writer, buffer) do
    save_to_disk(buffer, writer)
    :ok
  end

  defp parse(:ok, [partial_item], writer, buffer) do
    save_to_disk(buffer, writer)

    # We check against 11 instead of 9 because the message can be split
    # at the CRLF so we might end up with 123456789\r, which is a valid
    # partial number.
    if String.length(partial_item) > 11 do
      :error
    else
      {:ok, partial_item}
    end
  end

  defp parse(:ok, [item | items], writer, buffer) do
    {response, new_buffer} =
      if String.length(item) != 9 do
        {:error, buffer}
      else
        case Integer.parse(item) do
          {item_integer, ""} ->
            case save_to_ets(item_integer) do
              :new ->
                {:ok, [item_integer | buffer]}

              :duplicates ->
                {:ok, buffer}
            end

          _ ->
            if "terminate" == item do
              {:terminate, buffer}
            else
              {:error, buffer}
            end
        end
      end

    parse(response, items, writer, new_buffer)
  end

  defp parse(response, _items, writer, buffer) do
    save_to_disk(buffer, writer)
    response
  end

  @spec save_to_ets(integer) :: :new | :duplicates
  defp save_to_ets(item) do
    if Repo.insert_new(item) do
      :new
    else
      Repo.increase_duplicates_counter()
      :duplicates
    end
  end

  @spec save_to_disk(list(String.t()), pid) :: :ok
  defp save_to_disk([], _writer) do
    :ok
  end

  defp save_to_disk(buffer, writer) do
    Writer.append_line(writer, Enum.join(buffer, "\n"))
  end
end
