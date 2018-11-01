defmodule Saucexages.IO.SauceBinary do
  @moduledoc """
  Functions for working with SAUCE containing and related binaries.

  Provides basic building blocks for reading, writing, fixing, and analyzing binaries that may or may not contain SAUCE blocks.

  ## Notes

  Because of the way SAUCE works with regard to EOF position + bugs in practice with EOF characters, it may be highly inefficient to use some of these functions with large binaries. As such, several versions of similar functions (ex: split_all vs. split_sauce) exist to allow you to work only with the parts of a binary you need. If you still have issues with large files, prefer to work with the `SauceFile` and `FileReader` modules instead.
  """

  require Saucexages.Sauce
  alias Saucexages.{Sauce}

  @type contents_binary :: binary()
  @type sauce_block_binary :: binary()
  @type sauce_binary() :: binary()
  @type comments_binary() :: binary()

  defguard is_comment_lines(bin) when rem(byte_size(bin), Sauce.comment_line_byte_size()) == 0

  #TODO: Cleanup some of these functions that have overlapping handling. It's explicit now which is fine, but there's a lot of boiler plate that exists for binary efficiency that can be deleted with some work.

  @doc """
  Splits a binary into its component parts with respect to SAUCE.

  A 3-tuple is returned in the form `{contents_bin, sauce_bin, comments_bin}` that consists of the file contents, SAUCE record, if any, and comments, if any.

  """
  @spec split_all(binary()) :: {contents_binary(), sauce_binary(), comments_binary()}
  def split_all(bin) when is_binary(bin) do
    case sauce_handle(bin) do
    {:ok, {sauce_record_bin, comment_lines}} ->
      case extract_comments(bin, comment_lines) do
        {:ok, comments_bin} ->
          contents_offset = byte_size(bin) - Sauce.sauce_byte_size(comment_lines)
          <<contents_bin::binary-size(contents_offset), _::binary>> = bin
          {contents_bin, sauce_record_bin, comments_bin}
        _ ->
          contents_offset = byte_size(bin) - Sauce.sauce_record_byte_size()
          <<contents_bin::binary-size(contents_offset), _::binary-size(Sauce.sauce_record_byte_size())>> = bin
          {contents_bin, sauce_record_bin, <<>>}
      end
      _ -> {bin, <<>>, <<>>}
    end
  end

  @doc """
  Splits a binary, trimming the file contents and returning the SAUCE and SAUCE comment block if each exists as a 2-tuple in the form of `{sauce_record, comment_block}`.

  Any element of the tuple that does not exist will be returned as an empty binary.
  """
  @spec split_sauce(binary()) :: {sauce_binary(), comments_binary()}
  def split_sauce(bin) when is_binary(bin) do
    with {:ok, {sauce_bin, comments_bin}} <- sauce(bin) do
      {sauce_bin, comments_bin}
    else
      _ -> {<<>>, <<>>}
    end
  end

  @doc """
  Splits a binary into its components by SAUCE record.

   Returns a 2-tuple where the first element is the remaining file binary, if any, and the second element is the SAUCE record binary, if any.

   Note: The first element may or may not contain SAUCE comments. If you wish to extract all possible components of a file that may have a SAUCE, use `split_all/1` instead. If you wish to obtain the file contents only use `contents/1` instead.
  """
  @spec split_record(binary()) :: {contents_binary(), sauce_binary()}
  def split_record(bin) when is_binary(bin) do
    with bin_size when bin_size >= Sauce.sauce_record_byte_size() <- byte_size(bin),
         sauce_offset = bin_size - Sauce.sauce_record_byte_size(),
         <<contents_bin::binary-size(sauce_offset), sauce_bin::binary-size(Sauce.sauce_record_byte_size())>> = bin,
         true <- matches_sauce?(sauce_bin) do
      {contents_bin, sauce_bin}
    else
      _ -> {bin, <<>>}
    end
  end

  @doc """
  Splits a binary according to a specified number of `comment_lines` and returns a 3-tuple, where the first element is the file binary, if any, the second element is the SAUCE binary, if any, and the third element is the comments binary, if any.

  If the `comment_lines` do not match a valid comment block, no comments will be returned.
  """
  @spec split_with(binary(), non_neg_integer()) :: {contents_binary(), sauce_binary(), comments_binary()}
  def split_with(bin, comment_lines) when is_binary(bin) and is_integer(comment_lines) do
    bin_size = byte_size(bin)
    with true <- comment_lines > 0,
         block_size = Sauce.sauce_byte_size(comment_lines),
         true <- bin_size >= block_size,
         comment_size = Sauce.comment_block_byte_size(comment_lines),
         sauce_offset = bin_size - block_size,
         <<contents_bin::binary-size(sauce_offset),
           comments_bin::binary-size(comment_size),
           sauce_bin::binary-size(Sauce.sauce_record_byte_size())>> = bin,
         true <- matches_sauce?(sauce_bin),
         true <- matches_comment_block?(comments_bin) do
      {contents_bin, sauce_bin, comments_bin}
    else
      _ ->
        {contents_bin, sauce_bin} = split_record(bin)
        {contents_bin, sauce_bin, <<>>}
    end
  end

  @doc """
  Returns the contents before any SAUCE and other EOF data.

  May truncate any other data that might co-exist with a SAUCE block.
  """
  @spec clean_contents(binary()) :: binary()
  def clean_contents(bin) when is_binary(bin) do
    [contents_bin | _] = :binary.split(bin, <<Sauce.eof_character()>>)
    contents_bin
  end

  @doc """
  Returns the contents before any SAUCE block.

  An optional `terminate?` flag may be passed which will append an EOF character to the end of the contents if one does not already exist. This is useful in cases such as writing a new SAUCE record where you want to avoid appending extra EOF characters or ensure one is present to ensure SAUCE can be read properly after write. By default, contents is returned *as is*, and therefore you must opt-in to termination.
  """
  @spec contents(binary(), boolean()) :: {:ok, contents_binary()} | {:error, term()}
  def contents(bin, terminate? \\ false)
  def contents(bin, false) when is_binary(bin) do
    extract_contents(bin)
  end

  def contents(bin, true) when is_binary(bin) do
    {:ok, contents} = extract_contents(bin)
    terminated_bin = eof_terminate(contents)
    {:ok, terminated_bin}
  end

  @doc """
  Returns the byte size of the contents in the binary, before any potential SAUCE block.
  """
  @spec contents_size(binary()) :: non_neg_integer()
  def contents_size(bin) do
    {:ok, contents_bin} = contents(bin, false)
    byte_size(contents_bin)
  end

  @doc """
  Returns SAUCE record binary if the provided binary *is* a SAUCE record, otherwise an empty binary.
  """
  @spec maybe_sauce_record(sauce_binary()) :: sauce_binary() | <<>>
  def maybe_sauce_record(<<Sauce.sauce_id(), _sauce_data::binary-size(Sauce.sauce_data_byte_size())>> = sauce_bin) do
    sauce_bin
  end

  def maybe_sauce_record(_sauce_bin) do
    <<>>
  end

  @doc """
  Returns SAUCE comment block if the provided binary *is* a SAUCE comment block, otherwise an empty binary.
  """
  @spec maybe_comments(comments_binary()) :: comments_binary | <<>>
  def maybe_comments(<<Sauce.comment_id(), _first_comment_line::binary-size(Sauce.comment_line_byte_size()), rest::binary>> = comments_bin) do
    # The optimizer forces us to check this here instead of via guard
    if comment_lines?(rest) do
      comments_bin
    else
        <<>>
    end
  end

  def maybe_comments(_comments_bin) do
    <<>>
  end

  @doc """
  Checks if a binary *is* a SAUCE record.

  Note: This does not validate a SAUCE record, nor does it scan an entire binary for the presence of a SAUCE record. Instead, it merely matches if the entire binary *is* a SAUCE record, rather than *has* a SAUCE record.

  If you wish to check if a binary *has* a SAUCE record, instead use `sauce?/1`
  """
  @spec matches_sauce?(sauce_binary()) :: boolean()
  def matches_sauce?(sauce_bin)
  # we may want to tighten this up slightly to check for ascii, but validating is really part of decoding, which is at a higher level than this
  def matches_sauce?(<<Sauce.sauce_id(), 0, 0, _sauce_data::binary-size(121)>>) do
    false
  end
  def matches_sauce?(<<Sauce.sauce_id(), _sauce_data::binary-size(Sauce.sauce_data_byte_size())>>) do
    true
  end

  def matches_sauce?(_sauce_bin) do
    false
  end

  @doc """
  Checks if a binary *is* a SAUCE comment block.

  Note: This does not validate a comment block, nor does it scan an entire binary for the presence of a comment block. Instead, it merely matches if the entire binary *is* a comment block, rather than *has* a comment block.

  If you wish to check if a binary *has* a comment block, instead use `comments?/1`
  """
  @spec matches_comment_block?(comments_binary()) :: boolean()
  def matches_comment_block?(<<Sauce.comment_id(), _first_comment_lines::binary-size(Sauce.comment_line_byte_size()), rest::binary>>) do
    comment_lines?(rest)
  end

  def matches_comment_block?(_comments_bin) do
    false
  end

  @doc """
  Checks if a binary *is* a SAUCE record, returning `:ok` if true, and `{:error, :no_sauce}` if false.
  """
  @spec verify_sauce_record(sauce_binary()) :: :ok | {:error, :no_sauce}
  def verify_sauce_record(<<Sauce.sauce_id(), _sauce_data::binary-size(Sauce.sauce_data_byte_size())>>) do
    :ok
  end

  def verify_sauce_record(_sauce_bin) do
    {:error, :no_sauce}
  end

  @doc """
  Checks to see if a binary *is* a SAUCE comment block.
  """
  @spec verify_comment_block(comments_binary()) :: :ok | {:error, :no_sauce}
  def verify_comment_block(<<Sauce.comment_id(), first_comment_lines::binary-size(Sauce.comment_line_byte_size()), _rest::binary>>) do
    # optimizer forces us to do this here instead of via guard
    if comment_lines?(first_comment_lines) do
      :ok
    else
      {:error, :no_comments}
    end
  end

  def verify_comment_block(_comments_bin) do
    {:error, :no_comments}
  end

  @doc """
  Reads a given `field_id` from a binary SAUCE record or binary containing a SAUCE, and returns the undecoded result as binary.

  If the binary does not have a SAUCE record, `:no_sauce` is returned.

  Returns `{:ok, value}` if the value exists where the value will be raw binary. Returns `{:error, reason}` if there is a problem reading the field. If the binary has no SAUCE record to read, `{:error, :no_sauce}` is returned.
  """
  @spec read_field(sauce_binary(), Sauce.field_id()) :: {:ok, binary()} | {:error, :no_sauce} | {:error, term()}
  def read_field(bin, field_id)
  def read_field(<<Sauce.sauce_id(), _rest::binary-size(Sauce.sauce_data_byte_size())>> = sauce_bin, field_id) when is_atom(field_id) do
    case do_read_field(sauce_bin, field_id) do
      :no_sauce -> {:error, :no_sauce}
      value -> {:ok, value}
    end
  end

  def read_field(bin, field_id) when is_binary(bin) and is_atom(field_id) do
    with {:ok, sauce_bin} <- sauce_record(bin),
        value when is_binary(value) <- do_read_field(sauce_bin, field_id) do
      {:ok, value}
    else
      :no_sauce -> {:error, :no_sauce}
      {:error, _reason} = err -> err
      _ -> {:error, "Unable to read SAUCE field #{inspect field_id}"}
    end
  end

  defp do_read_field(sauce_bin, field_id)
  for %{field_id: field_id, field_size: field_size, position: position} <- Sauce.field_list() do
    defp do_read_field(sauce_bin, unquote(field_id)) do
      case sauce_bin do
        <<_::binary-size(unquote(position)), value::binary-size(unquote(field_size)), _::binary>> ->
          value
        _ ->
          :no_sauce
      end
    end
  end

  @doc """
  Reads a given `field_id` from a binary SAUCE record and returns the undecoded result as binary.

  Throws if the given binary is not or does not contain a SAUCE record.
  """
  @spec read_field!(sauce_binary(), Sauce.field_id()) :: binary() | :no_sauce
  def read_field!(bin, field_id)
  def read_field!(<<Sauce.sauce_id(), _rest::binary-size(Sauce.sauce_data_byte_size())>> = sauce_bin, field_id) when is_atom(field_id) do
    do_read_field(sauce_bin, field_id)
  end

  def read_field!(bin, field_id) when is_binary(bin) and is_atom(field_id) do
    with {:ok, sauce_bin} <- sauce_record(bin) do
      read_field!(sauce_bin, field_id)
    else
      _ -> raise ArgumentError, "You must supply a valid sauce record binary and field id."
    end
  end

  def read_field!(_sauce_bin, _field_id) do
    raise ArgumentError, "You must supply a valid sauce record binary and field id."
  end

  @doc """
  Writes a given `field_id` and a given encoded binary `value` to a binary that already contains a SAUCE record.

  Writing using this method should be considered "unsafe" unless the values are validated and encoded in advance.

  The `field_id` must be a valid SAUCE field and the value must be binary of the valid corresponding size according to the SAUCE spec.

  Can be used for building in-place updates of a SAUCE along with a proper field encoder.
  """
  @spec write_field(binary(), Sauce.field_id(), binary()) :: {:ok, sauce_binary()} | {:error, :no_sauce} | {:error, term()}
  def write_field(bin, field_id, value) when is_binary(bin) and is_atom(field_id) and is_binary(value) do
    case sauce_record(bin) do
      {:ok, sauce_bin} ->
        {:ok, do_write_field(sauce_bin, field_id, value)}
      {:error, _reason} = err -> err
    end
  end

  # It's possible for us to do a guard on byte_size here per field id using Sauce.field_size(field_id), but the pattern match pretty much takes care of it anyway. It's just a question if we want a cleaner exception or not, but this call is more of a nice to have for now.
  defp do_write_field(sauce_bin, field_id, value)
  for %{field_id: field_id, field_size: field_size, position: position} <- Sauce.field_list() do
    rest_size = Sauce.sauce_record_byte_size() - (field_size + position)
    defp do_write_field(<<start::binary-size(unquote(position)), _old_value::binary-size(unquote(field_size)), rest::binary-size(unquote(rest_size))>>, unquote(field_id), value) do
      <<start::binary-size(unquote(position)), value::binary-size(unquote(field_size)), rest::binary-size(unquote(rest_size))>>
    end
  end

  @doc """
  Extracts the SAUCE record from a binary and the number of comment lines present.

  The returned comment lines can be used to properly fetch the comments block later from the same binary such as via `split_with/1`.
  """
  @spec sauce_handle(binary()) :: {:ok, {sauce_binary(), non_neg_integer()}} | {:error, :no_sauce} | {:error, term()}
  def sauce_handle(bin) when is_binary(bin) do
    with {:ok, sauce_record_bin} <- extract_sauce_record(bin),
         {:ok, comment_lines} <- read_sauce_comment_lines(sauce_record_bin) do
      {:ok, {sauce_record_bin, comment_lines}}
    else
      {:error, _reason} = err -> err
    end
  end

  @doc """
  Extracts the SAUCE record and comment block from a binary, and returns `{:ok, {sauce_bin, comments_bin}`.

  If no SAUCE is found, `{:error, :no_sauce}` will be returned.
  """
  @spec sauce(binary()) :: {:ok, {sauce_binary(), comments_binary()}} | {:error, :no_sauce} | {:error, term()}
  def sauce(bin) when is_binary(bin) do
    with {:ok, {sauce_record_bin, comment_lines}} <- sauce_handle(bin),
         {:ok, comments_bin} <- maybe_extract_comments(bin, comment_lines) do
      {:ok, {sauce_record_bin, comments_bin}}
    else
      {:error, _reason} = err -> err
      _ -> {:error, "Unable to get SAUCE from binary."}
    end
  end

  @doc """
  Extracts the SAUCE block as a single binary as it appears within a SAUCE binary - a comments block (if any) followed by a SAUCE record.

  If no SAUCE is found, `{:error, :no_sauce}` will be returned.
  """
  @spec sauce_block(binary()) :: {:ok, sauce_block_binary()} | {:error, :no_sauce} | {:error, term()}
  def sauce_block(bin) when is_binary(bin) do
    case sauce(bin) do
      {:ok, {sauce_record_bin, comments_bin}} ->
        {:ok, <<comments_bin::binary, sauce_record_bin::binary-size(Sauce.sauce_record_byte_size())>>}
      err ->
        err
    end
  end

  @doc """
  Extracts the SAUCE record from a binary and returns `{:ok, sauce_bin}`.

  If the SAUCE record cannot be found, {:error, `:no_sauce`} is returned.
  """
  @spec sauce_record(binary()) :: {:ok, sauce_binary()} | {:error, :no_sauce} | {:error, term()}
  def sauce_record(bin) when is_binary(bin) do
    extract_sauce_record(bin)
  end

  @doc """
  Extracts the SAUCE record from a binary.

  If the SAUCE record cannot be found, an empty binary is returned.
  """
  @spec sauce_record!(binary()) :: sauce_binary()
  def sauce_record!(bin) when is_binary(bin) do
    case extract_sauce_record(bin) do
      {:ok, sauce_bin} -> sauce_bin
      _ -> <<>>
    end
  end

  @doc """
  Checks if a binary has a SAUCE record.
  """
  @spec sauce?(binary()) :: boolean()
  def sauce?(bin) when is_binary(bin) do
    case sauce(bin) do
      {:ok, _} -> true
      _ -> false
    end
    #this method avoids the sub-binary but is somewhat inconsistent with how we do things elsewhere
