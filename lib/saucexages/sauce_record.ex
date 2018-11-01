defmodule Saucexages.SauceRecord do
  @moduledoc """
  Represents a bare SAUCE record.

  Comments are not stored in a SAUCE record, but rather the `comment_lines` field serves as a pointer of sorts to know where in a binary/file to begin reading the comment data.

  Sauce records must contain at least a `file_type` and `data_type`. These two fields are used to interpret the following fields dependent on the combination of the two: `t_info_1`, `t_info_2`, `t_info_3`, `t_info_4`, `t_flags`,`t_info_s`. Each of these fields may contain information that may not be valid for the current `file_type` and `data_type` combination.
  """

  alias __MODULE__, as: SauceRecord

  @enforce_keys [:version, :data_type, :file_type]

  @type t :: %SauceRecord{
               version: String.t,
               title: String.t | nil,
               author: String.t | nil,
               group: String.t | nil,
               date: DateTime.t | nil,
               file_size: non_neg_integer() | nil,
               data_type: non_neg_integer(),
               file_type: non_neg_integer(),
               t_info_1: non_neg_integer() | nil,
               t_info_2: non_neg_integer() | nil,
               t_info_3: non_neg_integer() | nil,
               t_info_4: non_neg_integer() | nil,
               comment_lines: non_neg_integer() | nil,
               t_flags: non_neg_integer() | nil,
               t_info_s: String.t | nil
             }

  defstruct [
    :title,
    :author,
    :group,
    :date,
    :file_size,
    :t_info_s,
    :file_type,
    :data_type,
    :t_info_1,
    :t_info_2,
    :t_info_3,
    :t_info_4,
    :t_flags,
    :comment_lines,
    :version,
  ]

  @doc """
  Creates a new SAUCE record.
  """
  @spec new(String.t(), non_neg_integer(), non_neg_integer(), Enum.t()) :: t()
  def new(version, file_type, data_type, opts \\ []) do
    struct(%__MODULE__{data_type: data_type, file_type: file_type, version: version}, opts)
  end

end
