defmodule Saucexages.Codec.SauceFieldDecoder do
  @moduledoc """
  Functions for decoding commonly used SAUCE field data types.
  """

  require Codepagex
  require Saucexages.Sauce
  require Saucexages.Codec.Encodings
  require Saucexages.DataType
  require Saucexages.MediaInfo
  alias Saucexages.{Sauce, DataType, MediaInfo}
  alias Saucexages.Codec.Encodings

  # Here we can add more encodings if we wish in case some other strange encodings are observed in the wild. So far, only utf-8 which doesn't require codepagex, however latin-1 and ascii variants are highly probable.
  @sauce_encodings [Encodings.encoding(:cp437)]

  @doc """
  Decodes a SAUCE string, removing any padding. A default value may be optionally specified to use for cases when decoding is impossible. Custom encodings can also be passed to attempt to decode using something other than the SAUCE standard CP437 and a fallback of utf-8.
  """
  @spec decode_string(binary(), String.t() | nil, [String.t()]) :: String.t() | nil
  def decode_string(bin, default_value \\ nil, encodings \\ @sauce_encodings)
  def decode_string(bin, default_value, encodings)
      when is_binary(bin) and byte_size(bin) > 0 do
    # A "string" should never have zeroes, rather padding, however in practice this is not always true.
    # From the sauce spec:

    # "I have seen SAUCE where Character fields were terminated with a binary 0 with the remainder containing garbage.
    # When making a SAUCE reader, it is a good idea to properly handle this case.
    # When writing SAUCE, stick with space padding"

    with [sanitized_string | _] <- :binary.split(bin, [<<0>>], [:trim, :global]),
         {:ok, converted_string, _} <- convert_string(sanitized_string, encodings) do
        converted_string
    else
      _ ->
        default_value
    end
  end

  def decode_string(_bin, default_value, _encodings) do
    default_value
  end

  @doc """
  Decodes a SAUCE C-style string, removing any padding. A default value may be optionally specified to use for cases when decoding is impossible. Custom encodings can also be passed to attempt to decode using something other than the SAUCE standard CP437 and a fallback of utf-8.
  """
  @spec decode_cstring(binary(), String.t() | nil, [String.t()]) :: String.t()
  def decode_cstring(bin, default_value \\ nil, encodings \\ @sauce_encodings)
  def decode_cstring(bin, default_value, encodings)
      when is_binary(bin) and byte_size(bin) > 0 do
    # for now we treat these the same, but these are split because their behavior is different, but coincidentally have the same code due to garbage found in files (see SAUCE spec notes)
    decode_string(bin, default_value, encodings)
  end

  def decode_cstring(_string, default_value, _encodings) do
    default_value
  end

  @doc """
  Converts a SAUCE string, optionally using the specified encodings.
  """
  @spec convert_string(binary(), [String.t() | atom()]) :: {:ok, String.t(), atom() | String.t()} | {:error, term()}
  def convert_string(bin, encodings \\ @sauce_encodings)
  def convert_string(bin, []) when is_binary(bin) do
    # Randomly, have found stupid people who have encoded utf-8 instead of cp437.
    if String.valid?(bin) do
      {:ok, bin, Encodings.encoding(:utf8)}
    else
      {:error, "No valid string conversions found."}
    end
  end

  def convert_string(bin, [encoding | rest]) when is_binary(bin) do
    case Codepagex.to_string(bin, encoding) do
      {:ok, converted_string} ->
        {:ok, converted_string |> String.trim_trailing(), encoding}
      _ ->
        convert_string(bin, rest)
    end
  end

  @doc """
  Decodes a SAUCE file type, using the SAUCE spec file type specification rules. If a file type is invalid, it will be coerced to 0.
  """
  @spec decode_file_type(non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  def decode_file_type(file_type, data_type) do
    # only accept the file type if it is actually valid
    MediaInfo.media_type_id(file_type, data_type) |> MediaInfo.file_type()
  end

  @doc """
  Decodes a SAUCE data type, using the SAUCE spec data type specification rules. If a data type is invalid, it will be coerced to 0.
  """
  @spec decode_data_type(non_neg_integer()) :: non_neg_integer()
  def decode_data_type(data_type) do
    # only accept the data type if it is actually valid
    DataType.data_type_id(data_type) |> DataType.data_type()
  end

  @doc """
  Decodes a SAUCE date binary to an Elixir `DateTime` if possible.
  """
  @spec decode_date(binary()) :: DateTime.t() | nil
  def decode_date(date_binary)
  def decode_date(<<year::binary-size(4), month::binary-size(2), day::binary-size(2)>>) do
    decode_date(year, month, day)
  end

  def decode_date(_date) do
    nil
  end

  @doc """
  Decodes SAUCE date-time components taken from a SAUCE record and converts them to an Elixir `DateTime` if possible.
  """
  @spec decode_date(binary(), binary(), binary()) :: DateTime.t() | nil
  def decode_date(year, month, day)
      when is_binary(year) and is_binary(month) and is_binary(day) do
    with {numeric_year, ""} <- Integer.parse(year),
         {numeric_month, ""} <- Integer.parse(month),
         {numeric_day, ""} <- Integer.parse(day),
         {:ok, date} <- Date.new(numeric_year, numeric_month, numeric_day) do
      date
    else
      _ -> nil
    end
  end

  def decode_date(_year, _month, _day) do
    nil
  end

  @doc """
  Decodes SAUCE record comment lines.
  """
  @spec decode_comment_lines(non_neg_integer() | binary()) :: non_neg_integer()
  def decode_comment_lines(comment_lines)
  def decode_comment_lines(comment_lines) when is_binary(comment_lines) do
    :binary.decode_unsigned(comment_lines, :little) |> do_decode_comment_lines()
  end

  def decode_comment_lines(comment_lines) do
    comment_lines |> do_decode_comment_lines()
  end

  defp do_decode_comment_lines(comment_lines) when Sauce.is_comment_lines(comment_lines) do
    comment_lines
  end

  defp do_decode_comment_lines(_comment_lines) do
    # if there is garbage here, we force to zero
    0
  end

  @doc """
  Decodes SAUCE comment block comment lines with an optional separator.
  """
  @spec decode_comment_block_lines_with([binary()], String.t()) :: String.t()
  def decode_comment_block_lines_with(comment_lines, separator \\ "\n") when is_list(comment_lines) do
    decode_comment_block_lines(comment_lines) |> Enum.join(separator)
  end

  @doc """
  Decodes a SAUCE comment block comment line.
  """
  @spec decode_comment_block_line(binary()) :: String.t() | nil
  def decode_comment_block_line(comment_line) when is_binary(comment_line) do
    decode_string(comment_line, nil)
  end

  @doc """
  Decodes SAUCE comment block comment lines as a list of strings.
  """
  @spec decode_comment_block_lines([binary()]) :: [String.t() | nil]
  def decode_comment_block_lines(comment_lines) when is_list(comment_lines) do
    Enum.map(comment_lines, &decode_comment_block_line/1)
  end

end


defmodule Saucexages.Codec.Decoder do
  @moduledoc """
  Functions for decoding SAUCE records and SAUCE comment blocks.
  """

  require Saucexages.Sauce
  require Saucexages.SauceRecord
  alias Saucexages.{Sauce, SauceBlock, SauceRecord}
  alias Saucexages.Codec.SauceFieldDecoder

  @doc """
  Decodes a SAUCE record binary.
  """
  @spec decode_record(binary()) :: {:ok, SauceRecord.t()} | {:error, :no_sauce} | {:error, term()}
  def decode_record(<<Sauce.sauce_id(), sauce_data::binary-size(Sauce.sauce_data_byte_size())>> = sauce_record)
      when is_binary(sauce_record) do
    <<version::binary-size(Sauce.field_size(:version)),
      title::binary-size(Sauce.field_size(:title)),
      author::binary-size(Sauce.field_size(:author)),
      group::binary-size(Sauce.field_size(:group)),
      date::binary-size(Sauce.field_size(:date)),
      file_size::little-unsigned-integer-unit(8)-size(Sauce.field_size(:file_size)),
      data_type::little-unsigned-integer-unit(8)-size(Sauce.field_size(:data_type)),
      file_type::little-unsigned-integer-unit(8)-size(Sauce.field_size(:file_type)),
      t_info_1::little-unsigned-integer-unit(8)-size(Sauce.field_size(:t_info_1)),
      t_info_2::little-unsigned-integer-unit(8)-size(Sauce.field_size(:t_info_2)),
      t_info_3::little-unsigned-integer-unit(8)-size(Sauce.field_size(:t_info_3)),
      t_info_4::little-unsigned-integer-unit(8)-size(Sauce.field_size(:t_info_4)),
      comment_lines::little-unsigned-integer-unit(8)-size(Sauce.field_size(:comment_lines)),
      t_flags::little-unsigned-integer-unit(8)-size(Sauce.field_size(:t_flags)),
      t_info_s::binary-size(Sauce.field_size(:t_info_s))
    >> = sauce_data

    data_type = SauceFieldDecoder.decode_data_type(data_type)

    # version is really the only field that can perhaps do weird stuff as the other required fields (file_type, data_type) will floor to zero anyway due to integer wrap
    # the only improvement could be perhaps an integrity check on file_type + data_type, however doing so creates an intolerant reader and may break anyone who has extended SAUCE in some unsupported but still valid way.
    with decoded_version when is_binary(decoded_version) <- version |> SauceFieldDecoder.decode_string() do
      sauce_record = %SauceRecord{
        version: decoded_version,
        title: title |> SauceFieldDecoder.decode_string(),
        author: author |> SauceFieldDecoder.decode_string(),
        group: group |> SauceFieldDecoder.decode_string(),
        date: date |> SauceFieldDecoder.decode_date(),
        file_size: file_size,
        file_type: file_type |> SauceFieldDecoder.decode_file_type(data_type),
        data_type: data_type,
        t_info_1: t_info_1,
        t_info_2: t_info_2,
        t_info_3: t_info_3,
        t_info_4: t_info_4,
        comment_lines: comment_lines |> SauceFieldDecoder.decode_comment_lines(),
        t_flags: t_flags,
        t_info_s: t_info_s |> SauceFieldDecoder.decode_cstring()
      }
      {:ok, sauce_record}
    else
      _ ->
        {:error, :invalid_sauce}
    end
  end

  def decode_record(sauce_bin) when is_binary(sauce_bin) do
    {:error, :no_sauce}
  end

  def decode_record(_sauce_bin) do
    {:error, :invalid_sauce}
  end

  @doc """
  Decodes a full SAUCE block from a given SAUCE record and list of SAUCE comments.
  """
  @spec decode_sauce(SauceRecord.t(), [String.t()]) :: {:ok, SauceBlock.t()} | {:error, term()}
  def decode_sauce(sauce_record, sauce_comments) when is_map(sauce_record) and is_list(sauce_comments) do
    {:ok, SauceBlock.from_sauce_record(sauce_record, sauce_comments)}
  end

  def decode_sauce(sauce_record, sauce_comments) when is_map(sauce_record) and is_nil(sauce_comments) do
    {:ok, SauceBlock.from_sauce_record(sauce_record, [])}
  end

  def decode_sauce(_sauce_record, _sauce_comments) do
    {:error, "Invalid SAUCE data."}
  end

  @doc """
  Decodes a SAUCE comments block given an expected number of comment lines according to a SAUCE record, and returns a list of comments.
  """
  @spec decode_comments(binary(), integer()) :: {:ok, [String.t()]} | {:error, :no_comments} | {:error, term()}
  def decode_comments(<<Sauce.comment_id(), comment_bin::binary>>, comment_lines) when comment_lines > 0 do
    comments =  extract_comments(comment_bin, comment_lines, [])
    {:ok, comments}
  end

  def decode_comments(_comment_bin, 0) do
    {:ok, []}
  end

  #optimization in match
  def decode_comments(<<comment_bin::binary>>, _comment_lines) when is_binary(comment_bin) do
    # No comments found
    {:error, :no_comments}
  end

  def decode_comments(_comment_block, _comment_lines) do
    {:error, "Invalid comment block."}
  end

  defp extract_comments(<<line_comment::binary-size(Sauce.comment_line_byte_size()), rest::binary>>, comment_lines, comments) when comment_lines > 0 do
    remaining_lines = comment_lines - 1
    case SauceFieldDecoder.decode_comment_block_line(line_comment) do
      nil -> extract_comments(rest, remaining_lines, comments)
      converted_comment -> extract_comments(rest, remaining_lines, [converted_comment | comments])
    end
  end

  defp extract_comments(_comment_block, _comment_lines, comments) do
    Enum.reverse(comments)
  end

end
