defmodule Saucexages.Util.Binary do
  @moduledoc false

  ## General functions for working with Elixir/Erlang binaries.

  @doc """
  Pads a binary with the provided `padding` at the end, repeating the padding until `count` bytes is reached.

  If `count` is larger than the existing binary, no padding is applied.
  If the binary is already longer than the count, no padding will be applied.
  Padding will be applied 1 byte at a time, meaning that any padding provided greater than 1 byte may only be partially applied if the total size is reached first.

  ## Examples

    iex> pad_trailing_bytes(<<1, 2, 3>>, 6, <<6>>)
    <<1, 2, 3, 6, 6, 6>>

    iex> pad_trailing_bytes(<<1, 2, 3>>, 2, <<6>>)
    <<1, 2, 3>>

  """
  @spec pad_trailing_bytes(binary(), pos_integer(), binary()) :: binary()
  def pad_trailing_bytes(bin, count, padding) when is_binary(bin) and is_integer(count) and count >= 0 do
    pad_bytes(bin, :trailing, count, padding)
  end

  @doc """
  Pads a binary with the provided `padding` at the beginning, repeating the padding until `count` bytes is reached.

  If `count` is larger than the existing binary, no padding is applied.
  If the binary is longer than the count, no padding will be applied.
  Padding will be applied 1 byte at a time, meaning that any padding provided greater than 1 byte may only be partially applied if the total size is reached first.

  ## Examples

    iex> pad_leading_bytes(<<1, 2, 3>>, 6, <<6>>)
    <<6, 6, 6, 1, 2, 3>>

    iex> pad_leading_bytes(<<1, 2, 3>>, 2, <<6>>)
    <<1, 2, 3>>

  """
  @spec pad_leading_bytes(binary(), pos_integer(), binary()) :: binary()
  def pad_leading_bytes(bin, count, padding) when is_binary(bin) and is_integer(count) and count >= 0  do
    pad_bytes(bin, :leading, count, padding)
  end

  @doc """
  Creates a binary of a fixed size according to `count` padded with `padding`.

  Pads a binary with the provided `padding` at the end, repeating the padding until `count` bytes is reached if padding is required.
  If truncation is required, any bytes after `count` will be truncated.

  ## Examples

    iex> pad_truncate(<<1, 2, 3>>, 6, <<6>>)
    <<1, 2, 3, 6, 6, 6>>

    iex> pad_truncate(<<1, 2, 3>>, 5, <<6, 6, 6>>)
    <<1, 2, 3, 6, 6>>

    iex> pad_truncate(<<1, 2, 3>>, 2, <<6, 6, 6>>)
    <<1, 2>>

  """
  @spec pad_truncate(binary(), pos_integer(), binary()) :: binary()
  def pad_truncate(bin, count, padding) when is_binary(bin) and is_integer(count) and count >= 0 do
    maybe_padded_bin = pad_trailing_bytes(bin, count, padding)
    <<maybe_padded_bin :: binary - size(count)>>
  end

  #TODO: benchmark these alternates
  #pad_trailing_bytes(bin, count, padding) |> :binary.part(0, count)

  #    bin_size = byte_size(string)
  #    cond do
  #      bin_size == count ->
  #        string
  #      bin_size < count ->
  #        pad_trailing_bytes(string, count, padding)
  #      bin_size > count ->
  #        <<string::binary-size(count)>>
  #    end

  @doc """
  Replaces a binary at a specific position within a binary with a new sub-binary.

  The new sub-binary should not cause the binary to grow larger than the existing binary.
  """
  @spec replace_binary_at(binary(), non_neg_integer(), binary()) :: binary()
  def replace_binary_at(bin, position, value) when is_binary(bin) and is_integer(position) and position >= 0 and is_binary(value) and position < byte_size(bin) and (byte_size(value) + position) <= byte_size(bin) do
    bin_size = byte_size(bin)
    value_size = byte_size(value)
    remaining_size = bin_size - position - value_size
    <<start :: binary - size(position), _ :: binary - size(value_size), rest :: binary - size(remaining_size)>> = bin
    <<start :: binary - size(position), value :: binary - size(value_size), rest :: binary - size(remaining_size)>>
  end

  def replace_binary_at(_bin, _position, _value) do
    raise ArgumentError, "The replacement binary size and position should not cause the binary to grow larger than the existing binary."
  end

  defp build_filler(bin, 0, _remaining_padding, _padding) when is_binary(bin) do
    bin
  end

  defp build_filler(bin, remaining_count, <<pad_byte :: binary - size(1), rest :: binary>>, padding) when is_binary(bin) do
    build_filler(<<bin :: binary, pad_byte :: binary - size(1)>>, remaining_count - 1, rest, padding)
  end

  defp build_filler(bin, remaining_count, <<>>, padding) do
    build_filler(bin, remaining_count, padding, padding)
  end

  defp pad_bytes(bin, kind, count, padding) when is_binary(bin) and is_integer(count) and count >= 0 do
    bin_size = byte_size(bin)
    if bin_size >= count do
      bin
    else
      filler = build_filler(<<>>, count - bin_size, padding, padding)
      case kind do
        :leading -> <<filler :: binary, bin :: binary>>
        :trailing -> <<bin :: binary, filler :: binary>>
      end

    end
  end

end
