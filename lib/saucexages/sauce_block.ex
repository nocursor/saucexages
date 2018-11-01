defmodule Saucexages.SauceBlock do
  @moduledoc """
  Represents a full SAUCE block, including both a SAUCE record and comments.

  Used for in-memory representations of SAUCE data when reading and writing SAUCE. Can also be used to extract further metadata from SAUCE data such as font information, detailed data type and file type info, flags, and more.

  Overall, a SAUCE Block serves to provide an Elixir-centric SAUCE representation and a common format and shape for working with other SAUCE related tasks and APIs. The SAUCE block stores the minimum fields for full encoding and decoding, while avoiding extra decoding or encoding steps when possible. For instance, more detailed information for file types can be obtained by using the `data_type` and `file_type` fields, but a SAUCE block avoids forcing this information on the consumer until required.

  ## Fields

  See `Saucexages.Sauce` for a full description of each field.

  The main difference in terms of fields between a SAUCE binary or SAUCE record is that the SAUCE comment block is translated and encapsulated within a SAUCE block as a `comments` field. This allows for working with comments in a more natural way as a simple list of strings. `comment_lines` is no longer required as a specific field as it can be dynamically obtained from a SAUCE block. This is done to avoid error-prone synchronization of the comment contents with the comment lines.

  The other major difference is that type dependent fields are encapsulated under `media_info`. This is to distinguish between the SAUCE spec's notion of file type (an integer field) and the conceptual grouping of fields that are dependent on the combination of data type and file type. See `Saucexages.MediaInfo` for more info.

  """

  alias __MODULE__, as: SauceBlock

  require Saucexages.Sauce
  alias Saucexages.{Sauce, SauceRecord, MediaInfo, DataType}

  @enforce_keys [:version, :media_info]

  @type t :: %SauceBlock {
               version: String.t,
               title: String.t | nil,
               author: String.t | nil,
               group: String.t | nil,
               date: DateTime.t | nil,
               media_info: MediaInfo.t(),
               comments: [String.t()],
             }

  defstruct [
    :title,
    :author,
    :group,
    :date,
    :media_info,
    comments: [],
    version: Sauce.sauce_version()
  ]

  @doc """
  Creates a new `SauceBlock` struct from a `MediaInfo` and an optional field enumerable.
  """
  @spec new(MediaInfo.t(), Enum.t()) :: t()
  def new(%MediaInfo{} = media_info, opts \\ []) do
    struct(%SauceBlock{version: Sauce.sauce_version(), media_info: media_info}, opts)
  end

  @doc """
  Creates a SAUCE block from a SAUCE record and optional list of SAUCE comments.
  """
  @spec from_sauce_record(SauceRecord.t(), [String.t()]) :: t()
  def from_sauce_record(sauce_record, sauce_comments \\ [])
  def from_sauce_record(%{version: _version, file_type: file_type, data_type: data_type} = sauce_record, sauce_comments) when is_list(sauce_comments) do
    sauce_map = sauce_record |> Map.from_struct() |> Map.put(:comments, sauce_comments)
    file_type_struct = MediaInfo.new(file_type, data_type, sauce_map)
    new(file_type_struct, sauce_map)
  end

  def from_sauce_record(_sauce_record, _sauce_comments) do
    nil
  end

  @doc """
  Calculates the number of comment lines in a SAUCE block or list of comments.
  """
  @spec comment_lines(t()) :: non_neg_integer()
  def comment_lines(%{comments: comments}) do
    do_comment_lines(comments)
  end

  @spec comment_lines([String.t()]) :: non_neg_integer()
  def comment_lines(comments) when is_list(comments) do
    do_comment_lines(comments)
  end

  defp do_comment_lines([_ | _] = comments) do
    Enum.count(comments)
  end

  defp do_comment_lines(_comments) do
    0
  end

  @doc """
  Returns a formatted version of comment lines using the given separator between comment lines.

  ## Examples

      iex> Saucexages.SauceBlock.formatted_comments(["200 lines of blood", "80 columns of sweat"], ", ")
      "200 lines of blood, 80 columns of sweat"

  """
  @spec formatted_comments(t(), String.t()) :: String.t()
  def formatted_comments(sauce_block, separator \\ "\n")
  def formatted_comments(%{comments: comments}, separator) when is_list(comments) do
    do_format_comments(comments, separator)
  end

  @spec formatted_comments([String.t()], String.t()) :: String.t()
  def formatted_comments(comments, separator) when is_list(comments) do
    do_format_comments(comments, separator)
  end

  def do_format_comments(comments, separator) do
    Enum.join(comments, separator)
  end

  @doc """
  Adds a comment to the beginning of the of the SAUCE comments.
  """
  @spec prepend_comment(t(), String.t()) :: t()
  def prepend_comment(%SauceBlock{} = sauce_block, comment) when is_binary(comment) do
    case sauce_block do
      %{:comments => [_ | _] = comments} ->
        %{sauce_block | comments: [comment | comments]}
      _ ->
        Map.put(sauce_block, :comments, [comment])
    end
  end

  @doc """
  Adds comments to a SAUCE block.
  """
  @spec add_comments(t(), [String.t()] | String.t()) :: t()
  def add_comments(sauce_block, comments)
  def add_comments(%SauceBlock{} = sauce_block, comments) when is_list(comments) do
    case sauce_block do
      %{:comments => [_ | _] = existing_comments} ->
        %{sauce_block | comments: Enum.into(comments, existing_comments)}
      _ ->
        Map.put(sauce_block, :comments, comments)
    end
  end

  def add_comments(%SauceBlock{} = sauce_block, comment) when is_binary(comment) do
    add_comments(sauce_block, [comment])
  end

  @doc """
  Removes all comments from a SAUCE block.
  """
  @spec clear_comments(t()) :: t()
  def clear_comments(%SauceBlock{} = sauce_block) do
    Map.put(sauce_block, :comments, [])
  end

  @doc """
  Returns the `media_type_id` for the given SAUCE block.
  """
  @spec media_type_id(t()) :: MediaInfo.media_type_id()
  def media_type_id(%{media_info: %{file_type: file_type, data_type: data_type}}) do
    MediaInfo.media_type_id(file_type, data_type)
  end

  @doc """
  Returns the `data_type_id` for the given SAUCE block.
  """
  @spec data_type_id(t()) :: DataType.data_type_id()
  def data_type_id(%{media_info: %{data_type: data_type}}) do
    DataType.data_type_id(data_type)
  end

  @doc """
  Returns a detailed map of any file type info that can be converted per-file type. Only the detailed information is returned.

  Useful for editors or specialized processing.

  ## Examples

      iex> sauce_block = %Saucexages.SauceBlock{version: "00", media_info: %{file_type: 1, data_type: 1, t_flags: 17, t_info_1: 80, t_info_2: 250, t_info_s: "IBM VGA"}}
      iex> Saucexages.SauceBlock.media_details(sauce_block)
      %{
        ansi_flags: %Saucexages.AnsiFlags{
          aspect_ratio: :modern,
          letter_spacing: :none,
          non_blink_mode?: true
        },
        character_width: 80,
        data_type: 1,
        file_type: 1,
        font_id: :ibm_vga,
        number_of_lines: 250
      }

  """
  @spec media_details(t()) :: map()
  def media_details(%SauceBlock{media_info: media_info} = _sauce_block) do
    MediaInfo.media_details(media_info)
  end

  @doc """
  Returns a detailed map of all SAUCE block data.

  Useful for editors or specialized processing.

  ## Examples

      iex> sauce_block = %Saucexages.SauceBlock{version: "00", title: "cheese platter", author: "No Cursor", group: "Inconsequential",  date: ~D[1994-01-01],  media_info: %{file_type: 1, data_type: 1, t_flags: 17, t_info_1: 80, t_info_2: 250, t_info_s: "IBM VGA"}}
      iex> Saucexages.SauceBlock.details(sauce_block)
      %{
      ansi_flags: %Saucexages.AnsiFlags{
        aspect_ratio: :modern,
        letter_spacing: :none,
        non_blink_mode?: true
      },
      author: "No Cursor",
      character_width: 80,
      comments: [],
      data_type: 1,
      data_type_id: :character,
      date: ~D[1994-01-01],
      file_type: 1,
      font_id: :ibm_vga,
      group: "Inconsequential",
      media_type_id: :ansi,
      name: "ANSi",
      number_of_lines: 250,
      title: "cheese platter",
      version: "00"
      }

  """
  @spec details(t()) :: map()
  def details(%SauceBlock{media_info: media_info} = sauce_block) do
    block_details = Map.take(sauce_block, [:title, :author, :group, :date, :comments, :version])
    MediaInfo.details(media_info) |> Map.merge(block_details)
  end

  @doc """
  Returns a mapped version of the t_info_1 field as a tuple containing the field type as the first element and the field value as the second element.
  """
  @spec t_info_1(t()) :: {atom, term()}
  def t_info_1(%SauceBlock{media_info: media_info} = _sauce_block) do
    MediaInfo.t_info_1(media_info)
  end

  @doc """
  Returns a mapped version of the t_info_2 field as a tuple containing the field type as the first element and the field value as the second element.
  """
  @spec t_info_2(t()) :: {atom, term()}
  def t_info_2(%SauceBlock{media_info: media_info} = _sauce_block) do
    MediaInfo.t_info_2(media_info)
  end

  @doc """
  Returns a mapped version of the t_info_3 field as a tuple containing the field type as the first element and the field value as the second element.
  """
  @spec t_info_3(t()) :: {atom, term()}
  def t_info_3(%SauceBlock{media_info: media_info} = _sauce_block) do
    MediaInfo.t_info_3(media_info)
  end

  @doc """
  Returns a mapped version of the t_info_4 field as a tuple containing the field type as the first element and the field value as the second element.
  """
  @spec t_info_4(t()) :: {atom, term()}
  def t_info_4(%SauceBlock{media_info: media_info} = _sauce_block) do
    MediaInfo.t_info_4(media_info)
  end

  @doc """
  Returns a mapped version of the t_flags field as a tuple containing the field type as the first element and the field value as the second element.
  """
  @spec t_flags(t()) :: {atom, term()}
  def t_flags(%SauceBlock{media_info: media_info} = _sauce_block) do
    MediaInfo.t_flags(media_info)
  end

  @doc """
  Returns a mapped version of the t_info_s field as a tuple containing the field type as the first element and the field value as the second element.
  """
  @spec t_info_s(t()) :: {atom, term()}
  def t_info_s(%SauceBlock{media_info: media_info} = _sauce_block) do
    MediaInfo.t_info_s(media_info)
  end

  @doc """
  Returns the type handle for the given SAUCE block. A type handle consists of a tuple of `{file_type, data_type}`, where there is a valid mapping between the two. Invalid types will be coerced to a type handle for `:none` by default.
  """
  @spec type_handle(t()) :: MediaInfo.type_handle()
  def type_handle(sauce_block) do
    media_type_id(sauce_block) |> MediaInfo.type_handle()
  end

end
