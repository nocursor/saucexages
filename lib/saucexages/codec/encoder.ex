defmodule Saucexages.Codec.Encoder do
  @moduledoc """
  Functions for encoding SAUCE blocks as binary.
  """

  require Codepagex
  require Saucexages.Sauce
  require Saucexages.Codec.Encodings
  require Saucexages.DataType
  require Saucexages.MediaInfo
  alias Saucexages.{MediaInfo, Sauce, SauceBlock}
  alias Saucexages.Util.Binary
  alias Saucexages.Codec.{Encodings}

  @doc """
  Encodes a string for SAUCE using CP437, padding as needed with spaces according to size.
  """
  @spec encode_string(String.t(), pos_integer()) :: binary()
  def encode_string(string, size) when is_binary(string) do
    String.trim(string) |> do_encode_string(size, <<32>>)
  end

  def encode_string(_string, size) do
    do_encode_string("", size, <<32>>)
  end

  @doc """
  Encodes a C-style string for SAUCE using CP437, padding as needed with zeros according to size.
  """
  @spec encode_cstring(String.t(), pos_integer()) :: binary()
  def encode_cstring(string, size) when is_binary(string) do
    String.trim(string) |> do_encode_string(size, <<0>>)
  end

  def encode_cstring(_string, size) do
    do_encode_string("", size, <<0>>)
  end

  defp do_encode_string(string, size, padding) do
    with {:ok, string_bytes, _} <- Codepagex.from_string(string, Encodings.encoding(:cp437), Codepagex.replace_nonexistent("")) do
      Binary.pad_truncate(string_bytes, size, padding)
    else
      _ -> :binary.copy(padding, size)
    end
  end

  @doc """
  Encodes an elixir date time as a SAUCE date time binary in the format "CCMMYYDD".
  """
  @spec encode_date(DateTime.t()) :: binary()
  def encode_date(%{year: year, month: month, day: day}) do
    year_string = Integer.to_string(year) |> String.pad_leading(4, "0")
    month_string = Integer.to_string(month) |> String.pad_leading(2, "0")
    day_string = Integer.to_string(day) |> String.pad_leading(2, "0")

    Enum.join([year_string, month_string, day_string])
  end

  @doc """
  Encodes the SAUCE version.
  """
  @spec encode_version(String.t()) :: binary()
  def encode_version(version)

  def encode_version(version) when is_binary(version) do
    encode_string(version, Sauce.field_size(:version))
  end

  def encode_version(_version) do
    Sauce.sauce_version()
  end

  @doc """
  Encodes an integer to a given size as an unsigned little integer. If the integer is larger than the size allows, it will wrap.
  """
  @spec encode_integer(non_neg_integer(), pos_integer()) :: binary()
  def encode_integer(value, size) when is_integer(value) and is_integer(size) and size > 0 do
    <<value::unsigned-little-integer-unit(8)-size(size)>>
  end

  @doc """
  Encodes a given SAUCE block field.
  """
  @spec encode_field(Sauce.field_id(), SauceBlock.t()) :: term()
  def encode_field(field_id, sauce_block) when is_atom(field_id) do
    do_encode(field_id, sauce_block)
  end

  @doc """
  Encodes a given SAUCE block as a SAUCE record binary.
  """
  @spec encode_record(SauceBlock.t()) :: {:ok, binary()}
  def encode_record(sauce_block) when is_map(sauce_block) do
    #TODO: validate and return an {:error, reason} on failure

    # We could do all this with metadata and pure macros to be "neat." Let us not be neat, but explicit.
    encoded_version = do_encode(:version, sauce_block)
    encoded_title = do_encode(:title, sauce_block)
    encoded_author = do_encode(:author, sauce_block)
    encoded_group = do_encode(:group, sauce_block)
    encoded_date = do_encode(:date, sauce_block)
    encoded_file_size = do_encode(:file_size, sauce_block)
    encoded_data_type = do_encode(:data_type, sauce_block)
    encoded_file_type = do_encode(:file_type, sauce_block)
    encoded_t_info_1 = do_encode(:t_info_1, sauce_block)
    encoded_t_info_2 = do_encode(:t_info_2, sauce_block)
    encoded_t_info_3 = do_encode(:t_info_3, sauce_block)
    encoded_t_info_4 = do_encode(:t_info_4, sauce_block)
    encoded_comment_lines = do_encode(:comment_lines, sauce_block)
    encoded_t_flags = do_encode(:t_flags, sauce_block)
    encoded_t_info_s = do_encode(:t_info_s, sauce_block)

    sauce_bin =
      <<Sauce.sauce_id(),
      encoded_version::binary-size(Sauce.field_size(:version)),
      encoded_title::binary-size(Sauce.field_size(:title)),
      encoded_author::binary-size(Sauce.field_size(:author)),
      encoded_group::binary-size(Sauce.field_size(:group)),
      encoded_date::binary-size(Sauce.field_size(:date)),
      encoded_file_size::binary-size(Sauce.field_size(:file_size)),
      encoded_data_type::binary-size(Sauce.field_size(:data_type)),
      encoded_file_type::binary-size(Sauce.field_size(:file_type)),
      encoded_t_info_1::binary-size(Sauce.field_size(:t_info_1)),
      encoded_t_info_2::binary-size(Sauce.field_size(:t_info_2)),
      encoded_t_info_3::binary-size(Sauce.field_size(:t_info_3)),
      encoded_t_info_4::binary-size(Sauce.field_size(:t_info_4)),
      encoded_comment_lines::binary-size(Sauce.field_size(:comment_lines)),
      encoded_t_flags::binary-size(Sauce.field_size(:t_flags)),
      encoded_t_info_s::binary-size(Sauce.field_size(:t_info_s)),
    >>

    {:ok, sauce_bin}
  end

  def encode_record(_sauce_block) do
    {:error, "The SAUCE info provided is invalid."}
  end

  @doc """
  Encodes a single comment block line. If the size of the line is longer than allowed, it will be truncated.
  """
  @spec encode_comment_block_line(String.t()) :: binary()
  def encode_comment_block_line(comment) when is_binary(comment) do
    encode_string(comment, Sauce.comment_line_byte_size())
  end

  def encode_comment_block_line(_comment) do
    encode_string(<<>>, Sauce.comment_line_byte_size())
  end

  @doc """
  Encodes an entire comment block. If the size of any line is longer than allowed, it will be truncated.
  """
  @spec encode_comments(SauceBlock.t()) :: {:ok, binary()} | {:error, term()}
  def encode_comments(sauce_block)
  def encode_comments(%{comments: comments = [_ | _]}) do
    comments_block_bin = encode_comments_block(<<Sauce.comment_id()>>, comments)
    {:ok, comments_block_bin}
  end

  def encode_comments(sauce_block) when is_map(sauce_block) do
    {:ok, <<>>}
  end

  def encode_comments(_sauce_block) do
    {:error, "The SAUCE info provided is invalid."}
  end

  defp encode_comments_block(comments_bin, []) do
    comments_bin
  end

  defp encode_comments_block(comments_bin, [comment | rest]) do
    encoded_comment = encode_comment_block_line(comment)
    encode_comments_block(<<comments_bin::binary, encoded_comment::binary-size(Sauce.comment_line_byte_size())>>, rest)
  end

  # well I'm sure you're thinking - hey, this all looks like something you can do 100% with macros. I bet YOU can, but I also like things that work and don't force me to rewrite everything for 1 edge case.
  # fortunately, there's a small enough amount of fields that's it's not too painful to write all these, and the chances of a field being added are exactly zero.
  # we'll keep these as pattern matched methods in case there's a simpler way or we want to do things functionally, ex: using Enum functions
  defp do_encode(:version, %{version: version}) do
    encode_version(version)
  end

  defp do_encode(:title, %{title: title}) do
    encode_string(title, Sauce.field_size(:title))
  end

  defp do_encode(:author, %{author: author}) do
    encode_string(author, Sauce.field_size(:author))
  end

  defp do_encode(:group, %{group: group}) do
    encode_string(group, Sauce.field_size(:group))
  end

  defp do_encode(:date, %{date: date}) do
    encode_date(date)
  end

  defp do_encode(:file_size, %{media_info: %{file_size: file_size}})
       when is_integer(file_size) and file_size <= Sauce.file_size_limit() do
    encode_integer(file_size, Sauce.field_size(:file_size))
  end

  defp do_encode(:file_size, %{media_info: %{file_size: file_size}}) when is_integer(file_size) do
    # If the file size limit is exceeded, we force to zero according to the SAUCE spec
    0
  end

  defp do_encode(:data_type, %{media_info: %{file_type: file_type, data_type: data_type}}) do
    # we convert back to media_type_id here to be sure the combo of file_type and data_type is even something valid, otherwise we push it to :none
    # hopefully we catch this by doing validation, however if any caller directly accesses the encoder, we cannot guarantee it since a struct can be modified like a map a number of ways
    MediaInfo.media_type_id(file_type, data_type)
    |> MediaInfo.data_type()
    |> encode_integer(Sauce.field_size(:data_type))
  end

  defp do_encode(:file_type, %{media_info: %{file_type: file_type, data_type: data_type}}) do
    # we convert back to media_type_id here to be sure the combo of file_type and data_type is even something valid, otherwise we push it to :none
    # hopefully we catch this by doing validation, however if any caller directly accesses the encoder, we cannot guarantee it since a struct can be modified like a map a number of ways
    MediaInfo.media_type_id(file_type, data_type)
    |> MediaInfo.file_type()
    |> encode_integer(Sauce.field_size(:file_type))
  end

  defp do_encode(:t_info_1, %{media_info: %{t_info_1: t_info_1}}) do
    encode_integer(t_info_1, Sauce.field_size(:t_info_1))
  end

  defp do_encode(:t_info_2, %{media_info: %{t_info_2: t_info_2}}) do
    encode_integer(t_info_2, Sauce.field_size(:t_info_2))
  end

  defp do_encode(:t_info_3, %{media_info: %{t_info_3: t_info_3}}) do
    encode_integer(t_info_3, Sauce.field_size(:t_info_3))
  end

  defp do_encode(:t_info_4, %{media_info: %{t_info_4: t_info_4}}) do
    encode_integer(t_info_4, Sauce.field_size(:t_info_4))
  end

  defp do_encode(:comment_lines, %{comments: _comments} = sauce_block) do
    SauceBlock.comment_lines(sauce_block) |> encode_integer(Sauce.field_size(:comment_lines))
  end

  defp do_encode(:t_flags, %{media_info: %{t_flags: t_flags}}) do
    encode_integer(t_flags, Sauce.field_size(:t_flags))
  end

  defp do_encode(:t_info_s, %{media_info: %{t_info_s: t_info_s}}) do
    encode_cstring(t_info_s, Sauce.field_size(:t_info_s))
  end

  # Here we generate some fallbacks for non-required fields. According to the SAUCE standard, the default for any non-required fields seems to be zero.
  for %{field_id: field_id, field_size: field_size, required?: false} <- Sauce.field_list() do
    defp do_encode(unquote(field_id), _sauce) do
      encode_integer(0, unquote(field_size))
    end
  end

end