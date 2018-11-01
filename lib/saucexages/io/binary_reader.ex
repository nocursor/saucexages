defmodule Saucexages.IO.BinaryReader do
  @moduledoc """
  Reads SAUCE data from binaries according to the SAUCE specification.

  SAUCE data is decoded decoded according to the SAUCE spec.

  If you need to read files from the local file system directly in a more efficient manner, see `Saucexages.IO.FileReader`.

  ## General Usage

  The general use-case for the binary reader is to work with binaries that you can fit in memory. You should prefer this use-case whenever possible to free yourself from problems that may arise when working directly with another underlying medium such as the FileSystem.

  Most files that were commonly used for SAUCE are very small (ex: ANSi graphics) and an ideal fit for the binary reader. This also implies that this reader is suitable for use perhaps in a network service, streaming process, or similar context where loading the entire binary would not be a burden on the rest of the system.

  A general usage pattern on a local machine might be as follows:

  ```elixir
  File.read!("LD-ACID2.ANS") |> BinaryReader.sauce()
  ```

  ## Layout

  Binaries are generally assumed to take the following forms in pseudo-code below.

  ### Sauce with No comments

  ```elixir
  <<contents::binary, eof_character::binary, sauce::binary-size(128)>>
  ```

  ### Sauce with Comments

  ```elixir
  <<contents::binary, eof_character::binary, comments::binary-size(line_count), sauce::binary-size(128)>>
  ```

  ### No SAUCE with EOF character

  ```elixir
  <<contents::binary, eof_charter::binary>>
  ```

  ### No SAUCE with no EOF character

  ```elixir
  <<contents::binary>>
  ```

  ## Notes

  The operations within this module take the approach of tolerant reading while still following the SAUCE spec as closely as possible.

  For example, comments with a SAUCE are only read according to the comment lines value specified in a SAUCE record. A binary may have a comments block buried within it, but if the SAUCE record does not agree, no effort is made to find the binary.

  If you wish to work with SAUCE-related binaries at a lower-level or build your own binary reader, see `Saucexages.SauceBinary`. This module can also be used to build readers that relax or constrain the SAUCE spec, such as in the case of reading comment blocks.
  """

  require Saucexages.Sauce
  alias Saucexages.{SauceBlock}
  alias Saucexages.IO.SauceBinary
  alias Saucexages.Codec.Decoder

  @doc """
  Reads a binary containing a SAUCE record and returns decoded SAUCE information as `{:ok, sauce_block}`.

  If the binary does not contain a SAUCE record, `{:error, :no_sauce}` is returned.
  """
  @spec sauce(binary()) :: {:ok, SauceBlock.t} | {:error, :no_sauce} | {:error, :invalid_sauce} | {:error, term()}
  def sauce(bin) when is_binary(bin) do
    with {:ok, {sauce_bin, comments_bin}} <- SauceBinary.sauce(bin),
         {:ok, %{comment_lines: comment_lines} = sauce_record} <- Decoder.decode_record(sauce_bin),
         {:ok, comments} <- read_comments(comments_bin, comment_lines) do
      Decoder.decode_sauce(sauce_record, comments)
    else
      {:error, _reason} = err -> err
      err -> {:error, {"Unable to read sauce", err}}
    end
  end

  defp read_comments(comments_bin, comment_lines) do
    case Decoder.decode_comments(comments_bin, comment_lines) do
      {:ok, comments} ->
        {:ok, comments}
      {:error, :no_comments} ->
        {:ok, []}
      {:error, _reason} = err ->
        err
    end
  end

  @doc """
  Reads a binary containing a SAUCE record and returns the raw binary in the form `{:ok, {sauce_bin, comments_bin}}`.

  If the binary does not contain a SAUCE record, `{:error, :no_sauce}` is returned.
  """
  @spec raw(binary()) :: {:ok, {binary(), binary()}} | {:error, :no_sauce} | {:error, term()}
  def raw(bin) when is_binary(bin) do
    SauceBinary.sauce(bin)
  end

  @doc """
  Reads a binary containing a SAUCE record and returns the decoded SAUCE comments.
  """
  @spec comments(binary()) :: {:ok, [String.t]} | {:error, :no_sauce} | {:error, :no_comments} | {:error, term()}
  def comments(bin) when is_binary(bin) do
    with {:ok, {comments_bin, line_count}} <- SauceBinary.comments(bin) do
      Decoder.decode_comments(comments_bin, line_count)
    end
  end

  @doc """
  Reads a binary and returns the contents without the SAUCE block.
  """
  @spec contents(binary()) :: {:ok, binary()} | {:error, term()}
  def contents(bin) when is_binary(bin) do
    SauceBinary.contents(bin)
  end

  @doc """
  Reads a binary and returns whether or not a SAUCE comments block exists within the SAUCE block.

  Will match a comments block only if it a SAUCE record exists. Comment fragments are not considered to be valid without the presence of a SAUCE record.
  """
  @spec comments?(binary()) :: boolean()
  def comments?(bin) when is_binary(bin) do
    SauceBinary.comments?(bin)
  end

  @doc """
  Reads a binary and returns whether or not a SAUCE record exists.

  Will match both binary that is a SAUCE record and binary that contains a SAUCE record.
  """
  @spec sauce?(binary()) :: boolean()
  def sauce?(bin) when is_binary(bin) do
    SauceBinary.sauce?(bin)
  end

end