#    with bin_size when bin_size >= Sauce.sauce_record_byte_size <- byte_size(bin),
#         {_, _} <- do_match_sauce(bin, false, [{:scope, {bin_size, -Sauce.sauce_record_byte_size()}}]) do
#      true
#    else
#      _ -> false
#    end
  end

  def sauce?(_bin) do
    false
  end

  @doc """
  Extracts the SAUCE comment block from a binary and returns the comment block binary with the comment line count as `{:ok, {comments_bin, line_count}}`.

  The line count corresponds to the number of comment lines that have been read based on the `comment_lines` field in the SAUCE record, and may be used for decoding purposes.

  If the SAUCE comment block cannot be found, {:error, `:no_comments`} is returned.
  """
  @spec comments(binary()) :: {:ok, {comments_binary(), non_neg_integer()}} | {:error, :no_sauce} | {:error, :no_comments} | {:error, term()}
  def comments(bin) when is_binary(bin) do
    with {:ok, {_sauce_record_bin, comment_lines}} <- sauce_handle(bin),
         {:ok, comments_bin} <- extract_comments(bin, comment_lines) do
      {:ok, {comments_bin, comment_lines}}
    else
      {:error, :no_sauce} -> {:error, :no_sauce}
      _ -> {:error, :no_comments}
    end
  end

  @doc """
  Checks if a binary has a SAUCE comment block.
  """
  @spec comments?(binary()) :: boolean()
  def comments?(bin) when is_binary(bin) do
    case comments(bin) do
      {:ok, _} -> true
      _ -> false
    end
    # this method uses matching and avoids creating binaries, but is somewhat inconsistent with how we do things elsewhere
