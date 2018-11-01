defmodule Saucexages.MediaInfoMeta do
  @moduledoc false

  require Saucexages.DataType
  alias Saucexages.DataType

  @enforce_keys [:media_type_id, :file_type, :data_type_id, :name]

  defstruct [:media_type_id, :file_type, :data_type_id, :name, :t_info_1, :t_info_2, :t_info_3, :t_info_4, :t_flags, :t_info_s]

  @type t :: %__MODULE__{
               media_type_id: atom(),
               file_type: non_neg_integer(),
               data_type_id: DataType.data_type_id(),
               name: String.t(),
               t_info_1: non_neg_integer(),
               t_info_2: non_neg_integer(),
               t_info_3: non_neg_integer(),
               t_info_4: non_neg_integer(),
               t_flags: non_neg_integer(),
               t_info_s: String.t(),
             }

end


defmodule Saucexages.MediaInfo do
  @moduledoc """
  This module is used to provide facilities for working with type information described in the SAUCE spec. Typically, this consists at a minimum of a data type, possibly combined with a file type. The combination of the two together comprise the actual information type the SAUCE data is representing.

  This module uses the concept of a `media_type_id` atom to abstract and simplify the underlying media types. This allows a simple, compact, and human-readable representation when working with SAUCE information. `media_type_id` can be further used to decode and understand any type dependent fields within a SAUCE record.

  The type dependent fields include the following as describe by the SAUCE spec that may vary in meaning across media types:

  * `t_info_1`
  * `t_info_2`
  * `t_info_3`
  * `t_info_4`
  * `t_flags`
  * `t_info_s`

  Additionally, this module provides a number of convenience wrappers and tools for interrogating SAUCE information, fields, and related info. If you are building any sort of UI, behavior, or module that relies on type-specific field information (ex: aspect ratio, number of lines, etc.) then you should carefully scan the functions available in this module as most typical use-cases are considered.

  ## Use-Cases

  This module provides many functions to support the type dependent fields in SAUCE records.

  Some basic use-cases include:

  * Getting domain-specific names of SAUCE record values such as `character_width`, `pixel_height`, and `ansi_flags` among many others.
  * Reading and writing fields based on type-specific information, for example fields that are required or specific to that type
  * Extracting font, flags, colors, and other specific information, particularly in the case of character types such as ANSi art.
  * Selecting the appropriate types based on actual file type/mime type/metadata
  * Validating type information to avoid reading or writing invalid data for encoding/decoding SAUCE data

  ## Notes

  There is a very nasty edge-case in which `file_type` may be used to store data. According to the spec, this is only the case for the data type - `binary text`. As such, this module wraps this edge-case while handling all other data types cleanly as possible. Note that due to this edge-case, it is not possible to assume the `media_type_id` is redundant with `file_type`. As such, the `file_type` data is fully represented as a separate field to avoid data truncation or corruption.
  """

  require Saucexages.AnsiFlags
  require Saucexages.DataType
  require Saucexages.Font
  alias Saucexages.{MediaInfoMeta, AnsiFlags, DataType, Font}
  alias __MODULE__, as: MediaInfo

  @enforce_keys [:file_type, :data_type]
  @file_type_fields [:file_type, :data_type, :file_size, :t_info_1, :t_info_2, :t_info_3, :t_info_4, :t_flags, :t_info_s]
  @type_specific_fields [:t_info_1, :t_info_2, :t_info_3, :t_info_4, :t_flags, :t_info_s]

  defstruct [:file_type, :data_type, :t_info_s, t_info_1: 0, t_info_2: 0, t_info_3: 0, t_info_4: 0, t_flags: 0, file_size: 0]

  @type file_type :: non_neg_integer()
  @type type_handle :: {file_type(), DataType.data_type()}
  @type media_type_id :: :none | :ascii | :ansi | :ansimation | :rip | :pcboard | :avatar | :html | :source | :tundra_draw | :gif | :pcx | :lmb_iff | :tga | :fli | :flc | :bmp | :gl | :dl | :wpg_bitmap | :png | :jpg | :mpg | :avi | :dxf | :dwg | :wpg_vector | :"3ds" | :mod | :"669" | :stm | :s3m | :mtm | :far | :ult | :amf | :dmf | :okt | :rol | :cmf | :mid | :sadt | :voc | :wav | :smp8 | :smp8s | :smp16 | :smp16s | :patch8 | :patch16 | :xm | :hsc | :it | :binary_text | :xbin | :zip | :arj | :lzh | :arc | :tar | :zoo | :rar | :uc2 | :pak | :sqz | :executable

  @type t :: %__MODULE__{
               file_type: file_type(),
               data_type: non_neg_integer(),
               file_size: non_neg_integer(),
               t_info_1: non_neg_integer(),
               t_info_2: non_neg_integer(),
               t_info_3: non_neg_integer(),
               t_info_4: non_neg_integer(),
               t_flags: non_neg_integer(),
               t_info_s: String.t(),
             }

  @file_type_mapping [
    %MediaInfoMeta{
      media_type_id: :none,
      file_type: 0,
      data_type_id: :none,
      name: "Undefined"
    },
    %MediaInfoMeta{
      media_type_id: :ascii,
      file_type: 0,
      data_type_id: :character,
      name: "ASCII",
      t_info_1: :character_width,
      t_info_2: :number_of_lines,
      t_flags: :ansi_flags,
      t_info_s: :font_id
    },
    %MediaInfoMeta{
      media_type_id: :ansi,
      file_type: 1,
      name: "ANSi",
      data_type_id: :character,
      t_info_1: :character_width,
      t_info_2: :number_of_lines,
      t_flags: :ansi_flags,
      t_info_s: :font_id
    },
    %MediaInfoMeta{
      media_type_id: :ansimation,
      file_type: 2,
      name: "ANSiMation",
      data_type_id: :character,
      t_info_1: :character_width,
      t_info_2: :number_of_lines,
      t_flags: :ansi_flags,
      t_info_s: :font_id
    },
    %MediaInfoMeta{
      media_type_id: :rip,
      file_type: 3,
      name: "RIP Script",
      data_type_id: :character,
      t_info_1: :pixel_width,
      t_info_2: :pixel_height,
      t_info_3: :number_of_colors
    },
    %MediaInfoMeta{
      media_type_id: :pcboard,
      file_type: 4,
      name: "PC Board",
      data_type_id: :character,
      t_info_1: :character_width,
      t_info_2: :number_of_lines,
    },
    %MediaInfoMeta{
      media_type_id: :avatar,
      file_type: 5,
      name: "Avatar",
      data_type_id: :character,
      t_info_1: :character_width,
      t_info_2: :number_of_lines,
    },
    %MediaInfoMeta{
      media_type_id: :html,
      file_type: 6,
      name: "HTML",
      data_type_id: :character,
    },
    %MediaInfoMeta{
      media_type_id: :source,
      file_type: 7,
      name: "Source Code",
      data_type_id: :character,
    },
    %MediaInfoMeta{
      media_type_id: :tundra_draw,
      file_type: 8,
      name: "Tundra Draw",
      data_type_id: :character,
      t_info_1: :character_width,
      t_info_2: :number_of_lines,
    },
    %MediaInfoMeta{
      media_type_id: :gif,
      file_type: 0,
      name: "GIF",
      data_type_id: :bitmap,
      t_info_1: :pixel_width,
      t_info_2: :pixel_height,
      t_info_3: :pixel_depth,
    },
    %MediaInfoMeta{
      media_type_id: :pcx,
      file_type: 1,
      name: "PCX",
      data_type_id: :bitmap,
      t_info_1: :pixel_width,
      t_info_2: :pixel_height,
      t_info_3: :pixel_depth,
    },
    %MediaInfoMeta{
      media_type_id: :lmb_iff,
      file_type: 2,
      name: "LMB/IFF",
      data_type_id: :bitmap,
      t_info_1: :pixel_width,
      t_info_2: :pixel_height,
      t_info_3: :pixel_depth,
    },
    %MediaInfoMeta{
      media_type_id: :tga,
      file_type: 3,
      name: "TGA",
      data_type_id: :bitmap,
      t_info_1: :pixel_width,
      t_info_2: :pixel_height,
      t_info_3: :pixel_depth,
    },
    %MediaInfoMeta{
      media_type_id: :fli,
      file_type: 4,
      name: "FLI",
      data_type_id: :bitmap,
      t_info_1: :pixel_width,
      t_info_2: :pixel_height,
      t_info_3: :pixel_depth,
    },
    %MediaInfoMeta{
      media_type_id: :flc,
      file_type: 5,
      name: "FLC",
      data_type_id: :bitmap,
      t_info_1: :pixel_width,
      t_info_2: :pixel_height,
      t_info_3: :pixel_depth,
    },
    %MediaInfoMeta{
      media_type_id: :bmp,
      file_type: 6,
      name: "BMP",
      data_type_id: :bitmap,
      t_info_1: :pixel_width,
      t_info_2: :pixel_height,
      t_info_3: :pixel_depth,
    },
    %MediaInfoMeta{
      media_type_id: :gl,
      file_type: 7,
      name: "GL",
      data_type_id: :bitmap,
      t_info_1: :pixel_width,
      t_info_2: :pixel_height,
      t_info_3: :pixel_depth,
    },
    %MediaInfoMeta{
      media_type_id: :dl,
      file_type: 8,
      name: "DL",
      data_type_id: :bitmap,
      t_info_1: :pixel_width,
      t_info_2: :pixel_height,
      t_info_3: :pixel_depth,
    },
    %MediaInfoMeta{
      media_type_id: :wpg_bitmap,
      file_type: 9,
      name: "WPG",
      data_type_id: :bitmap,
      t_info_1: :pixel_width,
      t_info_2: :pixel_height,
      t_info_3: :pixel_depth,
    },
    %MediaInfoMeta{
      media_type_id: :png,
      file_type: 10,
      name: "PNG",
      data_type_id: :bitmap,
      t_info_1: :pixel_width,
      t_info_2: :pixel_height,
      t_info_3: :pixel_depth,
    },
    %MediaInfoMeta{
      media_type_id: :jpg,
      file_type: 11,
      name: "JPG",
      data_type_id: :bitmap,
      t_info_1: :pixel_width,
      t_info_2: :pixel_height,
      t_info_3: :pixel_depth,
    },
    %MediaInfoMeta{
      media_type_id: :mpg,
      file_type: 12,
      name: "MPG",
      data_type_id: :bitmap,
      t_info_1: :pixel_width,
      t_info_2: :pixel_height,
      t_info_3: :pixel_depth,
    },
    %MediaInfoMeta{
      media_type_id: :avi,
      file_type: 13,
      name: "AVI",
      data_type_id: :bitmap,
      t_info_1: :pixel_width,
      t_info_2: :pixel_height,
      t_info_3: :pixel_depth,
    },
    %MediaInfoMeta{
      media_type_id: :dxf,
      file_type: 0,
      name: "DXF",
      data_type_id: :vector,
    },
    %MediaInfoMeta{
      media_type_id: :dwg,
      file_type: 1,
      name: "DWG",
      data_type_id: :vector,
    },
    %MediaInfoMeta{
      media_type_id: :wpg_vector,
      file_type: 2,
      name: "WPG",
      data_type_id: :vector,
    },
    %MediaInfoMeta{
      media_type_id: :"3ds",
      file_type: 3,
      name: "3DS",
      data_type_id: :vector,
    },
    %MediaInfoMeta{
      media_type_id: :mod,
      file_type: 0,
      name: "MOD",
      data_type_id: :audio,
    },
    %MediaInfoMeta{
      media_type_id: :"669",
      file_type: 1,
      name: "669",
      data_type_id: :audio,
    },
    %MediaInfoMeta{
      media_type_id: :stm,
      file_type: 2,
      name: "STM",
      data_type_id: :audio,
    },
    %MediaInfoMeta{
      media_type_id: :s3m,
      file_type: 3,
      name: "S3M",
      data_type_id: :audio,
    },
    %MediaInfoMeta{
      media_type_id: :mtm,
      file_type: 4,
      name: "MTM",
      data_type_id: :audio,
    },
    %MediaInfoMeta{
      media_type_id: :far,
      file_type: 5,
      name: "FAR",
      data_type_id: :audio,
    },
    %MediaInfoMeta{
      media_type_id: :ult,
      file_type: 6,
      name: "ULT",
      data_type_id: :audio,
    },
    %MediaInfoMeta{
      media_type_id: :amf,
      file_type: 7,
      name: "AMF",
      data_type_id: :audio,
    },
    %MediaInfoMeta{
      media_type_id: :dmf,
      file_type: 8,
      name: "DMF",
      data_type_id: :audio,
    },
    %MediaInfoMeta{
      media_type_id: :okt,
      file_type: 9,
      name: "OKT",
      data_type_id: :audio,
    },
    %MediaInfoMeta{
      media_type_id: :rol,
      file_type: 10,
      name: "ROL",
      data_type_id: :audio,
    },
    %MediaInfoMeta{
      media_type_id: :cmf,
      file_type: 11,
      name: "CMF",
      data_type_id: :audio,
    },
    %MediaInfoMeta{
      media_type_id: :mid,
      file_type: 12,
      name: "MID",
      data_type_id: :audio,
    },
    %MediaInfoMeta{
      media_type_id: :sadt,
      file_type: 13,
      name: "SADT",
      data_type_id: :audio,
    },
    %MediaInfoMeta{
      media_type_id: :voc,
      file_type: 14,
      name: "VOC",
      data_type_id: :audio,
    },
    %MediaInfoMeta{
      media_type_id: :wav,
      file_type: 15,
      name: "WAV",
      data_type_id: :audio,
    },
    %MediaInfoMeta{
      media_type_id: :smp8,
      file_type: 16,
      name: "SMP8",
      data_type_id: :audio,
      t_info_1: :sample_rate,
    },
    %MediaInfoMeta{
      media_type_id: :smp8s,
      file_type: 17,
      name: "SMP8S",
      data_type_id: :audio,
      t_info_1: :sample_rate,
    },
    %MediaInfoMeta{
      media_type_id: :smp16,
      file_type: 18,
      name: "SMP16",
      data_type_id: :audio,
      t_info_1: :sample_rate,
    },
    %MediaInfoMeta{
      media_type_id: :smp16s,
      file_type: 19,
      name: "SMP16S",
      data_type_id: :audio,
      t_info_1: :sample_rate,
    },
    %MediaInfoMeta{
      media_type_id: :patch8,
      file_type: 20,
      name: "PATCH8",
      data_type_id: :audio,
    },
    %MediaInfoMeta{
      media_type_id: :patch16,
      file_type: 21,
      name: "PATCH16",
      data_type_id: :audio,
    },
    %MediaInfoMeta{
      media_type_id: :xm,
      file_type: 22,
      name: "XM",
      data_type_id: :audio,
    },
    %MediaInfoMeta{
      media_type_id: :hsc,
      file_type: 23,
      name: "HSC",
      data_type_id: :audio,
    },
    %MediaInfoMeta{
      media_type_id: :it,
      file_type: 24,
      name: "IT",
      data_type_id: :audio,
    },
    %MediaInfoMeta{
      media_type_id: :binary_text,
      file_type: 0,
      # file_type: nil,
      name: "Binary Text",
      data_type_id: :binary_text,
      t_flags: :ansi_flags,
      t_info_s: :font_id
    },
    %MediaInfoMeta{
      media_type_id: :xbin,
      file_type: 0,
      name: "XBIN",
      data_type_id: :xbin,
      t_info_1: :character_width,
      t_info_2: :number_of_lines,
    },
    %MediaInfoMeta{
      media_type_id: :zip,
      file_type: 0,
      name: "ZIP",
      data_type_id: :archive,
    },
    %MediaInfoMeta{
      media_type_id: :arj,
      file_type: 1,
      name: "ARJ",
      data_type_id: :archive,
    },
    %MediaInfoMeta{
      media_type_id: :lzh,
      file_type: 2,
      name: "LZH",
      data_type_id: :archive,
    },
    %MediaInfoMeta{
      media_type_id: :arc,
      file_type: 3,
      name: "ARC",
      data_type_id: :archive,
    },
    %MediaInfoMeta{
      media_type_id: :tar,
      file_type: 4,
      name: "TAR",
      data_type_id: :archive,
    },
    %MediaInfoMeta{
      media_type_id: :zoo,
      file_type: 5,
      name: "ZOO",
      data_type_id: :archive,
    },
    %MediaInfoMeta{
      media_type_id: :rar,
      file_type: 6,
      name: "RAR",
      data_type_id: :archive,
    },
    %MediaInfoMeta{
      media_type_id: :uc2,
      file_type: 7,
      name: "UC2",
      data_type_id: :archive,
    },
    %MediaInfoMeta{
      media_type_id: :pak,
      file_type: 8,
      name: "PAK",
      data_type_id: :archive,
    },
    %MediaInfoMeta{
      media_type_id: :sqz,
      file_type: 9,
      name: "sqz",
      data_type_id: :archive,
    },
    %MediaInfoMeta{
      media_type_id: :executable,
      file_type: 0,
      name: "Executable",
      data_type_id: :executable,
    },
  ]

  defguardp is_binary_text(file_type, data_type) when (data_type == 5 or data_type == :binary_text) and is_integer(file_type) and file_type >= 0

  @doc """
  Creates a new MediaInfo based on the given file_type and data_type.
  """
  @spec new(file_type(), DataType.data_type(), Enum.t()) :: t()
  def new(file_type, data_type, opts \\ []) do
    struct(%__MODULE__{file_type: file_type, data_type: data_type}, opts)
  end

  @doc """
  Lists all meta information about file types.

  Useful for building interfaces, specialized parsing, and dynamic access.
  """
  @spec media_meta() :: [MediaInfoMeta.t()]
  defmacro media_meta() do
    @file_type_mapping
    |> Macro.escape()
  end

  @doc """
  Lists all the meta information about the given media_type_id.

  ## Examples

      iex> Saucexages.MediaInfo.media_meta_by(:ansi)
      %Saucexages.MediaInfoMeta{
        data_type_id: :character,
        file_type: 1,
        media_type_id: :ansi,
        name: "ANSi",
        t_flags: :ansi_flags,
        t_info_1: :character_width,
        t_info_2: :number_of_lines,
        t_info_3: nil,
        t_info_4: nil,
        t_info_s: :font_id
      }

  """

  @spec media_meta_by(media_type_id()) :: MediaInfoMeta.t() | nil
  def media_meta_by(media_type_id)
  for %{media_type_id: media_type_id} = mapping <- @file_type_mapping do
    def media_meta_by(unquote(media_type_id)) do
      unquote(
        mapping
        |> Macro.escape()
      )
    end
  end

  def media_meta_by(_media_type_id) do
    nil
  end

  @doc """
  Lists all known file types.
  """
  @spec media_type_ids() :: [media_type_id()]
  defmacro media_type_ids() do
    Enum.map(@file_type_mapping, fn (%{media_type_id: media_type_id}) -> media_type_id end)
  end

  @doc """
  Lists all known file type ids per the given `data_type_id` or `data_type`.

  ## Examples

      iex> Saucexages.MediaInfo.media_type_ids_for(:character)
      [:ascii, :ansi, :ansimation, :rip, :pcboard, :avatar, :html, :source, :tundra_draw]

      iex> Saucexages.MediaInfo.media_type_ids_for(1)
      [:ascii, :ansi, :ansimation, :rip, :pcboard, :avatar, :html, :source, :tundra_draw]

  """
  @spec media_type_ids_for(DataType.data_type() | DataType.data_type_id()) :: [media_type_id()]
  defmacro media_type_ids_for(data_type)
  for %{data_type_id: data_type_id, data_type: data_type} <- DataType.data_type_meta() do
    defmacro media_type_ids_for(unquote(data_type_id)) do
      media_type_ids_by(unquote(data_type_id))
    end

    defmacro media_type_ids_for(unquote(data_type)) do
      DataType.data_type_id(unquote(data_type))
      |> media_type_ids_by()
    end
  end

  defmacro media_type_ids_for(_data_type) do
    []
  end

  defp media_type_ids_by(data_type_id) do
    Enum.flat_map(
      @file_type_mapping,
      fn (mapping) ->
        case mapping do
          %{media_type_id: nil} -> []
          %{data_type_id: ^data_type_id, media_type_id: media_type_id} -> [media_type_id]
          _ -> []
        end
      end
    )
  end

  @doc """
  Lists all known file type ids per the given `data_type_id` or `data_type`.

  For file types that don't exist for a given data type, ex: `binary_text`, an empty list will be returned.

  ## Examples

      iex> Saucexages.MediaInfo.file_types_for(:character)
      [0, 1, 2, 3, 4, 5, 6, 7, 8]

      iex> Saucexages.MediaInfo.file_types_for(1)
      [0, 1, 2, 3, 4, 5, 6, 7, 8]


      iex> Saucexages.MediaInfo.file_types_for(:binary_text)
      []

  """
  @spec file_types_for(DataType.data_type() | DataType.data_type_id()) :: [file_type()] | []
  defmacro file_types_for(data_type)
  for %{data_type_id: data_type_id, data_type: data_type} <- DataType.data_type_meta() do
    defmacro file_types_for(unquote(data_type_id)) do
      file_types_from(unquote(data_type_id))
    end

    defmacro file_types_for(unquote(data_type)) do
      DataType.data_type_id(unquote(data_type))
      |> file_types_from()
    end
  end

  defmacro file_types_for(_data_type) do
    []
  end

  defp file_types_from(data_type_id) when is_atom(data_type_id) do
    Enum.flat_map(
      @file_type_mapping,
      fn (mapping) ->
        case mapping do
          %{file_type: nil} -> []
          %{media_type_id: :binary_text} -> []
          %{data_type_id: ^data_type_id, file_type: file_type} -> [file_type]
          _ -> []
        end
      end
    )
  end

  @doc """
  Extracts the `data_type_id` associated for a known `media_type_id`.

  If the file type or data type is unknown, :none is returned.

  ## Examples

      iex> Saucexages.MediaInfo.data_type_id(:ansi)
      :character

      iex> Saucexages.MediaInfo.data_type_id(:mod)
      :audio

      iex> Saucexages.MediaInfo.data_type_id(:fried_chicken)
      :none

  """
  @spec data_type_id(media_type_id()) :: DataType.data_type_id()
  def data_type_id(media_type_id)
  for %{media_type_id: media_type_id, data_type_id: data_type_id} <- @file_type_mapping do
    def data_type_id(unquote(media_type_id)) do
      unquote(data_type_id)
    end
  end

  def data_type_id(_media_type_id) do
    :none
  end

  @doc """
  Extracts the integer data type from a given `media_type_id`.

  ## Examples

      iex> Saucexages.MediaInfo.data_type(:ansi)
      1

      iex> Saucexages.MediaInfo.data_type(:gif)
      2

      iex> Saucexages.MediaInfo.data_type(:chicken_salad)
      0

  """
  @spec data_type(media_type_id()) :: DataType.data_type()
  def data_type(media_type_id) do
    data_type_id(media_type_id)
    |> DataType.data_type()
  end

  @doc """
  Lists all dynamic file type fields that can be found in a SAUCE record.

  The meaning of each of these fields varies by `media_type_id`, and therefore by the combination of `data_type` and usually `file_type`.

  Useful for building interfaces, specialized parsing, and dynamic access.

  ## Examples

      iex> Saucexages.MediaInfo.type_fields()
      [:t_info_1, :t_info_2, :t_info_3, :t_info_4, :t_flags, :t_info_s]

  """
  @spec type_fields() :: [atom()]
  defmacro type_fields() do
    @type_specific_fields
  end

  @doc """
  Lists all dynamic file type fields that can be found in a SAUCE record for the given `media_type_id`.

  Useful for building interfaces, specialized parsing, and dynamic access.

  If you need the mapping between SAUCE fields and what they mean for a file type, see `type_field_mapping/1`.
  If you need the names of each field specific to the given file type, see `type_field_names/1`.

  ## Examples

      iex> Saucexages.MediaInfo.type_fields(:ansi)
      [:t_flags, :t_info_1, :t_info_2, :t_info_s]

      iex> Saucexages.MediaInfo.type_fields(:gif)
      [:t_info_1, :t_info_2, :t_info_3]

  """
  @spec type_fields(media_type_id()) :: [atom()]
  defmacro type_fields(media_type_id)
  for %{media_type_id: media_type_id} = mapping <- @file_type_mapping do
    defmacro type_fields(unquote(media_type_id)) do
      unquote(
        mapping
        |> Macro.escape()
      )
      |> Map.take(@type_specific_fields)
      |> Enum.flat_map(
           fn {k, v} ->
             case v do
               nil -> []
               v when is_atom(v) -> [k]
               _ -> []
             end
           end
         )
    end
  end

  defmacro type_fields(media_type_id) when is_atom(media_type_id) do
    []
  end

  @doc """
  Lists all dynamic file type fields that can be found in a SAUCE record for the given `file_type` and `data_type`.

  Useful for building interfaces, specialized parsing, and dynamic access.

  If you need the mapping between SAUCE fields and what they mean for a file type, see `type_field_map/1`.
  If you need the names of each field specific to the given file type, see `type_field_names/1`.

  ## Examples

      iex> Saucexages.MediaInfo.type_fields(1, 1)
      [:t_flags, :t_info_1, :t_info_2, :t_info_s]

      iex> Saucexages.MediaInfo.type_fields(0, 2)
      [:t_info_1, :t_info_2, :t_info_3]

  """
  @spec type_fields(file_type(), DataType.data_type()) :: [atom()]
  defmacro type_fields(file_type, data_type)
  for %{media_type_id: media_type_id, file_type: file_type, data_type_id: data_type_id} <- @file_type_mapping do
    data_type = DataType.data_type(data_type_id)
    defmacro type_fields(unquote(file_type), unquote(data_type)) do
      type_fields(unquote(media_type_id))
    end
  end

  defmacro type_fields(file_type, data_type) when is_binary_text(file_type, data_type)do
    type_fields(:binary_text)
  end

  defmacro type_fields(_file_type, _data_type) do
    []
  end

  @doc """
  Returns the `media_type_id` associated with the given `file_type` integer value and `data_type_id` or `data_type`.

  ## Examples

      iex> Saucexages.MediaInfo.new(1, 1) |> Saucexages.MediaInfo.media_type_id()
      :ansi

      iex> Saucexages.MediaInfo.new(10, 2) |> Saucexages.MediaInfo.media_type_id()
      :png

      iex> Saucexages.MediaInfo.new(27, :binary_text) |> Saucexages.MediaInfo.media_type_id()
      :binary_text

  """
  @spec media_type_id(t()) :: media_type_id()
  def media_type_id(%{file_type: file_type, data_type: data_type}) do
    media_type_id(file_type, data_type)
  end

  @doc """
  Returns the `media_type_id` associated with the given `file_type` integer value and `data_type_id` or `data_type`.

  ## Examples

      iex> Saucexages.MediaInfo.media_type_id(1, :character)
      :ansi

      iex> Saucexages.MediaInfo.media_type_id(10, :bitmap)
      :png

      iex> Saucexages.MediaInfo.media_type_id(10, 2)
      :png

  """
  @spec media_type_id(file_type, DataType.data_type_id() | DataType.data_type()) :: media_type_id()
  def media_type_id(file_type, data_type_id)
  for %{media_type_id: media_type_id, file_type: file_type, data_type_id: data_type_id} <- @file_type_mapping, !is_nil(file_type) do
    data_type = DataType.data_type(data_type_id)

    def media_type_id(unquote(file_type), unquote(data_type_id)) do
      unquote(media_type_id)
    end

    def media_type_id(unquote(file_type), unquote(data_type)) do
      unquote(media_type_id)
    end
  end

  def media_type_id(file_type, data_type) when is_binary_text(file_type, data_type) do
    :binary_text
  end

  def media_type_id(_file_type, _data_type_id) do
    :none
  end

  @doc """
  Returns the `file_type` associated with the given `media_type_id`.

  ## Examples

      iex> Saucexages.MediaInfo.file_type(:ansi)
      1

      iex> Saucexages.MediaInfo.file_type(:png)
      10

  """
  @spec file_type(media_type_id()) :: file_type()
  def file_type(media_type_id)
  for %{media_type_id: media_type_id, file_type: file_type} <- @file_type_mapping do
    def file_type(unquote(media_type_id)) do
      unquote(file_type)
    end
  end

  def file_type(media_type_id) when is_atom(media_type_id) do
    0
  end

  @doc """
  Returns a tuple of `file_type` and `data_type` associated with the given `media_type_id` to be used with SAUCE data directly, for example writing a SAUCE.

  ## Examples

      iex> Saucexages.MediaInfo.type_handle(:ansi)
      {1, 1}
      iex> Saucexages.MediaInfo.type_handle(:png)
      {10, 2}

  """
  @spec type_handle(media_type_id) :: type_handle()
  def type_handle(media_type_id)
  for %{media_type_id: media_type_id, file_type: file_type, data_type_id: data_type_id} <- @file_type_mapping do
    def type_handle(unquote(media_type_id)) do
      {unquote(file_type), DataType.data_type(unquote(data_type_id))}
    end
  end

  def type_handle(_media_type_id) do
    {0, 0}
  end

  @doc """
  Returns a map consisting of only basic info about the `media_type_id` associated with the given `file_type` map.

  If the file type is unknown, :undefined is returned.

  The following keys are always returned:

  * `media_type_id` - The unique identifier for a file type.
  * `data_type_id` - The unique identifier for a data type.
  * `name` - The friendly name for a file type.

  ## Examples

      iex> Saucexages.MediaInfo.new(1, 1) |> Saucexages.MediaInfo..basic_info()
      %{data_type_id: :character, media_type_id: :ansi, name: "ANSi"}

      iex> Saucexages.MediaInfo.new(10, 2) |> Saucexages.MediaInfo.basic_info()
      %{data_type_id: :bitmap, media_type_id: :png, name: "PNG"}

      iex> Saucexages.MediaInfo.new(10, :binary_text) |> Saucexages.MediaInfo.basic_info()
      %{data_type_id: :binary_text, media_type_id: :binary_text, name: "Binary Text"}

      iex> Saucexages.MediaInfo.new(1, 10) |> Saucexages.MediaInfo.basic_info()
      %{data_type_id: :none, media_type_id: :none, name: "Undefined"}

  """
  @spec basic_info(t()) :: map()
  def basic_info(file_type) when is_map(file_type) do
    media_type_id(file_type)
    |> basic_info()
  end

  @doc """
  Returns a map consisting of only basic info about the given `media_type_id`.

  The following keys are always returned:

  * `media_type_id` - The unique identifier for a file type.
  * `data_type_id` - The unique identifier for a data type.
  * `name` - The friendly name for a file type.

  ## Examples

      iex> Saucexages.MediaInfo.basic_info(:ansi)
      %{data_type_id: :character, media_type_id: :ansi, name: "ANSi"}

      iex> Saucexages.MediaInfo.basic_info(:png)
      %{data_type_id: :bitmap, media_type_id: :png, name: "PNG"}

      iex> Saucexages.MediaInfo.basic_info(:binary_text)
      %{data_type_id: :binary_text, media_type_id: :binary_text, name: "Binary Text"}

  """
  @spec basic_info(media_type_id()) :: map()
  def basic_info(media_type_id)
  for %{media_type_id: media_type_id, data_type_id: data_type_id, name: name} <- @file_type_mapping do
    def basic_info(unquote(media_type_id)) do
      %{
        media_type_id: unquote(media_type_id),
        data_type_id: unquote(data_type_id),
        name: unquote(name),
      }
    end

  end

  def basic_info(media_type_id) when is_atom(media_type_id) do
    basic_info(:none)
  end

  @doc """
  Returns a detailed map of any media info that can be converted per-file type, along with basic file type information.

  Useful for editors or specialized processing.

  Any type-specific fields that have special meaning will be converted accordingly. Type-specific fields without meaning will be left `as is` to account for cases when developers, apps, users, etc. have added this data contrary to the SAUCE spec.

  ## Examples

      iex> Saucexages.MediaInfo.details(%Saucexages.MediaInfo{file_type: 1, data_type: 1, t_flags: 17, t_info_1: 80, t_info_2: 250, t_info_s: "IBM VGA"})
      %{
        ansi_flags: %Saucexages.AnsiFlags{
          aspect_ratio: :modern,
          letter_spacing: :none,
          non_blink_mode?: true
        },
        character_width: 80,
        data_type: 1,
        data_type_id: :character,
        file_size: 0,
        file_type: 1,
        media_type_id: :ansi,
        font_id: :ibm_vga,
        name: "ANSi",
        number_of_lines: 250,
        t_info_3: 0,
        t_info_4: 0
      }

  """
  @spec details(t()) :: map()
  def details(media_info) when is_map(media_info) do
    # We could use a macro to do all this, but it's nicer to be slightly explicit as we may want additional functions called in this chain anyway
    with base_map when is_map(base_map) <- basic_info(media_info) do
      do_read_fields(media_info, base_map)
    else
      _ -> nil
    end
  end

  @doc """
  Returns a detailed map of any media info that can be converted per-file type. Only the detailed information is returned.

  Useful for editors or specialized processing.

  ## Examples

      iex> Saucexages.MediaInfo.media_details(%Saucexages.MediaInfo{file_type: 1, data_type: 1, t_flags: 17, t_info_1: 80, t_info_2: 250, t_info_s: "IBM VGA"})
      %{
        ansi_flags: %Saucexages.AnsiFlags{
          aspect_ratio: :modern,
          letter_spacing: :none,
          non_blink_mode?: true
        },
        character_width: 80,
        data_type: 1,
        file_size: 0,
        file_type: 1,
        font_id: :ibm_vga,
        number_of_lines: 250,
        t_info_3: 0,
        t_info_4: 0
      }

  """
  @spec media_details(t()) :: map()
  def media_details(media_info) when is_map(media_info) do
    do_read_fields(media_info, %{})
  end

  def media_details(_media_info) do
    nil
  end

  defp do_read_fields(media_info, file_type_info) do
    read_fields(media_info, @file_type_fields)
    |> Enum.into(file_type_info)
  end

  @doc """
  Returns a keyword list of all the type dependent fields for a given file type.

  Useful for building interfaces, specialized parsing, and dynamic access.

  ## Examples

      iex> Saucexages.MediaInfo.type_field_mapping(:ansi)
      [
        t_flags: :ansi_flags,
        t_info_1: :character_width,
        t_info_2: :number_of_lines,
        t_info_s: :font_id
      ]

  """
  @spec type_field_mapping(media_type_id()) :: Enum.t()
  def type_field_mapping(media_type_id)
  for %{media_type_id: media_type_id} = mapping <- @file_type_mapping do
    def type_field_mapping(unquote(media_type_id)) do
      unquote(
        mapping
        |> Macro.escape()
      )
      |> Map.take(@type_specific_fields)
      |> Enum.reject(fn ({_k, v}) -> is_nil(v) end)
    end
  end

  def type_field_mapping(_media_type_id) do
    []
  end

  @doc """
  Returns a list of all field names used by a given file type.

  Useful for building interfaces, specialized parsing, and dynamic access.

  ## Examples

      iex> Saucexages.MediaInfo.type_field_names(:ansi)
      [:ansi_flags, :character_width, :number_of_lines, :font_id]

      iex> Saucexages.MediaInfo.type_field_names(:gif)
      [:pixel_width, :pixel_height, :pixel_depth]

  """
  @spec type_field_names(media_type_id()) :: [atom()]
  def type_field_names(media_type_id)
  for %{media_type_id: media_type_id} = mapping <- @file_type_mapping do
    def type_field_names(unquote(media_type_id)) do
      unquote(
        mapping
        |> Macro.escape()
      )
      |> Map.take(@type_specific_fields)
      |> Enum.flat_map(
           fn ({_k, v}) ->
             case v do
               nil -> []
               v when is_atom(v) -> [v]
               _ -> []
             end
           end
         )
    end
  end

  def type_field_names(media_type_id) when is_atom(media_type_id) do
    []
  end

  @doc """
  Returns the field name associated with a given file type and file type field.

  ## Examples

      iex> Saucexages.MediaInfo.field_type(:ansi, :t_info_s)
      :font_id

      iex> Saucexages.MediaInfo.field_type(:ansi, :t_flags)
      :ansi_flags

  """
  @spec field_type(media_type_id(), atom()) :: atom()
  def field_type(media_type_id, field_type_id)
  for %{media_type_id: media_type_id} = mapping <- @file_type_mapping do
    def field_type(unquote(media_type_id), field_type_id) do
      case unquote(
             mapping
             |> Macro.escape()
           ) do
        %{^field_type_id => field_type_value} -> field_type_value
        _ -> nil
      end
    end
  end

  def field_type(_media_type_id, _field_type_id) do
    nil
  end

  @doc """
  Reads data dynamically for a given file info map based on its meta information and converts the data if possible.

  Returns a 2-tuple containing the new field id (if any) as the first element, and the field data (if any) as the second element.

  If the value does not exist in the map, you may pass a `default_value` to be used in these cases.

  Optionally, a 3-arity conversion function that takes the same parameters, `media_type_id`, `field_type_id`, and `value` may be passed for custom conversions.

  ## Examples

      iex> Saucexages.MediaInfo.read_media_field(%{file_type: 1, data_type: 1, t_flags: 17}, :t_flags)
      {:ansi_flags,
         %Saucexages.AnsiFlags{
           aspect_ratio: :modern,
           letter_spacing: :none,
           non_blink_mode?: true
      }}

      iex> Saucexages.MediaInfo.read_media_field(%{file_type: 1, data_type: 1, t_flags: 17, t_info_1: 80}, :t_info_2, 22)
      {:number_of_lines, 22}

  """
  @spec read_media_field(t(), atom(), term(), function()) :: {atom(), term()}
  def read_media_field(media_info, field_type_id, default_value \\ nil, conversion_fn \\ &read_field_value/3)
  def read_media_field(%{file_type: _file_type, data_type: _data_type} = media_info, field_type_id, default_value, conversion_fn) do
    media_type_id = media_type_id(media_info)
    with %{^field_type_id => value} <- media_info do
      read_field(media_type_id, field_type_id, value, conversion_fn)
    else
      _ -> read_field(media_type_id, field_type_id, default_value, conversion_fn)
    end
  end

  def read_media_field(_media_info, field_type_id, default_value, _conversion_fn) do
    {field_type_id, default_value}
  end

  @doc """
  Reads the fields given in the `field_ids` list dynamically and returns data based on file type information, converting data when possible. The field ids may be any field that is part of a MediaInfo. A new map will be returned with any valid fields converted accordingly.

  Unknown field ids will be ignored.

  Optionally, a 3-arity conversion function that takes the same parameters, `media_type_id`, `field_type_id`, and `value` may be passed for custom conversions.

  ## Examples


      iex> Saucexages.MediaInfo.read_fields(%Saucexages.MediaInfo{file_type: 1, data_type: 1, t_flags: 17, t_info_1: 80, t_info_2: 250, t_info_s: "IBM VGA"}, [:t_info_s, :t_info_1,  :t_info_2])
      %{character_width: 80, font_id: :ibm_vga, number_of_lines: 250}

      iex> Saucexages.MediaInfo.read_fields(%Saucexages.MediaInfo{file_type: 1, data_type: 1, t_flags: 17, t_info_1: 80, t_info_2: 250, t_info_s: "IBM VGA"}, [:t_info_s, :cheese, :data_type])
      %{font_id: :ibm_vga, data_type: 1}

  """
  @spec read_fields(t(), [atom()]) :: map()
  def read_fields(media_info, field_ids, conversion_fn \\ &read_field_value/3)
  def read_fields(media_info, field_ids, conversion_fn) do
    media_type_id = media_type_id(media_info)
    Enum.reduce(
      field_ids,
      %{},
      fn (field_id, acc) ->
        with %{^field_id => value} <- media_info,
             {k, v} <- read_field(media_type_id, field_id, value, conversion_fn) do
          Map.put(acc, k, v)
        else
          _ -> acc
        end
      end
    )
  end

  @doc """
  Reads data dynamically for a given file type based on its meta information and converts the data if possible.

  Returns a 2-tuple containing the new field id (if any) as the first element, and the field data (if any) as the second element.

  Optionally, a 3-arity conversion function that takes the same parameters, `media_type_id`, `field_type_id`, and `value` may be passed for custom conversions.

  ## Examples

      iex> Saucexages.MediaInfo.read_field(:ansi, :t_flags, 17)
      {:ansi_flags, %Saucexages.AnsiFlags{aspect_ratio: :modern, letter_spacing: :none, non_blink_mode?: true}}

      iex> Saucexages.MediaInfo.read_field(:png, :t_info_1, 640)
      {:pixel_width, 640}

  """
  @spec read_field(media_type_id(), atom(), term(), function()) :: {atom(), term()}
  def read_field(media_type_id, field_type_id, value, conversion_fn \\ &read_field_value/3)
  def read_field(media_type_id, :file_type, value, conversion_fn) when is_function(conversion_fn) do
    {:file_type, conversion_fn.(media_type_id, :file_type, value)}
  end

  for %{media_type_id: media_type_id} = mapping <- @file_type_mapping do
    def read_field(unquote(media_type_id), field_type_id, value, conversion_fn) when is_function(conversion_fn) do
      case unquote(
             mapping
             |> Macro.escape()
           ) do
        %{^field_type_id => nil} -> {field_type_id, value}
        %{^field_type_id => field_type_value} ->
          {field_type_value, conversion_fn.(unquote(media_type_id), field_type_value, value)}
        _ ->
          {field_type_id, value}
      end
    end
  end

  def read_field(_media_type_id, field_type, value, _conversion_fn) do
    {field_type, value}
  end

  defp read_field_value(_file_type, :ansi_flags, value) do
    AnsiFlags.ansi_flags(value)
  end

  defp read_field_value(_file_type, :font_id, value) do
    Font.font_id(value)
  end

  defp read_field_value(_file_type, _field_type_value, value) do
    value
  end

  @doc """
  Returns a mapped version of the t_info_1 field as a tuple containing the field type as the first element and the field value as the second element.
  """
  @spec t_info_1(t()) :: {atom, term()}
  def t_info_1(%MediaInfo{} = media_info) do
    read_media_field(media_info, :t_info_1, 0)
  end

  @doc """
  Returns a mapped version of the t_info_1 field as a tuple containing the field type as the first element and the field value as the second element.
  """
  @spec t_info_1(media_type_id(), term()) :: {atom, term()}
  def t_info_1(media_type_id, value) do
    read_field(media_type_id, :t_info_1, value)
  end

  @doc """
  Returns a mapped version of the t_info_2 field as a tuple containing the field type as the first element and the field value as the second element.
  """
  @spec t_info_2(t()) :: {atom, term()}
  def t_info_2(%MediaInfo{} = media_info) do
    read_media_field(media_info, :t_info_2, 0)
  end

  @doc """
  Returns a mapped version of the t_info_2 field as a tuple containing the field type as the first element and the field value as the second element.
  """
  @spec t_info_2(media_type_id(), term()) :: {atom, term()}
  def t_info_2(media_type_id, value) do
    read_field(media_type_id, :t_info_2, value)
  end

  @doc """
  Returns a mapped version of the t_info_3 field as a tuple containing the field type as the first element and the field value as the second element.
  """
  @spec t_info_3(t()) :: {atom, term()}
  def t_info_3(%MediaInfo{} = media_info) do
    read_media_field(media_info, :t_info_3, 0)
  end

  @doc """
  Returns a mapped version of the t_info_3 field as a tuple containing the field type as the first element and the field value as the second element.
  """
  @spec t_info_3(media_type_id(), term()) :: {atom, term()}
  def t_info_3(media_type_id, value) do
    read_field(media_type_id, :t_info_3, value)
  end

  @doc """
  Returns a mapped version of the t_info_4 field as a tuple containing the field type as the first element and the field value as the second element.
  """
  @spec t_info_4(t()) :: {atom, term()}
  def t_info_4(%MediaInfo{} = media_info) do
    read_media_field(media_info, :t_info_4, 0)
  end

  @doc """
  Returns a mapped version of the t_info_4 field as a tuple containing the field type as the first element and the field value as the second element.
  """
  @spec t_info_4(media_type_id(), term()) :: {atom, term()}
  def t_info_4(media_type_id, value) do
    read_field(media_type_id, :t_info_4, value)
  end

  @doc """
  Returns a mapped version of the t_flags field as a tuple containing the field type as the first element and the field value as the second element.
  """
  @spec t_flags(t()) :: {atom, term()}
  def t_flags(%MediaInfo{} = media_info) do
    read_media_field(media_info, :t_flags, 0)
  end

  @doc """
  Returns a mapped version of the t_flags field as a tuple containing the field type as the first element and the field value as the second element.
  """
  @spec t_flags(media_type_id(), term()) :: {atom, term()}
  def t_flags(media_type_id, value) do
    read_field(media_type_id, :t_flags, value)
  end

  @doc """
  Returns a mapped version of the t_info_s field as a tuple containing the field type as the first element and the field value as the second element.
  """
  @spec t_info_s(t()) :: {atom, term()}
  def t_info_s(%MediaInfo{} = media_info) do
    read_media_field(media_info, :t_info_s, nil)
  end

  @doc """
  Returns a mapped version of the t_info_s field as a tuple containing the field type as the first element and the field value as the second element.
  """
  @spec t_info_s(media_type_id(), term()) :: {atom, term()}
  def t_info_s(media_type_id, value) do
    read_field(media_type_id, :t_info_s, value)
  end

  @doc """
  Checks if the combination of 'file_type' and 'data_type' corresponds to a valid, known file type.

  ## Examples

      iex> Saucexages.MediaInfo.new(1, 1) |> Saucexages.MediaInfo.media_type_id?()
      true

      iex> Saucexages.MediaInfo.new(999, 5) |> Saucexages.MediaInfo.media_type_id?()
      true

      iex> Saucexages.MediaInfo.new(999, 1) |> Saucexages.MediaInfo.media_type_id?()
      false

  """
  @spec media_type_id?(t()) :: boolean()
  def media_type_id?(%MediaInfo{file_type: file_type, data_type: data_type} = _media_info) do
    media_type_id?(file_type, data_type)
  end

  def media_type_id?(_media_info) do
    false
  end

  @doc """
  Checks if the combination of 'file_type' and 'data_type' corresponds to a valid, known file type.

  ## Examples

      iex> Saucexages.MediaInfo.media_type_id?(1, 1)
      true
      iex> Saucexages.MediaInfo.media_type_id?(999, 999)
      false
      iex> Saucexages.MediaInfo.media_type_id?(999, 5)
      true
      iex> Saucexages.MediaInfo.media_type_id?(-1, 5)
      false

  """
  @spec media_type_id?(file_type(), DataType.data_type()) :: boolean()
  def media_type_id?(file_type, data_type)
  for %{file_type: file_type, data_type_id: data_type_id} <- @file_type_mapping, !is_nil(file_type) do
    data_type = DataType.data_type(data_type_id)
    def media_type_id?(unquote(file_type), unquote(data_type)) do
      true
    end
  end

  def media_type_id?(file_type, data_type) when is_binary_text(file_type, data_type) do
    #binary text
    true
  end

  def media_type_id?(_file_type, _data_type) do
    false
  end

end
