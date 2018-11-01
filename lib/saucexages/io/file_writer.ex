defmodule Saucexages.IO.FileWriter do
  @moduledoc """
  Functions for writing and maintaining SAUCE files.

  This writer is primarily for working with larger files. You may elect to use `Saucexages.IO.BinaryWriter` if you want a more flexible writer, provided that your files are small and fit in memory.

  The general approach this writer takes is to be pragmatic about what is and is not a SAUCE and where according to the SAUCE spec data should be located. The general strategy of this writer is to avoid costly seeks and rewrites of very large files. Instead, the writer generally tries to perform most operations from a SAUCE-centric point-of-view. That is, most operations are focused on scanning backwards through a file in a deterministic, constant way.

  A good example of pragmatic behavior is how this writer deals with EOF characters. For example, according to the SAUCE spec, a SAUCE should always be written after an EOF character. This does not mean that the SAUCE will be immediately after the EOF. To avoid scanning entire large files, we merely check for the presence of an EOF character relative to the SAUCE block. If an EOF character is not before the SAUCE block, we insert one. This can result in an extra byte written, but with the benefit that seeking through the whole file is no longer necessary.
  """

  require Saucexages.Sauce
  alias Saucexages.{Sauce, SauceBlock}
  alias Saucexages.IO.{SauceBinary, SauceFile}
  alias Saucexages.Codec.{Encoder}

  @doc """
  Writes the given SAUCE info to the file at the given `path`.
  """
  @spec write(Path.t(), SauceBlock.t()) :: :ok
  def write(path, sauce_block) do
    case File.open(path, [:binary, :write, :read], fn (io_device) -> do_write(io_device, sauce_block) end) do
      {:ok, sauce_response} -> sauce_response
      err -> err
    end
  end

  defp do_write(fd, sauce_block) do
    with {:ok, encoded_sauce_bin} <- Encoder.encode_record(sauce_block),
         {:ok, encoded_comments_bin} <- Encoder.encode_comments(sauce_block),
         {:ok, contents_size} <- SauceFile.contents_size(fd),
         {:ok, _write_position} <- :file.position(fd, contents_size),
         {:ok, eof_prefix?} <- eof_prefixed?(fd) do
      item = if eof_prefix? do
        [encoded_comments_bin, encoded_sauce_bin]
      else
        [<<Sauce.eof_character>>, encoded_comments_bin, encoded_sauce_bin]
      end
      # truncate the file in case there is any randomness after the point where we want to write the SAUCE or an old SAUCE
      :file.truncate(fd)
      IO.binwrite(fd, item)
    end
  end

  @doc """
  Removes any comments, if present from a SAUCE and rewrites the SAUCE accordingly.

  Can be used to remove a SAUCE comments block or to clean erroneous comment information such as mismatched comment lines or double comment blocks.
  """
  @spec remove_comments(Path.t()) :: :ok | {:error, term()}
  def remove_comments(path) do
    case File.open(path, [:binary, :write, :read], &do_remove_comments/1) do
      {:ok, sauce_response} -> sauce_response
      err -> err
    end
  end

  defp do_remove_comments(fd) do
    with :ok <- sauce_seekable(fd),
         {:ok, _sauce_offset} = :file.position(fd, {:eof, -Sauce.sauce_record_byte_size()}),
         {:ok, sauce_record_bin} = :file.read(fd, Sauce.sauce_record_byte_size()),
         :ok <- SauceBinary.verify_sauce_record(sauce_record_bin),
         {:ok, comment_lines} <- SauceBinary.comment_lines(sauce_record_bin) do
      maybe_truncate_comments(fd, sauce_record_bin, comment_lines)
    else
      {:error, :no_sauce} ->
        :ok
      {:error, _reason} = err ->
        err
      err -> {:error, {"Error reading contents.", err}}
    end

  end

  @doc """
  Removes a SAUCE record from a file.

  Both the SAUCE record and comments block will be removed.
  """
  @spec remove_sauce(Path.t()) :: :ok | {:error, term()}
  def remove_sauce(path) when is_binary(path) do
    case File.open(path, [:binary, :write, :read], &do_remove_sauce/1) do
      {:ok, sauce_response} -> sauce_response
      err -> err
    end
  end

  defp do_remove_sauce(fd) do
    with {:ok, file_size} <- :file.position(fd, :eof),
         true <- file_size >= Sauce.sauce_record_byte_size(),
         {:ok, contents_size} <- SauceFile.contents_size(fd) do
      maybe_truncate(fd, file_size, contents_size)
    else
      false -> {:error, :no_sauce}
      err -> err
    end
  end

  defp write_encoded(fd, encoded_sauce_bin, encoded_comments_bin, position) do
    with {:ok, _write_position} <- :file.position(fd, position),
         {:ok, eof_prefix?} <- eof_prefixed?(fd) do
      item = if eof_prefix? do
        [encoded_sauce_bin, encoded_comments_bin, encoded_comments_bin]
      else
        [<<Sauce.eof_character>>, encoded_comments_bin, encoded_sauce_bin]
      end
      IO.binwrite(fd, item)
    end
  end

  defp eof_prefixed?(fd) do
    case :file.position(fd, :cur) do
      {:ok, 0} -> {:ok, false}
      {:ok, _pos} -> cursor_eof_prefixed?(fd)
      {:error, _reason} = err -> err
    end
  end

  defp cursor_eof_prefixed?(fd) do
    with {:ok, _pos} <- :file.position(fd, {:cur, -1}),
         {:ok, previous_bin} <- :file.read(fd, 1) do
      {:ok, previous_bin == <<Sauce.eof_character()>>}
    else
      {:error, _reason} = err -> err
      _ -> {:error, "Unable to check EOF prefix."}
    end
  end

  defp maybe_truncate_comments(fd, sauce_record_bin, comment_lines) when comment_lines > 0 do
    with {:ok, file_size} <- :file.position(fd, :eof),
         {:ok, updated_sauce_bin} <- reset_sauce_comments(sauce_record_bin),
         comment_block_offset = Sauce.sauce_byte_size(comment_lines),
         comment_block_size = Sauce.comment_block_byte_size(comment_lines),
         {:ok, comments_offset} = :file.position(fd, {:eof, -comment_block_offset}),
         {:ok, comments_bin} <- :file.read(fd, comment_block_size) do
      # TODO: refactor - this is extremely yuck since we need a lot of sanity checks, branches, and multiple writes (truncate + write).
      # Alternative approaches:
      # 1. Copy the file, make the changes, and swap the new file
      # 2. Rewrite the file byte by byte by reading until the comments/sauce position, and writing the new SAUCE
      # 3. Do all of this as is, but exclusive which isn't guaranteed for some file systems
      # 4. Write new SAUCE over old one, starting at where comments may or may not be. This leaves the file in an invalid state though until we finish by truncating, vs. the existing approach truncates first, leaving the file valid if something blows up before the update is written.
      if SauceBinary.matches_comment_block?(comments_bin) do
        case maybe_truncate(fd, file_size, comments_offset) do
          :ok -> write_encoded(fd, updated_sauce_bin, <<>>, comments_offset)
          {:error, _reason} = err -> err
        end
      else
        write_encoded(fd, updated_sauce_bin, <<>>, {:eof, -Sauce.sauce_record_byte_size()})
      end
    else
      err -> err
    end
  end

  defp maybe_truncate_comments(_fd, _sauce_record_bin, _comment_lines) do
    :ok
  end

  defp reset_sauce_comments(sauce_bin) when is_binary(sauce_bin) do
    encoded_comment_lines = Encoder.encode_integer(0, Sauce.field_size(:comment_lines))
    SauceBinary.write_field(sauce_bin, :comment_lines, encoded_comment_lines)
  end

  defp maybe_truncate(fd, file_size, contents_size) when file_size > contents_size do
    with {:ok, _pos} <- :file.position(fd, contents_size) do
      :file.truncate(fd)
    end
  end

  defp maybe_truncate(_fd, file_size, contents_size) when file_size == contents_size do
    {:ok, file_size}
  end

  defp sauce_seekable(fd) do
    with {:ok, file_size} <- :file.position(fd, :eof),
         true <- file_size >= Sauce.sauce_record_byte_size() do
      :ok
    else
      false -> {:error, :no_sauce}
      {:error, _reason} = err -> err
    end
  end

end
