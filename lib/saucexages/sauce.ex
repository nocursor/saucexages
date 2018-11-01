defmodule Saucexages.Sauce do
  @moduledoc """
  Functions for working with [SAUCE](http://www.acid.org/info/sauce/sauce.htm).
  """

  @sauce_version "00"
  @sauce_id "SAUCE"
  @comment_id "COMNT"
  @comment_line_byte_size 64
  @sauce_record_byte_size 128
  @max_comment_lines 255
  @eof_character 0x1a
  @file_size_limit <<255, 255, 255, 255>> |> :binary.decode_unsigned(:little)

  @type field_id :: :sauce_id | :version | :title | :author | :group | :date | :file_size | :data_type | :file_type | :t_info_1 | :t_info_2 | :t_info3 | :t_info_4 | :comment_lines | :t_flags | :t_info_s

  #TODO: Make FieldMeta module with well-defined struct? - these may eventually roll into a validation lib via something like vex or ecto if it reduces deps
  @field_mappings [
    %{field_id: :sauce_id, field_size: 5, required?: true},
    %{field_id: :version, field_size: 2, required?: true},
    %{field_id: :title, field_size: 35, required?: false},
    %{field_id: :author, field_size: 20, required?: false},
    %{field_id: :group, field_size: 20, required?: false},
    %{field_id: :date, field_size: 8, required?: false},
    %{field_id: :file_size, field_size: 4, required?: false},
    %{field_id: :data_type, field_size: 1, required?: true},
    %{field_id: :file_type, field_size: 1, required?: true},
    %{field_id: :t_info_1, field_size: 2, required?: false},
    %{field_id: :t_info_2, field_size: 2, required?: false},
    %{field_id: :t_info_3, field_size: 2, required?: false},
    %{field_id: :t_info_4, field_size: 2, required?: false},
    %{field_id: :comment_lines, field_size: 1, required?: false},
    %{field_id: :t_flags, field_size: 1, required?: false},
    %{field_id: :t_info_s, field_size: 22, required?: false},
  ]

  defguard is_comment_lines(comment_lines) when is_integer(comment_lines) and comment_lines >= 0 and comment_lines <=  @max_comment_lines
  defguard is_comment_block(comment_lines) when is_integer(comment_lines) and comment_lines > 0 and comment_lines <=  @max_comment_lines

  @doc """
  Returns a list of metadata for each SAUCE record field.
  """
  @spec field_mappings() :: [map()]
  defmacro field_mappings() do
    @field_mappings |> Macro.escape()
  end

  @doc """
  Returns the EOF (end-of-file) character value that should be used when reading or writing a SAUCE.
  """
  @spec eof_character() :: integer()
  defmacro eof_character() do
    @eof_character
  end

  @doc """
  Returns the size of a SAUCE field in bytes. The byte size determines how much fixed-space in a SAUCE binary the field should occupy.

  Useful for building binaries, constructing matches, and avoiding sizing errors when working with SAUCE.

  Only matches valid SAUCE fields.

  ## Examples

      iex> Saucexages.Sauce.field_size(:title)
      35

      iex> Saucexages.Sauce.field_size(:t_info_1)
      2

  """
  @spec field_size(field_id()) :: pos_integer()
  defmacro field_size(field_id)
  for %{field_id: field_id, field_size: field_size} <- @field_mappings do
    defmacro field_size(unquote(field_id)) do
      unquote(field_size)
    end
  end

  @doc """
  Returns a list of metadata for each SAUCE record field, including calculated information such as field position.
  """
  @spec field_list() :: [map()]
  defmacro field_list() do
    {fields, _} = Enum.map_reduce(@field_mappings, 0, fn(%{field_size: field_size} = field, acc) -> {Map.put(field, :position, acc), acc + field_size} end)
    fields |> Macro.escape()
  end

  @doc """
  Returns the zero-based binary offset within a SAUCE record for a given `field_id`.

  Optionally, you may pass a boolean to indicate if the field is offset from the SAUCE `sauce_id` field.

  Useful for jumping to the exact start position of a field, building binaries, constructing matches, and avoiding sizing errors when working with SAUCE.

  Used with `field_size/1`, it can be helpful for working with SAUCE binaries efficiently.

  ## Examples

      iex> Saucexages.Sauce.field_position(:title)
      7

      iex> Saucexages.Sauce.field_position(:title, true)
      2

      iex> Saucexages.Sauce.field_position(:sauce_id)
      0

      iex> Saucexages.Sauce.field_position(:t_info_s)
      106

  """
  @spec field_position(field_id(), boolean()) :: non_neg_integer()
  defmacro field_position(field_id, offset? \\ false)
  with {fields, _} <- Enum.map_reduce(@field_mappings, 0, fn (%{field_id: field_id, field_size: field_size}, acc) -> {%{field_id: field_id, field_size: field_size, position: acc}, acc + field_size} end) do
    for %{field_id: field_id, position: position} <- fields do
      defmacro field_position(unquote(field_id), false) do
        unquote(position)
      end
      if field_id != :sauce_id do
        defmacro field_position(unquote(field_id), true) do
          unquote(position) - byte_size(@sauce_id)
        end
      else
        defmacro field_position(unquote(field_id), true) do
          unquote(position)
        end
      end
    end
  end

  @doc """
  Returns a list of metadata consisting only of required fields for a SAUCE record. SAUCE binary that lacks these fields should be considered invalid.
  """
  @spec required_fields() :: [map()]
  defmacro required_fields() do
    Enum.filter(@field_mappings, fn(%{required?: required?}) -> required? end) |> Macro.escape()
  end

  @doc """
  Returns a list of field_ids consisting only of required fields for a SAUCE record. SAUCE binary that lacks these fields should be considered invalid.

  ## Examples

      iex> Saucexages.Sauce.required_field_ids()
      [:sauce_id, :version, :data_type, :file_type]

  """
  @spec required_field_ids() :: [field_id()]
  defmacro required_field_ids() do
    Enum.flat_map(@field_mappings, fn(%{field_id: field_id, required?: required?}) -> if required?, do: [field_id], else: [] end) |> Macro.escape()
  end

  @doc """
  Default value of the sauce version field.

  ## Examples

      iex> Saucexages.Sauce.sauce_version()
      "00"

  """
  @spec sauce_version() :: String.t()
  defmacro sauce_version() do
    @sauce_version
  end

  @doc """
  Value of the sauce ID field.

  Useful for constructing binaries and matching.

  ## Examples

      iex> Saucexages.Sauce.sauce_id()
      "SAUCE"

  """
  @spec sauce_id() :: String.t()
  defmacro sauce_id() do
    @sauce_id
  end

  @doc """
  Value of the sauce comment ID field.

  Useful for constructing binaries and matching.

  ## Examples

      iex> Saucexages.Sauce.comment_id()
      "COMNT"

  """
  @spec comment_id() :: String.t()
  defmacro comment_id() do
    @comment_id
  end

  @doc """
  Byte size of the sauce comment ID field.

  Useful for constructing binaries and matching.

  ## Examples

      iex> Saucexages.Sauce.comment_id_byte_size()
      5

  """
  @spec comment_id_byte_size() :: pos_integer()
  defmacro comment_id_byte_size() do
    byte_size(@comment_id)
  end

  @doc """
  Byte size of a single comment line in a sauce.

  Useful for constructing binaries and matching.

  ## Examples

      iex> Saucexages.Sauce.comment_line_byte_size()
      64

  """
  @spec comment_line_byte_size() :: pos_integer()
  defmacro comment_line_byte_size() do
    @comment_line_byte_size
  end

  @doc """
  Total byte size of all comment lines when stored.

  Useful for constructing binaries and matching.

  ## Examples

       iex> Saucexages.Sauce.comments_byte_size(1)
       64

       iex> Saucexages.Sauce.comments_byte_size(2)
       128

  """
  @spec comments_byte_size(non_neg_integer()) :: non_neg_integer()
  def comments_byte_size(comment_lines) when is_comment_lines(comment_lines) do
    comment_lines * @comment_line_byte_size
  end

  def comments_byte_size(comment_lines) do
    raise ArgumentError, "Comment lines must be an integer greater than or equal to zero and less than or equal to #{inspect @max_comment_lines}, instead got #{inspect comment_lines}}."
  end

  @doc """
  Max number of comment lines allowed according to the SAUCE spec.

  ## Examples

      iex> Saucexages.Sauce.max_comment_lines()
      255

  """
  @spec max_comment_lines() :: pos_integer()
  defmacro max_comment_lines() do
    @max_comment_lines
  end

  @doc """
  Byte size of just the sauce record fields.

  Useful for constructing binaries and matching.

  ## Examples

      iex> Saucexages.Sauce.sauce_record_byte_size()
      128

  """
  @spec sauce_record_byte_size() :: pos_integer()
  defmacro sauce_record_byte_size() do
    @sauce_record_byte_size
  end

  @doc """
  Byte size of the sauce record fields, excluding the sauce_id.

  Useful for constructing binaries and matching.

  ## Examples

      iex> Saucexages.Sauce.sauce_data_byte_size()
      123

  """
  @spec sauce_data_byte_size() :: pos_integer()
  defmacro sauce_data_byte_size() do
    @sauce_record_byte_size - byte_size(@sauce_id)
  end

  @doc """
  Byte size of the sauce ID field.

  ## Examples

      iex> Saucexages.Sauce.sauce_id_byte_size()
      5

  """
  @spec sauce_id_byte_size() :: pos_integer()
  defmacro sauce_id_byte_size() do
    byte_size(@sauce_id)
  end

  @doc """
  Total byte size of a sauce including the full comments block.

  ## Examples

      iex> Saucexages.Sauce.sauce_byte_size(1)
      197

      iex> Saucexages.Sauce.sauce_byte_size(2)
      261

  """
  @spec sauce_byte_size(non_neg_integer()) :: pos_integer()
  def sauce_byte_size(comment_lines)
  def sauce_byte_size(0) do
    @sauce_record_byte_size
  end

  def sauce_byte_size(comment_lines) when is_comment_block(comment_lines) do
    comment_block_byte_size(comment_lines) + @sauce_record_byte_size
  end

  def sauce_byte_size(comment_lines) do
    raise ArgumentError, "Comment lines must be an integer greater than or equal to zero and less than or equal to #{inspect @max_comment_lines}, instead got #{inspect comment_lines}}."
  end

  @doc """
  Total byte size of a sauce comments block, including the comment ID.

  ## Examples

      iex> Saucexages.Sauce.comment_block_byte_size(1)
      69

      iex> Saucexages.Sauce.comment_block_byte_size(2)
      133

      iex> Saucexages.Sauce.comment_block_byte_size(0)
      0

  """
  @spec comment_block_byte_size(non_neg_integer()) :: non_neg_integer()
  def comment_block_byte_size(comment_lines)
  def comment_block_byte_size(0) do
    0
  end
  def comment_block_byte_size(comment_lines) when is_comment_block(comment_lines) do
    comments_byte_size(comment_lines) + comment_id_byte_size()
  end

  def comment_block_byte_size(comment_lines) do
    raise ArgumentError, "Comment lines must be an integer greater than or equal to zero and less than or equal to #{inspect @max_comment_lines}, instead got #{inspect comment_lines}}."
  end

  @doc """
  Minimum byte size of a comment block as required by SAUCE.

  The minimum requirement for a comment block is that it includes the comment id (COMNT) and enough space for 1 comment line (64 bytes).

  ## Examples

      iex> Saucexages.Sauce.minimum_comment_block_byte_size()
      69

  """
  @spec minimum_comment_block_byte_size() :: pos_integer()
  defmacro minimum_comment_block_byte_size() do
    comment_block_byte_size(1)
  end

  @doc """
  Minimum byte size of a SAUCE block that includes at least one comment.

  ## Examples

      iex> Saucexages.Sauce.minimum_commented_sauce_size()
      197

  """
  @spec minimum_commented_sauce_size() :: pos_integer()
  defmacro minimum_commented_sauce_size() do
    @sauce_record_byte_size + comment_block_byte_size(1)
  end

  @doc """
  Byte size limit for a file size (32-bit unsigned integer) according to SAUCE. Any file size bigger than this limit is set to zero or can be considered undefined.

  ## Examples

      iex> Saucexages.Sauce.file_size_limit()
      4294967295

  """
  @spec file_size_limit() :: pos_integer()
  defmacro file_size_limit() do
    @file_size_limit
  end

end
