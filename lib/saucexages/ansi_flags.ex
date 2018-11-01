defmodule Saucexages.AnsiFlags do
  @moduledoc """
  ANSiFlags allow an author of ANSi and similar files to provide a clue to a viewer / editor how to render the image.

  ANSiFlags use the following binary layout:

  `<<0, 0, 0, aspect_ratio::2, letter_spacing::2, non_blink_mode::1>>`

  ## Aspect ratio

  Most modern display devices have square pixels, but that has not always been the case. Displaying an ANSI file that was created for one of the older devices on a device with square pixels will vertically compress the image slightly. This can be compensated for by either taking a font that is slightly taller than was used on the legacy device, or by stretching the rendered image.

  These 2 bits can be used to signal that the image was created with square pixels in mind, or that it was created for a legacy device with the elongated pixels.

  The following values are used to represent decoded aspect ratio flags with respect to image display preferences:

  * `:none` - Legacy value. No preference.
  * `:legacy` - Image was created for a legacy device. When displayed on a device with square pixels, either the font or the image needs to be stretched.
  * `:modern` - Image was created for a modern device with square pixels. No stretching is desired on a device with square pixels.
  * `:invalid` - Not currently a valid value. This is used to represent an invalid state such as when both aspect ratio bits are set.

  ## Letter Spacing

  Letter-spacing for font selection.

  Fixed-width text mode as used in DOS and early graphics based computers such as the Amiga used bitmap fonts to display text. Letter-spacing and line spacing is a part of the font bitmap, so the font box inside each bitmap was a bit smaller than the font bitmap.

  For the VGA, IBM wanted a smoother font. 2 more lines were added, and the letter-spacing was removed from the font and instead inserted by the VGA hardware during display. All 8 pixels in the font could thus be used, and still have a 1 pixel letter spacing. For the line graphics characters, this was a problem because they needed to match up with their neighbours on both sides. The VGA hardware was wired to duplicate the 8th column of the font bitmap for the character range C0h to DFh. In some code pages was undesired, so this feature could be turned off to get an empty letter spacing on all characters as well (via the ELG field (Enable Line Graphics Character Codes) in the Mode Control register (10h) of the VGA Attribute Controller (3C0h).

  While the VGA allows you to enable or disable the 8th column duplication, there is no way to specify which range of characters this needs to be done for, the C0h to DFh range is hardwired into the VGA. These 2 bits can be used to select the 8 pixel or 9 pixel variant of a particular font.

  The following values are used to represent decoded letter-spacing flags:

  `:none` - Legacy value. No preference.
  `:eight_pixel_font` - Select 8 pixel font.
  `:nine_pixel_font` - Select 9 pixel font.
  `invalid` - Not currently a valid value.

  Changing the font width and wanting to remain at 80 characters per row means that you need to adjust for a change in horizontal resolution (from 720 pixels to 640 or vice versa). When you are trying to match the original aspect ratio (see the AR bits), you will need to adjust the vertical stretching accordingly.

  Only the VGA (and the Hercules) video cards actually supported fonts 9 pixels wide. SAUCE does not prevent you from specifying you want a 9 pixel wide font for a font that technically was never used that way. Note that duplicating the 8th column on non-IBM fonts (and even some code pages for IBM fonts) may not give the desired effect.
  Some people like the 9 pixel fonts, some do not because it causes a visible break in the 3 ‘shadow blocks’ (B0h, B1h and B2h)

  ## Non-blink Mode (iCE Color)

  When 0, only the 8 low intensity colors are supported for the character background. The high bit set to 1 in each attribute byte results in the foreground color blinking repeatedly.

  When 1, all 16 colors are supported for the character background. The high bit set to 1 in each attribute byte selects the high intensity color instead of blinking.

  The following values are used to represent a decode non-blink mode flag:

  * `true` - All 16 color support for character backgrounds, i.e. iCE Color
  * `false` - Only 8 low intensity colors for character backgrounds, i.e. iCE Color is *not* supported.

  ## Source

  The content in these docs was adapted from the following source:

  * [Sauce SPEC - ANSI Flags](http://www.acid.org/info/sauce/sauce.htm#ANSiFlags)
  """

  alias __MODULE__, as: AnsiFlags

  @type ansi_flags :: integer() | binary()
  @type aspect_ratio :: :none | :legacy | :modern | :invalid
  @type letter_spacing :: :none | :eight_pixel_font | :nine_pixel_font | :invalid
  @type t :: %__MODULE__{
               aspect_ratio: aspect_ratio(),
               letter_spacing: letter_spacing(),
               non_blink_mode?: boolean()
             }

  defstruct [:aspect_ratio, :letter_spacing, :non_blink_mode?]

  aspect_ratio_flag_items = [{:none, 0, 0}, {:legacy, 0, 1}, {:modern, 1, 0}, {:invalid, 1, 1}]
  letter_spacing_flag_items = [{:none, 0, 0}, {:eight_pixel_font, 0, 1}, {:nine_pixel_font, 1, 0}, {:invalid, 1, 1}]
  non_blink_mode_flag_items = [{false, 0}, {true, 1}]


  @doc """
  Decodes and returns human-readable ansi flags, as specified in the given ANSi flags.

  ## Examples

      iex> Saucexages.AnsiFlags.ansi_flags(0)
      %Saucexages.AnsiFlags{
      aspect_ratio: :none,
      letter_spacing: :none,
      non_blink_mode?: false
      }

      iex> Saucexages.AnsiFlags.ansi_flags(17)
      %Saucexages.AnsiFlags{
      aspect_ratio: :modern,
      letter_spacing: :none,
      non_blink_mode?: true
      }

      iex> Saucexages.AnsiFlags.ansi_flags(2)
      %Saucexages.AnsiFlags{
      aspect_ratio: :none,
      letter_spacing: :eight_pixel_font,
      non_blink_mode?: false
      }

      iex>  Saucexages.AnsiFlags.ansi_flags(5)
      %Saucexages.AnsiFlags{
      aspect_ratio: :none,
      letter_spacing: :nine_pixel_font,
      non_blink_mode?: true
      }

  """
  @spec ansi_flags(ansi_flags()) :: t()
  def ansi_flags(t_flags)
  for {aspect_ratio, ar_hi, ar_lo} <- aspect_ratio_flag_items, {letter_spacing, ls_hi, ls_lo} <- letter_spacing_flag_items, {non_blink_mode?, nb_flag} <- non_blink_mode_flag_items do
    def ansi_flags(<<_ :: 3, unquote(ar_hi) :: 1, unquote(ar_lo) :: 1, unquote(ls_hi) :: 1, unquote(ls_lo) :: 1, unquote(nb_flag) :: 1>> = t_flags) when is_binary(t_flags) do
      %AnsiFlags {
        aspect_ratio: unquote(aspect_ratio),
        letter_spacing: unquote(letter_spacing),
        non_blink_mode?: unquote(non_blink_mode?)
      }
    end
  end

  def ansi_flags(t_flags) when is_integer(t_flags) do
    to_binary(t_flags)
    |> ansi_flags()
  end

  @doc """
  Returns the aspect ratio to be used for display as specified in the given ANSi flags.

  ## Examples

      iex> Saucexages.AnsiFlags.aspect_ratio(<<16>>)
      :modern

      iex> Saucexages.AnsiFlags.aspect_ratio(1)
      :none

      iex> Saucexages.AnsiFlags.aspect_ratio(8)
      :legacy

      iex> Saucexages.AnsiFlags.aspect_ratio(16)
      :modern

  """
  @spec aspect_ratio(ansi_flags()) :: aspect_ratio()
  def aspect_ratio(t_flags)
  for {aspect_ratio, ar_hi, ar_lo} <- aspect_ratio_flag_items do
    def aspect_ratio(<<_ :: 3, unquote(ar_hi) :: 1, unquote(ar_lo) :: 1, _ :: 3>> = t_flags) when is_binary(t_flags) do
      #	00: Legacy value. No preference.
      # 01: Image was created for a legacy device. When displayed on a device with square pixels, either the font or the image needs to be stretched.
      # 10: Image was created for a modern device with square pixels. No stretching is desired on a device with square pixels.
      # 11: Not currently a valid value
      unquote(aspect_ratio)
    end
  end

  def aspect_ratio(t_flags) when is_integer(t_flags) do
    to_binary(t_flags)
    |> aspect_ratio()
  end

  @doc """
  Returns the letter spacing as specified in the given ANSi flags to be used for fonts.

  ## Examples

      iex> Saucexages.AnsiFlags.letter_spacing(<<2>>)
      :eight_pixel_font

      iex> Saucexages.AnsiFlags.letter_spacing(11)
      :eight_pixel_font

      iex> Saucexages.AnsiFlags.letter_spacing(12)
      :nine_pixel_font

      iex> Saucexages.AnsiFlags.letter_spacing(14)
      :invalid

  """
  @spec letter_spacing(ansi_flags()) :: letter_spacing()
  def letter_spacing(t_flags)
  for {letter_spacing, ls_hi, ls_lo} <- letter_spacing_flag_items do
    def letter_spacing(<<_ :: 5, unquote(ls_hi) :: 1, unquote(ls_lo) :: 1, _ :: 1>> = t_flags) when is_binary(t_flags) do
      #	00: Legacy value. No preference.
      # 01: Select 8 pixel font.
      # 10: Select 9 pixel font.
      # 11: Not currently a valid value.
      unquote(letter_spacing)
    end
  end

  def letter_spacing(t_flags) when is_integer(t_flags) do
    to_binary(t_flags)
    |> letter_spacing()
  end

  @doc """
  Returns whether or not non-blink mode (iCE Colors) are set in the given ANSi flags.

  `true` - Use non-blink mode.
  `false` - Do not use non-blink mode, use 8 background colors.

  ## Examples

      iex> Saucexages.AnsiFlags.non_blink_mode?(<<16>>)
      false

      iex> Saucexages.AnsiFlags.non_blink_mode?(<<17>>)
      true

      iex> Saucexages.AnsiFlags.non_blink_mode?(16)
      false

      iex> Saucexages.AnsiFlags.non_blink_mode?(17)
      true

  """
  @spec non_blink_mode?(ansi_flags()) :: boolean()
  def non_blink_mode?(t_flags)
  for {non_blink_mode?, nb_flag} <- non_blink_mode_flag_items do
    def non_blink_mode?(<<_ :: 7, unquote(nb_flag) :: 1>> = t_flags) when is_binary(t_flags) do
      unquote(non_blink_mode?)
    end
  end

  def non_blink_mode?(t_flags) when is_binary(t_flags) do
    false
  end

  def non_blink_mode?(t_flags) when is_integer(t_flags) do
    to_binary(t_flags)
    |> non_blink_mode?()
  end

  @doc """
  Converts an integer t_flags value to binary.
  """
  @spec to_binary(integer()) :: binary()
  def to_binary(t_flags) when is_integer(t_flags) do
    <<t_flags :: little - unsigned - integer - unit(8) - size(1)>>
  end

  @doc """
  Converts a binary t_flags value to an integer.
  """
  @spec to_integer(binary()) :: integer()
  def to_integer(<<flag_value :: little - unsigned - integer - unit(8) - size(1)>> = t_flags) when is_binary(t_flags) do
    flag_value
  end

  def to_integer(t_flags) when is_binary(t_flags) do
    raise ArgumentError, "ANSi flags must be specified as a single byte representing a binary little unsigned integer."
  end

end
