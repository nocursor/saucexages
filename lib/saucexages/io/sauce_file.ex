defmodule Saucexages.IO.SauceFile do
  @moduledoc """
  Functions for handling SAUCE files in the file system.

  Any devices passed are assumed to be file descriptors that are opened using `:read` and `:binary` at the minimum.
  SAUCE does not use UTF-8 files, so do not pass such devices or you risk incorrect behavior.
  """

  require Saucexages.Sauce
  require Logger
  alias Saucexages.{Sauce}
  alias Saucexages.IO.SauceBinary

  @type part :: {non_neg_integer(), non_neg_integer()}

  @doc """
  Returns the byte size of the contents in a file, before any potential SAUCE block.

  Contents is strictly defined as all data before a properly written SAUCE record and optionally a comments block. If there is no SAUCE data, the contents size is the actual size of the file.
  """
  @spec contents_size(File.io_device()) :: {:ok, non_neg_integer()} | {:error, term()}
  def contents_size(fd) do
    case :file.position(fd, :eof) do
      {:ok, pos} when pos >= Sauce.sauce_record_byte_size() ->
        calculate_contents_size(fd)
      {:ok, pos} ->
        {:ok, pos}
      {:error, _reason} = err -> err
    end
  end

  defp calculate_contents_size(fd) do
    # Here we calculate the contents size by walking backwards, first checking for the SAUCE, followed by any comments as specified by the SAUCE.
    # If there is garbage such as non-matched comments, we consider this content since we don't know what it actually is and cannot assume.
    with {:ok, sauce_offset} = :file.position(fd, {:eof, -Sauce.sauce_record_byte_size()}),
         {:ok, sauce_record_bin} = :file.read(fd, Sauce.sauce_record_byte_size()),
         :ok <- SauceBinary.verify_sauce_record(sauce_record_bin),
         {:ok, comment_lines} <- SauceBinary.comment_lines(sauce_record_bin),
         # The cursor reset itself after reading the SAUCE, so we need to account for the 128 bytes again
         comment_block_offset = Sauce.sauce_byte_size(comment_lines),
         comment_block_size = Sauce.comment_block_byte_size(comment_lines),
         {:ok, comments_offset} = :file.position(fd, {:eof, -comment_block_offset}),
         {:ok, comments_bin} <- :file.read(fd, comment_block_size) do
      if SauceBinary.matches_comment_block?(comments_bin) do
        {:ok, comments_offset}
      else
        {:ok, sauce_offset}
      end
    else
      {:error, :no_sauce} ->
        :file.position(fd, :eof)
      {:error, _reason} = err ->
        err
      err -> {:error, {"Error reading contents.", err}}
    end
  end

  @doc """
  Splits a SAUCE file into parts by contents, and optionally SAUCE, and finally comments. Each part is a tuple of position and length.

  Parts will be returned in the following possible forms:

  * `{contents, sauce, comments}` - SAUCE with comments
  * `{contents, sauce}` - SAUCE with no comments
  * `{contents}` - No SAUCE

  Each part has the form - `{position, length}` where position is absolute within the file.
  """
  @spec split_parts(File.io_device()) :: {:ok, {part()}} | {:ok, {part(), part()}} | {:ok, {part(), part(), part()}}
  def split_parts(fd) do
    #TODO: Decide return format - may want list of tuples instead or to return fixed tuples with :no_sauce and :no_comments instead
    with {:ok, sauce_offset} = :file.position(fd, {:eof, -Sauce.sauce_record_byte_size()}),
         {:ok, sauce_record_bin} = :file.read(fd, Sauce.sauce_record_byte_size()),
         :ok <- SauceBinary.verify_sauce_record(sauce_record_bin),
         {:ok, comment_lines} <- SauceBinary.comment_lines(sauce_record_bin),
         # The cursor reset itself after reading the SAUCE, so we need to account for the 128 bytes again
         comment_block_offset = Sauce.sauce_byte_size(comment_lines),
         comment_block_size = Sauce.comment_block_byte_size(comment_lines),
         {:ok, comments_offset} = :file.position(fd, {:eof, -comment_block_offset}),
         {:ok, comments_bin} <- :file.read(fd, comment_block_size) do
      if SauceBinary.matches_comment_block?(comments_bin) do
        {:ok, {{0, comments_offset}, {comments_offset + comment_block_size, Sauce.sauce_record_byte_size()}, {comments_offset, comment_block_size}}}
      else
        {:ok, {{0, sauce_offset}, {sauce_offset, Sauce.sauce_record_byte_size()}}}
      end
    else
      {:error, :no_sauce} ->
        case :file.position(fd, :eof) do
          {:ok, pos} -> {:ok, {0, pos}}
        end
      {:error, _reason} = err ->
        err
      err -> {:error, {"Error reading contents.", err}}
    end
  end

  @doc """
  Reads a SAUCE file descriptor and returns the byte size of the SAUCE file from the file descriptor.
  """
  @spec read_byte_size(File.io_device()) :: {:ok, non_neg_integer()} | {:error, term()}
  def read_byte_size(fd) do
    #save the cursor position
    {:ok, cur} = :file.position(fd, :cur)
    try do
      :file.position(fd, :eof)
    after
      :file.position(fd, cur)
    end
  end

  @doc """
  Checks if the file descriptor is for a SAUCE.
  """
  @spec sauce?(File.io_device()) :: boolean()
  def sauce?(fd) do
    case extract_sauce_binary(fd) do
      {:ok, _sauce_bin} -> true
      _ -> false
    end
  end

  defp extract_sauce_binary(fd) do
    with {:ok, _offset} = :file.position(fd, {:eof, -Sauce.sauce_record_byte_size()}),
         {:ok, sauce_record_bin} = :file.read(fd, Sauce.sauce_record_byte_size()),
         :ok <- SauceBinary.verify_sauce_record(sauce_record_bin) do
      {:ok, sauce_record_bin}
    else
      {:error, _reason} = err -> err
      _ -> {:error, "Error reading SAUCE record."}
    end
  end

end
