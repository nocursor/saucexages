defmodule Saucexages.DataTypeInfo do
  @moduledoc false

  @enforce_keys [:data_type_id, :data_type, :name]

  @type t :: %__MODULE__{
               data_type_id: atom(),
               data_type: non_neg_integer(),
               name: String.t()
             }

  defstruct [:data_type_id, :data_type, :name]
end

defmodule Saucexages.DataType do
  @moduledoc """
  Functions for working with SAUCE Data Types. Each data type in combination with a file type determines how SAUCE type dependent fields should be interpreted. The `data type` and `file type` together form *named file types* such as ANSI, ASCII, RIP Script, HTML, and S3M among many others.

  Each data type is represented by a human-readable `data_type_id` and has *one* or *more* associated file types. The `data_type` itself is stored in a field in a SAUCE record as an unsigned integer.

  You should work with `data_type_id` internally in your system and `data_type` only when working *externally* or dealing *directly* with SAUCE binary values.

  The list of data types itself is fixed and is a part of the SAUCE specification. In the unlikely event you need to work with an unsupported data type, you should use a data_type of `:none` or otherwise reconsider.


  ## Data Types Overview

  The following `data_type_id` values are valid and correspond to those defined by the SAUCE spec:

  * `:none` - Anything not set in a SAUCE record or not covered by the SAUCE spec.
  * `:character` - Character-based files such as `ascii`, `ansi graphics`, and other text files.
  * `:bitmap` - Bitmap graphic and animation files such as `gif`, `png`, `jpeg`, etc.
  * `:vector` - Vector graphics file such as `dxf`, `dwg`, etc.
  * `:audio` - Audio files such as mod, s3m, wav, etc.
  * `:binary_text` - Raw memory copy of text mode screen, used for art .BIN files.
  * `:xbin` - Extended BIN files
  * `:archive` - Archive files such as `zip`, `arc`, `lzh`, etc.
  * `executable` - Executable scripts such as `.exe`, `.bat`, `.dll`, etc.

  ## Notes

  In the case of `:binary_text`, its file type is variable and thus can be any non-negative file type.

  Be aware that some media types might intuitively match some of these types such, but you should not assume any typing other than what is defined by the SAUCE spec. For instance, `rip` files are vectors, but considered to be characters.

  It is critical that any media type not covered by this spec should be assumed to have a data type of `:none` unless you are able to update the official SAUCE spec.
  """

  alias Saucexages.DataTypeInfo

  @type data_type :: non_neg_integer()
  @type data_type_id :: :none | :character | :bitmap | :vector | :audio | :binary_text | :xbin | :archive | :executable

  @data_type_mapping    [
    %DataTypeInfo{data_type_id: :none, data_type: 0, name: "None"},
    %DataTypeInfo{data_type_id: :character, data_type: 1, name: "Character"},
    %DataTypeInfo{data_type_id: :bitmap, data_type: 2, name: "Bitmap"},
    %DataTypeInfo{data_type_id: :vector, data_type: 3, name: "Vector"},
    %DataTypeInfo{data_type_id: :audio, data_type: 4, name: "Audio"},
    %DataTypeInfo{data_type_id: :binary_text, data_type: 5, name: "Binary Text"},
    %DataTypeInfo{data_type_id: :xbin, data_type: 6, name: "XBIN"},
    %DataTypeInfo{data_type_id: :archive, data_type: 7, name: "Archive"},
    %DataTypeInfo{data_type_id: :executable, data_type: 8, name: "Executable"},
  ]

  @doc """
  Returns a full list of data type info available for SAUCE.
  """
  @spec data_type_meta() :: [DataTypeInfo.t()]
  defmacro data_type_meta() do
    @data_type_mapping
    |> Macro.escape()
  end

  @doc """
  Returns the data type meta information for the given data type.

  ## Examples

      iex> Saucexages.DataType.data_type_meta(:character)
      %Saucexages.DataTypeInfo{
        data_type: 1,
        data_type_id: :character,
        name: "Character"
      }

  """
  @spec data_type_meta(data_type() | data_type_id()) :: DataTypeInfo.t()
  def data_type_meta(data_type)
  for %{data_type_id: data_type_id, data_type: data_type} = data_type_info <- @data_type_mapping do
    def data_type_meta(unquote(data_type_id)) do
      unquote(
        data_type_info
        |> Macro.escape()
      )
    end

    def data_type_meta(unquote(data_type)) do
      unquote(
        data_type_info
        |> Macro.escape()
      )
    end
  end

  def data_type_meta(data_type) when is_integer(data_type) or is_atom(data_type) do
    nil
  end

  @doc """
  Returns a list of data type ids available for SAUCE.

  ## Examples

      iex> Saucexages.DataType.data_type_ids()
      [:none, :character, :bitmap, :vector, :audio, :binary_text, :xbin, :archive,
      :executable]

  """
  @spec data_type_ids() :: [data_type_id()]
  defmacro data_type_ids() do
    Enum.map(@data_type_mapping, fn (%{data_type_id: data_type_id}) -> data_type_id end)
  end

  @doc """
  Returns a data type identifier for a given data type value.

  ## Examples

      iex> Saucexages.DataType.data_type_id(1)
      :character

      iex> Saucexages.DataType.data_type_id(2)
      :bitmap

      iex> Saucexages.DataType.data_type_id(44)
      :none

  """
  @spec data_type_id(data_type()) :: data_type_id()
  def data_type_id(data_type)
  for %{data_type_id: data_type_id, data_type: data_type} <- @data_type_mapping do
    def data_type_id(unquote(data_type)) do
      unquote(data_type_id)
    end
  end

  def data_type_id(data_type) when is_integer(data_type) do
    :none
  end

  @doc """
  Returns a data type value for a given data type identifier.

  ## Examples

      iex> Saucexages.DataType.data_type(:none)
      0

      iex> Saucexages.DataType.data_type(:character)
      1

      iex> Saucexages.DataType.data_type(:bitmap)
      2

  """
  @spec data_type(data_type_id()) :: data_type()
  def data_type(data_type_id)
  for %{data_type_id: data_type_id, data_type: data_type} <- @data_type_mapping do
    def data_type(unquote(data_type_id)) do
      unquote(data_type)
    end
  end

  def data_type(data_type_id) when is_atom(data_type_id) do
    0
  end

end
