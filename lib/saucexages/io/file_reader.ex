defmodule Saucexages.IO.FileReader do
  @moduledoc """
  Reads SAUCE data from files according to the SAUCE specification.

  SAUCE data is decoded decoded according to the SAUCE spec.

  If you are working with small files, it is recommended to use `Saucexages.IO.BinaryReader` instead.

  Files are opened with read and binary flags, and as such must be available for reading.

  ## General Usage

  The general use-case for the file reader is to work with binaries that you cannot fit in memory or you wish to offload some of the boiler-plate IO to this module.

  A general usage pattern on a local machine might be as follows:

  `FileReader.sauce("LD-ACID2.ANS")`

  ## Layout

  The layout of the binary read is assumed to be consistent with what is described in `Saucexages.IO.BinaryReader`.

  The SAUCE must exist at the *end* of a file, per the SAUCE spec. As such, this reader assumes that reading should begin at the end-of-file position (eof position). Note that this is *not* the same as the *end-of-file character* (eof character). The difference lies in the fact that the eof character comes before the SAUCE data, while the eof itself is the true termination of the file.

  SAUCE Block data itself is limited to 128 bytes for the SAUCE record, and 255 comment lines of 64-bytes each + 5 bytes for a comment ID. Therefore if you are not dealing with corrupted files, you can read a maximum of 128 + (255 * 64) + 5 bytes, or 16,453 bytes before you can give up scanning for a SAUCE. In practice, if you wish to scan a file in this manner, it may be better to follow the spec as this module does, or to scan up to the first eof character, starting from the eof position.

  ## Notes

  There are many SAUCE files in the wild that have data written *after* the SAUCE record, multiple eof characters, and multiple SAUCE records. As such, these cases are dealt with universally by obeying the SAUCE specification. Multiple eof characters is very common as many SAUCE writers have naively appended eof characters on each write instead of truncating the file after the eof character or doing an in-place update.

  Specifically, this reader will always read *only* from the eof position. It is possible to fix these cases using the `Saucexages.SauceBinary` module as well as some general binary matching, however these fixes should be viewed as outside the scope and concerns of this reader.

  Reads often require multiple position changes using the current device. This is because the comments cannot be reliably obtained without first scanning the SAUCE record. The comments block itself is of variable size and cannot reliably be obtained otherwise. If this is a concern, consider using the binary reader and reading the entire file or a feasible chunk that will obtain the SAUCE block data.
  """

  require Saucexages.Sauce
  alias Saucexages.{Sauce, SauceBlock}
  alias Saucexages.IO.SauceBinary
  alias Saucexages.Codec.Decoder

  @doc """
  Reads a file containing a SAUCE record and returns decoded SAUCE information as `{:ok, sauce_block}`.

  If the file does not contain a SAUCE record, `{:error, :no_sauce}` is returned.
  """
  @spec sauce(Path.t()) :: {:ok, SauceBlock.t} | {:error, :no_sauce} | {:error, term()}
  def sauce(path) when is_binary(path) do
    case File.open(path, [:binary, :read], &do_read_sauce/1) do
      {:ok, result} -> result
      err -> err
    end
  end

  @doc """
  Reads a binary containing a SAUCE record and returns the raw binary in the form `{:ok, {sauce_bin, comments_bin}}`.

  If the binary does not contain a SAUCE record, `{:error, :no_sauce}` is returned.
  """
  @spec raw(Path.t()) :: {:ok, {binary(), binary()}} | {:error, :no_sauce} | {:error, term()}
  def raw(path) when is_binary(path) do
    case File.open(path, [:binary, :read], &do_read_raw/1) do
      {:ok, result} -> result
      err -> err
    end
  end

  @doc """
  Reads a binary and returns the contents without the SAUCE block.

  It is not recommended to use this function for large files. Instead, get the index of where the SAUCE block starts and read until that point using a stream if you need the file contents.
  """
  @spec contents(Path.t()) :: {:ok, binary()} | {:error, term()}
  def contents(path) when is_binary(path) do
    with {:ok, file_bin} <- File.read(path) do
      SauceBinary.contents(file_bin)
    end
  end

  @doc """
  Reads a file containing a SAUCE record and returns the decoded SAUCE comments.
  """
  @spec comments(binary()) :: {:ok, [String.t]} | {:error, :no_sauce} | {:error, :no_comments} | {:error, term()}
  def comments(path) when is_binary(path) do
    case File.open(path, [:binary, :read], &do_read_comments/1) do
      {:ok, result} -> result
      err -> err
    end
  end

  @doc """
  Reads a file with a SAUCE record and returns whether or not a SAUCE comments block exists within the SAUCE block.

  Will match a comments block only if it a SAUCE record exists. Comment fragments are not considered to be valid without the presence of a SAUCE record.
  """
  @spec comments?(binary()) :: boolean()
  def comments?(path) when is_binary(path) do
    case File.open(path, [:binary, :read], &do_comments?/1) do
      {:ok, result} -> result
      err -> err
    end
  end

  @doc """
  Reads a file and returns whether or not a SAUCE record exists.
  """
  @spec sauce?(Path.t()) :: boolean()
  def sauce?(path) when is_binary(path) do
    case File.open(path, [:binary, :read], &do_sauce?/1) do
      {:ok, result} -> result
      err -> err
    end
  end

  defp do_read_comments(fd) do
    with {:ok, comment_lines} <- read_comment_lines(fd),
         {:ok, comments} = comments_result <- read_comments_block(fd, comment_lines),
         [_ | _] <- comments do
      comments_result
    else
      [] -> {:error, :no_comments}
      {:error, _reason} = err -> err
      _ -> {:error, "Unable to read SAUCE comments."}
    end
  end

  defp do_comments?(fd) do
    with {:ok, comment_lines} <- read_comment_lines(fd),
         {:ok, _comments} <- extract_comments_block(fd, comment_lines) do
      true
    else
      _ ->
        false
    end
  end

  defp do_sauce?(fd) do
    case extract_sauce_binary(fd) do
      {:ok, _sauce_bin} -> true
      _ -> false
    end
  end

  defp do_read_sauce(fd) do
    with {:ok, sauce_record_bin} <- extract_sauce_binary(fd),
         {:ok, %{comment_lines: comment_lines} = sauce_record} <- Decoder.decode_record(sauce_record_bin),
         {:ok, comments} <- read_comments_block(fd, comment_lines)
      do
      Decoder.decode_sauce(sauce_record, comments)
    else
      {:error, _reason} = err -> err
      err -> {:error, {"Unable to read sauce", err}}
    end
  end

  defp do_read_raw(fd) do
    with {:ok, sauce_record_bin} <- extract_sauce_binary(fd),
         {:ok, %{comment_lines: comment_lines} = _sauce_record} <- Decoder.decode_record(sauce_record_bin),
         {:ok, comments_bin} when is_binary(comments_bin) <- extract_comments_block(fd, comment_lines)
      do
      {:ok, {sauce_record_bin, comments_bin}}
    else
      {:error, _reason} = err -> err
      err -> {:error, {"Unable to read sauce", err}}
    end
  end

  defp read_comments_block(fd, comment_lines) when is_integer(comment_lines) and comment_lines > 0 do
    with {:ok, comments_bin} when is_binary(comments_bin) <- extract_comments_block(fd, comment_lines) do
      Decoder.decode_comments(comments_bin, comment_lines)
    else
      # Here we try to be tolerant in case the comment line value from the SAUCE record was nonsense
      {:error, :no_comments} -> {:ok, []}
      # Here we may have failed for some other reason, like the OS so in this case we do want to be intolerant
      {:error, _reason} = err -> err
      _ -> {:error, "Unable to read comments block."}
    end
  end

  defp read_comments_block(_fd, comment_lines) when is_integer(comment_lines) do
    {:ok, []}
  end

  defp read_comment_lines(fd) do
    case extract_sauce_binary(fd) do
      {:ok, sauce_record_bin} ->
        SauceBinary.comment_lines(sauce_record_bin)
      {:error, _reason} = err ->
        err
    end
  end

  defp extract_sauce_binary(fd) do
    with {:ok, file_size} <- :file.position(fd, :eof),
         true <- file_size >= Sauce.sauce_record_byte_size(),
         {:ok, _offset} = :file.position(fd, {:eof, -Sauce.sauce_record_byte_size()}),
         {:ok, sauce_record_bin} = :file.read(fd, Sauce.sauce_record_byte_size()),
         true <- SauceBinary.matches_sauce?(sauce_record_bin) do
      {:ok, sauce_record_bin}
    else
      false -> {:error, :no_sauce}
      {:error, _reason} = err -> err
      _ -> {:error, "Error reading SAUCE record binary."}
    end
  end

  defp extract_comments_block(fd, comment_lines) when is_integer(comment_lines) and comment_lines > 0 do
    with comment_block_offset <- Sauce.sauce_byte_size(comment_lines),
         comment_block_size <- Sauce.comment_block_byte_size(comment_lines),
         # we could use cursor here, but the cursor should normally be at eof after reading the SAUCE so we might as well read from eof to be safer
         {:ok, _comments_offset} = :file.position(fd, {:eof, -comment_block_offset}),
         {:ok, comments_bin} = comments_result <- :file.read(fd, comment_block_size),
         true <- SauceBinary.matches_comment_block?(comments_bin) do
      comments_result
    else
      false -> {:error, :no_comments}
      # We tried to read but maybe the comment line pointer was inaccurate/wrong.
      # Rather than erroring out, we try to be tolerant as this case is somewhat common in the wild.
      {:error, :einval} -> {:error, :no_comments}
      {:error, _reason} = err -> err
      err -> {:error, "Unable to read SAUCE comments.", err}
    end
  end

  defp extract_comments_block(_bin, comment_lines) when is_integer(comment_lines) do
    # no comments present but we tried to grab them anyway
    {:error, :no_comments}
  end

end
