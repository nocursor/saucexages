defmodule Saucexages.IO.BinaryWriter do
  @moduledoc """
  Functions for writing and maintaining SAUCE binaries.
  """

  require Saucexages.Sauce
  alias Saucexages.{Sauce, SauceBlock}
  alias Saucexages.IO.SauceBinary
  alias Saucexages.Codec.{Encoder}

  @doc """
  Writes the given SAUCE block to the provided binary.
  """
  #TODO: Validation
  @spec write(binary(), SauceBlock.t) :: {:ok, binary()} | {:error, term()}
  def write(bin, sauce_block) when is_binary(bin) and is_map(sauce_block) do
    with {:ok, encoded_sauce_bin} <- Encoder.encode_record(sauce_block),
         {:ok, comments_bin} <- Encoder.encode_comments(sauce_block),
         {:ok, contents_bin} <- SauceBinary.contents(bin, true) do
      encoded_bin = <<contents_bin :: binary, comments_bin :: binary, encoded_sauce_bin :: binary - size(Sauce.sauce_record_byte_size())>>
      {:ok, encoded_bin}
    else
      {:error, _reason} = err -> err
      _ -> {:error, "Unable to write SAUCE."}
    end
  end

  @doc """
  Removes any comments, if present from a SAUCE and rewrites the SAUCE accordingly.

  Can be used to remove a SAUCE comments block or to clean erroneous comment information such as mismatched comment lines or double comment blocks.
  """
  @spec remove_comments(binary()) :: {:ok, binary()} | {:error, :no_sauce} | {:error, term()}
  def remove_comments(bin) when is_binary(bin) do
    {contents_bin, sauce_bin, _comments_bin} = SauceBinary.split_all(bin)
    with {:ok, updated_sauce_bin} <- reset_sauce_comments(sauce_bin) do
      {:ok, <<contents_bin :: binary, updated_sauce_bin :: binary - size(Sauce.sauce_record_byte_size())>>}
    else
      {:error, :no_sauce} -> {:ok, bin}
      {:error, _reason} = err -> err
      _ -> {:error, "Unable to remove SAUCE comments."}
    end
  end

  defp reset_sauce_comments(<<>> = _sauce_bin) do
    {:error, :no_sauce}
  end

  defp reset_sauce_comments(sauce_bin) when is_binary(sauce_bin) do
    encoded_comment_lines = Encoder.encode_integer(0, Sauce.field_size(:comment_lines))
    SauceBinary.write_field(sauce_bin, :comment_lines, encoded_comment_lines)
  end

  @doc """
  Removes a SAUCE block from a binary.

  Both the SAUCE record and comments block will be removed.
  """
  @spec remove_sauce(binary()) :: {:ok, binary()} | {:error, term()}
  def remove_sauce(bin) when is_binary(bin) do
    SauceBinary.contents(bin)
  end

end