#    case match_comment_block(bin) do
#      {_, _} -> true
#      _ -> false
#    end
  end

  def comments?(_bin) do
    false
  end

  @doc """
  Extracts the SAUCE comment block from a binary or returns a comment fragment if the binary is a comment fragment.

  If a SAUCE record exists after the comment block, it will be trimmed. Because there is no other terminator for a comments fragment other than a SAUCE record, it is possible that additional data may be returned that is not part of comments. You should therefore manually parse the data to see if it is actually comment data or otherwise relevant.

  If you want to be sure you have a valid comment block, you should instead use `comments/1` which will check for the presence of a SAUCE record as a terminator. Alternatively, you can safely use this function if you have previously split a binary and know that the SAUCE terminator existed previously, for example after calling `split_sauce/1`.

  Useful for casual introspection of SAUCE files and diagnosing damaged files.
  """
  @spec comments_fragment(binary()) :: {:ok, comments_binary()}
  def comments_fragment(bin) when is_binary(bin) do
    if matches_comment_fragment?(bin) do
      # trim any SAUCE record that might exist after - this trim will always produce a value
      [comments_bin | _] = :binary.split(bin, Sauce.sauce_id())
      {:ok, comments_bin}
    else
      case comments(bin) do
        {:ok, {comments_bin, _lines}} -> {:ok, comments_bin}
        err -> err
      end
    end
  end

  # a more relaxed check for comments
  defp matches_comment_fragment?(<<Sauce.comment_id(), _first_comment_lines::binary-size(Sauce.comment_line_byte_size()), _rest::binary>>) do
    true
  end

  defp matches_comment_fragment?(_bin) do
    false
  end

  @doc """
  Checks if a binary has a SAUCE comments fragment.
  """
  @spec comments_fragment?(binary()) :: boolean()
  def comments_fragment?(bin) when is_binary(bin) do
    case do_match_comments(bin, false, []) do
      {_, _} -> true
      _ -> false
    end
  end

  def comments_fragment?(_bin) do
    false
  end

  @doc """
  Dynamically counts the number of comment lines in a SAUCE binary and return it as `{:ok, line_count}`.

  Note that this number may not match the `comment_line` field found in a SAUCE record. Major reasons for this include:

  * The SAUCE block itself is corrupted.
  * The SAUCE record `comment_lines` field was not updated properly by a SAUCE writer.
  * The SAUCE comment block was not updated properly by a SAUCE writer.

  Useful for finding and fixing damaged SAUCE files.

  Use `comment_lines/1` if you want to read the comment lines stored in the SAUCE record directly.
  """
  @spec count_comment_lines(binary()) :: {:ok, non_neg_integer()} | {:error, :no_sauce} | {:error, :no_comments} | {:error, term()}
  def count_comment_lines(bin) when is_binary(bin) do
    with {:ok, comments_bin} <- comments_fragment(bin),
         block_size = byte_size(comments_bin) - Sauce.comment_id_byte_size(),
         line_count when rem(block_size, Sauce.comment_line_byte_size()) == 0 <- div(block_size, Sauce.comment_line_byte_size()) do
      {:ok, line_count}
    else
      {:error, _reason} = err -> err
      _ -> {:error, "Invalid comment block."}
    end
  end

  def comment_lines?(<<>>) do
    true
  end

  def comment_lines?(<<bin::binary>>) when is_binary(bin) do
    #rem(byte_size(bin), Sauce.comment_line_byte_size()) == 0
    do_comment_lines?(bin)
  end

  defp do_comment_lines?(<<>>) do
    true
  end

  defp do_comment_lines?(<<_line::binary-size(Sauce.comment_line_byte_size()), rest::binary>>) do
    comment_lines?(rest)
  end

  defp do_comment_lines?(_bin) do
    false
  end

  @doc """
  Returns the number of comment lines stored in the SAUCE record as `{:ok, line_count}`.

  This value can serve as a pointer for helping you locate a SAUCE comment block in a binary and can be used for reading the comments a variety of ways, such as via `split_with/1`.

  Note: This value may or may not match the number of lines stored in the comment block. As such, you should exhibit caution when relying on either. See the reasons for this in `count_comment_lines/1`.
  """
  @spec comment_lines(binary()) :: {:ok, non_neg_integer()} | {:error, :no_sauce} | {:error, term()}
  def comment_lines(bin) when is_binary(bin) do
    # first verify it's actually a SAUCE record or grab it so we don't read garbage
    with {:ok, sauce_bin} <- sauce_record(bin) do
      read_sauce_comment_lines(sauce_bin)
    else
      {:error, _reason} = err -> err
      _ -> {:error, "Unable to read comment lines field."}
    end
  end

  @doc """
  Returns a list of comment block line undecoded comment line binaries, if any.
  """
  @spec comment_block_lines(binary()) :: {:ok, [binary()]} | {:error, :no_sauce} | {:error, :no_comments} | {:error, term()}
  def comment_block_lines(bin) when is_binary(bin) do
    with {:ok, comments_bin} <- comments_fragment(bin),
         lines when is_list(lines) <- do_comment_block_lines(comments_bin) do
      {:ok, lines}
    end
  end

  defp do_comment_block_lines(<<Sauce.comment_id(), comment_lines::binary>>) do
    do_comment_block_lines(comment_lines, [])
  end

  defp do_comment_block_lines(_bin) do
    []
  end

  defp do_comment_block_lines(<<comment_line::binary-size(Sauce.comment_line_byte_size()), rest::binary>>, lines) do
    do_comment_block_lines(rest, [comment_line | lines])
  end

  defp do_comment_block_lines(_bin, lines) do
    lines
  end

  @doc """
  Checks if a binary most likely has a valid SAUCE using a relaxed set of constraints that avoid a full decode.

  Useful for deciding whether or not a SAUCE is damaged or worth further actions.
  """
  @spec valid_sauce?(binary()) :: boolean()
  def valid_sauce?(bin) when is_binary(bin) and byte_size(bin) >= Sauce.sauce_record_byte_size() do
    with {:ok, sauce_record_bin} <- sauce_record(bin),
         <<Sauce.sauce_id(),
           version::binary-size(Sauce.field_size(:version)),
           _title::binary-size(Sauce.field_size(:title)),
           _author::binary-size(Sauce.field_size(:author)),
           _group::binary-size(Sauce.field_size(:group)),
           _date::binary-size(Sauce.field_size(:date)),
           _file_size::binary-size(Sauce.field_size(:file_size)),
           data_type::little-unsigned-integer-unit(8)-size(Sauce.field_size(:data_type)),
           file_type::little-unsigned-integer-unit(8)-size(Sauce.field_size(:file_type)),
           _t_info_1::binary-size(Sauce.field_size(:t_info_1)),
           _t_info_2::binary-size(Sauce.field_size(:t_info_2)),
           _t_info_3::binary-size(Sauce.field_size(:t_info_3)),
           _t_info_4::binary-size(Sauce.field_size(:t_info_4)),
           _comment_lines::binary-size(Sauce.field_size(:comment_lines)),
           _t_flags::binary-size(Sauce.field_size(:t_flags)),
           _t_info_s::binary-size(Sauce.field_size(:t_info_s)),
         >> = sauce_record_bin,
         false <- <<0, 0>> == version,
         true <- file_type >= 0,
         true <- data_type >= 0 do
      true
    else
      _ -> false
    end
  end

  def valid_sauce?(_bin) do
    false
  end

  @doc """
  Scans a binary for a comment block and returns it if found.
  """
  @spec discover_comments(binary()) :: comments_binary()
  def discover_comments(bin) when is_binary(bin) do
    #TODO: refactor
    case split_record(bin) do
      {<<>>, _} -> <<>>
      {_, <<>>} -> <<>>
      {contents_bin, sauce_bin} when is_binary(contents_bin) and is_binary(sauce_bin) ->
        bin_size = byte_size(contents_bin)
        if bin_size >= Sauce.minimum_comment_block_byte_size() do
          comment_offset = bin_size - Sauce.minimum_comment_block_byte_size()
          <<remaining_bin::binary-size(comment_offset), comments_bin::binary-size(Sauce.minimum_comment_block_byte_size())>> = contents_bin
          do_discover_comments(comments_bin, remaining_bin)
        else
          <<>>
        end
    end
  end

  defp do_discover_comments(<<Sauce.comment_id(), _comment_lines::binary-size(Sauce.minimum_comment_block_byte_size())>> = comments_bin, <<>>) do
    # 1 comment line
    comments_bin
  end

  defp do_discover_comments(<<Sauce.comment_id(), _comment_lines::binary>> = comments_bin, _remaining) do
    # multiple comment lines
    comments_bin
  end

  defp do_discover_comments(comments_bin, remaining) do
    # COMNT + 64 + LAST

    bin_size = byte_size(remaining)
    if bin_size >= Sauce.minimum_comment_block_byte_size() do
      offset = bin_size - Sauce.comment_line_byte_size()
      <<rest_bin::binary-size(offset), comments_start_bin::binary-size(Sauce.comment_line_byte_size())>> = remaining
      do_discover_comments(<<comments_start_bin::binary-size(Sauce.comment_line_byte_size()), comments_bin::binary>>, rest_bin)
    else
      <<>>
    end
  end

  @doc """
  Determines if a binary is terminated by an EOF character.
  """
  @spec eof_terminated?(binary()) :: boolean()
  def eof_terminated?(bin) when is_binary(bin) do
    if :binary.last(bin) == Sauce.eof_character() do
      true
    else
      false
    end
  end

  @doc """
  Terminates a binary with an EOF character.
  """
  @spec eof_terminate(binary()) :: binary()
  def eof_terminate(bin) when is_binary(bin) do
    if eof_terminated?(bin) do
      bin
    else
      bin_size = byte_size(bin)
      <<bin::binary-size(bin_size), Sauce.eof_character()>>
    end
  end

  @doc """
  Searches for the first occurrence of a SAUCE comment block in a binary and returns the `{position, length}` corresponding to the SAUCE comment block.

  If no comment block is found, :nomatch is returned.

  Options may be provided according to `:binary.match`.

  Additionally, the `:eof?` boolean option may be specified to search for a match against the end-of-file character (EOF) that is required in a SAUCE file. When searching sub-binaries or damaged files, you may wish to avoid this requirement by specifying `[eof?: false]` as an option, while conversely you may wish to set it true to explicitly check for a correct comment block.

  The returned `{position, length}` will always match that of the comment block itself and does not include the EOF character as part of the position or length.

  Note: A comment block cannot exist by definition if no SAUCE record exists. If the binary has no SAUCE, the comments data will be ignored as it is invalid and not guaranteed to be part of a SAUCE comment block. If you wish to manage the presence of an erroneous comment block for fixing a SAUCE, cleaning a file, or other purposes, use `match_comments_fragment` which removes this requirement.
  """
  @spec match_comment_block(binary(), Enum.t()) :: {non_neg_integer(), pos_integer()} | :nomatch
  def match_comment_block(bin, opts \\ [eof?: false])
  def match_comment_block(bin, opts) when is_binary(bin) do
    with bin_size when bin_size >= Sauce.minimum_commented_sauce_size() <- byte_size(bin),
        # first we check if there is a SAUCE because we need to know the comment block is valid at all
         {sauce_pos, Sauce.sauce_record_byte_size()} <- match_sauce_record(bin, [{:scope, {bin_size, -Sauce.sauce_record_byte_size()}}]),
         {eof?, match_opts} = Keyword.pop(opts, :eof?, false),
          # because we know the SAUCE exists, we can reduce the scope to search if the scope was already not passed
          # we can probably compress this scope some, but walking backward negatively without knowing the size has some issues unless using EOF character
          scoped_opts = Keyword.put_new_lazy(match_opts, :scope, fn -> {0, (bin_size - 128)} end),
         {pos, _len} <- do_match_comments(bin, eof?, scoped_opts),
         # comments must actually be at least 69 bytes long. We need to ensure we didn't match some random COMNT data that is truncated or otherwise invalid.
         true <- (bin_size - pos - Sauce.minimum_comment_block_byte_size()) >= 0 do
      {pos, sauce_pos - pos}
    else
      _ -> :nomatch
    end
  end

  @doc """
  Searches for the first occurrence of a SAUCE comment block fragment in a binary and returns the `{position, length}` corresponding to the SAUCE comment block.

  If no comment block is found, :nomatch is returned.

  Options may be provided according to `:binary.match`.

  Additionally, the `:eof?` boolean option may be specified to search for a match against the end-of-file character (EOF) that is required in a SAUCE file. When searching sub-binaries or damaged files, you may wish to avoid this requirement by specifying `[eof?: false]` as an option, while conversely you may wish to set it true to explicitly check for a correct comment block.

  The returned `{position, length}` will always match that of the comment block itself and does not include the EOF character as part of the position or length.

  Note: A comment block cannot exist by definition if no SAUCE record exists. If the binary has no SAUCE, the comments data will still be returned. If you wish to manage the presence of an erroneous comment block for fixing a SAUCE, cleaning a file, or other purposes, use `match_comment_block` which adds this requirement.
  """
  @spec match_comments_fragment(binary(), Enum.t()) :: {non_neg_integer(), pos_integer()} | :nomatch
  def match_comments_fragment(bin, opts \\ [eof?: false])
  def match_comments_fragment(bin, opts) when is_binary(bin) do
    with bin_size when bin_size >= Sauce.minimum_comment_block_byte_size() <- byte_size(bin),
         {eof?, match_opts} = Keyword.pop(opts, :eof?, false),
         {pos, _len} <- do_match_comments(bin, eof?, match_opts),
         # comments must actually be at least 69 bytes long. We need to ensure we didn't match some random COMNT data that is truncated or otherwise invalid.
         true <- (bin_size - pos - Sauce.minimum_comment_block_byte_size()) >= 0 do
      case match_sauce_record(bin, [{:scope, {pos, bin_size - pos}}]) do
        :nomatch ->
          {pos, bin_size - pos}
        {sauce_position, _len} ->
          {pos, sauce_position - pos}
      end
    else
      _ -> :nomatch
    end
  end

  defp do_match_comments(bin, true, match_opts) do
    case :binary.match(bin, <<Sauce.eof_character(), Sauce.comment_id()>>, match_opts) do
      :nomatch -> :nomatch
      {pos, length} -> {pos + 1, length - 1}
    end
  end

  defp do_match_comments(bin, _eof?, match_opts) do
    :binary.match(bin, <<Sauce.comment_id()>>, match_opts)
  end

  @doc """
  Searches for the first occurrence of a SAUCE record in a binary and returns the `{pos, length}` corresponding to the start of the SAUCE block.

  If no comment block is found, :nomatch is returned.

  Options may be provided according to `:binary.match`.

  Additionally, the `:eof?` boolean option may be specified to search for a match against the end-of-file character (EOF) that is required in a SAUCE file. This can be used to search for a SAUCE record without comments, a sub-binary, or damaged files. Note that when comments are present, specifying `[eof?: true]` will result in never matching a SAUCE record.

  If you need to verify that the EOF character is present before SAUCE data, it is suggested that you first call `match_comment_block(bin, [eof?: true])` or read the SAUCE comment lines field to get the length and position of the comment block, and check the result to verify the EOF character's correct position with respect to the SAUCE data.

  The returned `{position, length}` will always match that of the comment block itself and does not include the EOF character as part of the position or length.
  """
  @spec match_sauce_record(binary(), Enum.t()) :: {non_neg_integer(), pos_integer()} | :nomatch
  def match_sauce_record(bin, opts \\ [eof?: false])
  def match_sauce_record(bin, opts) when is_binary(bin) do
    # we check to see if the binary is at least big enough to accommodate the rest of the SAUCE.
    with bin_size when bin_size >= Sauce.sauce_record_byte_size() <- byte_size(bin),
         {eof?, match_opts} = Keyword.pop(opts, :eof?, false),
         {pos, _len} <- do_match_sauce(bin, eof?, match_opts),
        # SAUCE must actually be at least 128 bytes long. we need to ensure we didn't match some random SAUCE data that is truncated or otherwise invalid.
         0 <- (bin_size - pos - Sauce.sauce_record_byte_size()) do
      {pos, Sauce.sauce_record_byte_size()}
    else
      _ -> :nomatch
    end
  end

  defp do_match_sauce(bin, true, match_opts) do
    case :binary.match(bin, <<Sauce.eof_character(), Sauce.sauce_id()>>, match_opts) do
      :nomatch -> :nomatch
      {pos, length} -> {pos + 1, length - 1}
    end
  end

  defp do_match_sauce(bin, _eof?, match_opts) do
    :binary.match(bin, <<Sauce.sauce_id()>>, match_opts)
  end

  defp read_sauce_comment_lines(sauce_bin) do
    with {:ok, comment_lines} <- read_field(sauce_bin, :comment_lines),
         lines <- comment_lines |> :binary.decode_unsigned(:little) do
      {:ok, lines}
    end
  end

  defp extract_comments(bin, comment_lines) when is_binary(bin) and is_integer(comment_lines) and comment_lines > 0 do
    with sauce_byte_size = Sauce.sauce_byte_size(comment_lines),
         bin_size when bin_size >= sauce_byte_size <- byte_size(bin),
         comment_block_size = Sauce.comment_block_byte_size(comment_lines),
         comments_offset = bin_size - sauce_byte_size,
         <<_file_contents_bin::binary-size(comments_offset), comments_bin::binary-size(comment_block_size), _sauce_record::binary-size(Sauce.sauce_record_byte_size())>> = bin,
         true <- matches_comment_block?(comments_bin) do
      {:ok, comments_bin}
    else
      {:error, _reason} = err -> err
      _ -> {:error, :no_comments}
    end
  end

  defp extract_comments(bin, _comment_lines) when is_binary(bin) do
    # no comments present but we tried to grab them anyway
    {:error, :no_comments}
  end

  defp extract_sauce_record(bin) do
    with bin_size when bin_size >= Sauce.sauce_record_byte_size() <- byte_size(bin),
         sauce_offset = bin_size - Sauce.sauce_record_byte_size(),
         <<_ ::binary-size(sauce_offset), sauce_record_bin::binary-size(Sauce.sauce_record_byte_size())>> = bin,
         true <- matches_sauce?(sauce_record_bin) do
      {:ok, sauce_record_bin}
    else
      {:error, _reason} = err -> err
      _ -> {:error, :no_sauce}
    end
  end

  defp extract_contents(bin) when is_binary(bin) do
    with {:ok, {_sauce_record_bin, comment_lines}} <- sauce_handle(bin) do
            bin_size = byte_size(bin)
            offset = case extract_comments(bin, comment_lines) do
              {:ok, _comments} ->  bin_size - Sauce.sauce_byte_size(comment_lines)
              {:error, :no_comments} -> bin_size - Sauce.sauce_record_byte_size()
            end
            <<contents_bin::binary-size(offset), _rest::binary>> = bin
            {:ok, contents_bin}
    else
      {:error, :no_sauce} -> {:ok, bin}
    end
  end

  defp maybe_extract_comments(bin, comment_lines) do
    case extract_comments(bin, comment_lines) do
      {:ok, _comments_bin} = result -> result
      {:error, :no_comments} -> {:ok, <<>>}
    end
  end

end
