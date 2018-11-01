defmodule Saucexages.FontEncoding do
  @moduledoc false

  alias __MODULE__, as: FontEncoding

  defstruct [:encoding_id, :encoding_name, :friendly_name]

  @type encoding_id() :: atom()
  @type t :: %FontEncoding {
               encoding_id: atom(),
               encoding_name: String.t(),
               friendly_name: String.t()
             }

end

defmodule Saucexages.FontProperties do
  @moduledoc false

  alias __MODULE__, as: FontProperties

  defstruct [:font_size, :resolution, :display, :pixel_ratio, :vertical_stretch]

  @type font_id :: atom()
  @type font_size :: {pos_integer(), pos_integer()}
  @type resolution :: {pos_integer(), pos_integer()}
  @type ratio :: {pos_integer(), pos_integer()}

  @type t :: %FontProperties{
               font_size: font_size(),
               resolution: resolution(),
               display: ratio(),
               pixel_ratio: ratio(),
               vertical_stretch: float()
             }
end

defmodule Saucexages.FontInfo do
  @moduledoc false

  alias __MODULE__, as: FontInfo
  alias Saucexages.FontEncoding

  defstruct [:font_id, :font_name, :encoding_id]

  @type t :: %FontInfo{
               font_id: atom(),
               font_name: String.t(),
               encoding_id: FontEncoding.encoding_id(),
             }
end


defmodule Saucexages.FontOption do
  @moduledoc false

  # Maps font properties to a font id to uniquely identify properties for each font.

  alias __MODULE__, as: FontOption
  alias Saucexages.FontProperties

  defstruct [:font_id, :properties]

  @type t :: %FontOption{
               font_id: atom(),
                properties: FontProperties.t()
             }

end

defmodule Saucexages.SauceFont do
  @moduledoc false

  # Represents a SAUCE record font and its properties mapped by its id.

  alias __MODULE__, as: SauceFont
  alias Saucexages.{FontProperties}

  defstruct [:font_id, :font_name, :encoding_id, :font_size, :resolution, :display, :pixel_ratio, :vertical_stretch]

  @type encoding_id :: :cp437 | :cp720 | :cp737 | :cp775 | :cp819 | :cp850 | :cp852 | :cp855 | :cp857 | :cp860 |
    :cp861 | :cp862 | :cp863 | :cp864 | :cp865 | :cp866 | :cp869 | :cp872 | :kam | :cp867 |
    :cp895 | :maz | :cp667 | :cp790 | :mik

  # closed set of strings according to SAUCE spec
  @type font_name :: String.t()

  @type font_id :: FontProperties.font_id()
  @type font_size :: FontProperties.font_size()
  @type resolution :: FontProperties.resolution()
  @type ratio :: FontProperties.ratio()
  @type t :: %SauceFont{
               font_id: font_id(),
               font_name: font_name(),
               encoding_id: encoding_id(),
               font_size: font_size,
               resolution: resolution(),
               display: ratio(),
               pixel_ratio: ratio(),
               vertical_stretch: float(),
             }

  def new(%_{} = font_info, %_{} = font_properties) do
    font_map = Map.merge(
      font_info
      |> Map.from_struct(),
      font_properties
      |> Map.from_struct()
    )
    struct(SauceFont, font_map)
  end

  def new(%{font_id: font_id, font_name: font_name, encoding_id: encoding_id}, %{font_size: font_size, resolution: resolution, display: display, pixel_ratio: pixel_ratio, vertical_stretch: vertical_stretch}) do
    %SauceFont{font_id: font_id, font_name: font_name, encoding_id: encoding_id, font_size: font_size, resolution: resolution, display: display, pixel_ratio: pixel_ratio, vertical_stretch: vertical_stretch}
  end

end

defmodule Saucexages.Font do
  @moduledoc """
  Module used for working with font data embedded into certain SAUCE types.

  The primary use-cases of this module are to help with building interfaces, displaying SAUCE file data, and to help with analysis of SAUCE data.

  A more specific common-use case for instance is a viewer app may wish to know how to display a particular piece of ANSi or ASCII art. One of the primary purposes of SAUCE was to facilitate such a case by conveying the author's intentions. For example, spacing or pixel properties may look incorrect on many settings, or the character set used may be off-putting using the OS or user default.

  ## Working with Fonts

  SAUCE embeds various information via the presence of a `font name`, for example "IBM VGA". This name correlates to a number of combinations of settings depending on the viewer's preference and capabilities. Interpreting this information prevents incorrect display and helps viewers more closely match the original intention. This information can be used to upgrade, transition and/or adapt media display accordingly (ex: fallback fonts). Another use for this information is to do things such as answer questions - ex: "How much of this artwork was intended for Amiga fonts?" or "Which ANSI artwork do I own that I should not display in the common `cp437` encoding?"

  ## Why Decode Fonts

  Most SAUCE libraries simply choose to return just the font name. Saucexages instead chooses to allow API consumers to get more info about the encoded information, rather than to yet again defer to another library or force the consumer to re-implement the SAUCE spec. In other words, the intention is to provide a single abstraction that is data-driven which programmers can leverage to "get things done."

  In real-world terms, the neglect of font information and other metadata has lead to buggy viewers, inconsistent experiences, and outright failures handling media. Although many files in the wild lack the proper font information regardless, it is surprisingly easy to re-write this information and correct these mistakes. For example, many major art groups relied on IBM VGA-based fonts. Ascii groups by contrast often also used Amiga fonts. Even when this information cannot be inferred per-group, many authors have actually written their display preferences inside the art itself. With some patience and time, Saucexages can be used to fix artwork so it displays properly.

  Simply put, Saucexages gives you the tools you need to fix your artwork and display it right instead of making it someone else's job who doesn't' exist.
  """

  alias Saucexages.{FontInfo, FontEncoding, FontOption, FontProperties, SauceFont}

  @type font_id :: SauceFont.font_id()
  @type font_name :: SauceFont.font_name()
  @type font_size :: SauceFont.font_size()
  @type ratio :: SauceFont.font_size()
  @type encoding_id :: FontEncoding.encoding_id()

  @supported_encodings [
    %FontEncoding{encoding_id: :cp437, encoding_name: "437", friendly_name: "MS-DOS Latin US"},
    %FontEncoding{encoding_id: :cp720, encoding_name: "720", friendly_name: "Windows-1256"},
    %FontEncoding{encoding_id: :cp737, encoding_name: "737", friendly_name: "MS-DOS Greek"},
    %FontEncoding{encoding_id: :cp775, encoding_name: "775", friendly_name: "MS-DOS Baltic Rim"},
    %FontEncoding{encoding_id: :cp819, encoding_name: "819", friendly_name: "ISO/IEC 8859-1"},
    %FontEncoding{encoding_id: :cp850, encoding_name: "850", friendly_name: "MS-DOS Latin 1"},
    %FontEncoding{encoding_id: :cp852, encoding_name: "852", friendly_name: "MS-DOS Latin 2"},
    %FontEncoding{encoding_id: :cp855, encoding_name: "855", friendly_name: "MS-DOS Cyrillic"},
    %FontEncoding{encoding_id: :cp857, encoding_name: "857", friendly_name: "MS-DOS Turkish"},
    %FontEncoding{encoding_id: :cp860, encoding_name: "860", friendly_name: "MS-DOS Portuguese"},
    %FontEncoding{encoding_id: :cp861, encoding_name: "861", friendly_name: "MS-DOS Icelandic"},
    %FontEncoding{encoding_id: :cp862, encoding_name: "862", friendly_name: "MS-DOS Hebrew"},
    %FontEncoding{encoding_id: :cp863, encoding_name: "863", friendly_name: "MS-DOS French Canada"},
    %FontEncoding{encoding_id: :cp864, encoding_name: "864", friendly_name: "Arabic"},
    %FontEncoding{encoding_id: :cp865, encoding_name: "865", friendly_name: "Nordic"},
    %FontEncoding{encoding_id: :cp866, encoding_name: "866", friendly_name: "Cyrillic"},
    %FontEncoding{encoding_id: :cp869, encoding_name: "869", friendly_name: "MS-DOS Greek 2"},
    %FontEncoding{encoding_id: :cp872, encoding_name: "872", friendly_name: "Cyrillic"},
    %FontEncoding{encoding_id: :kam, encoding_name: "KAM", friendly_name: "Kamenický"},
    %FontEncoding{encoding_id: :cp867, encoding_name: "867", friendly_name: "Kamenický"},
    %FontEncoding{encoding_id: :cp895, encoding_name: "895", friendly_name: "Kamenický"},
    %FontEncoding{encoding_id: :maz, encoding_name: "MAZ", friendly_name: "Mazovia"},
    %FontEncoding{encoding_id: :cp667, encoding_name: "667", friendly_name: "Mazovia"},
    %FontEncoding{encoding_id: :cp790, encoding_name: "790", friendly_name: "Mazovia"},
    %FontEncoding{encoding_id: :mik, encoding_name: "MIK", friendly_name: "Cyrillic"},
  ]

  @groupable_font_ids [:ibm_vga, :ibm_vga50, :ibm_vga25g, :ibm_ega, :ibm_ega43]

  @default_fonts    [
    %FontInfo{font_id: :amiga_topaz_1, font_name: "Amiga Topaz 1", encoding_id: :amiga},
    %FontInfo{font_id: :amiga_topaz_1_plus, font_name: "Amiga Topaz 1+", encoding_id: :amiga},
    %FontInfo{font_id: :amiga_topaz_2, font_name: "Amiga Topaz 2", encoding_id: :amiga},
    %FontInfo{font_id: :amiga_topaz_2_plus, font_name: "Amiga Topaz 2+", encoding_id: :amiga},
    %FontInfo{font_id: :amiga_pot_noodle, font_name: "Amiga P0T-NOoDLE", encoding_id: :amiga},
    %FontInfo{font_id: :amiga_micro_knight, font_name: "Amiga MicroKnight", encoding_id: :amiga},
    %FontInfo{font_id: :amiga_micro_knight_plus, font_name: "Amiga MicroKnight+", encoding_id: :amiga},
    %FontInfo{font_id: :amiga_mo_soul, font_name: "Amiga mOsOul", encoding_id: :amiga},

    %FontInfo{font_id: :c64_petscii_unshifted, font_name: "C64 PETSCII unshifted", encoding_id: :c64},
    %FontInfo{font_id: :c64_petscii_shifted, font_name: "C64 PETSCII shifted", encoding_id: :c64},

    %FontInfo{font_id: :atari_atascii, font_name: "Atari ATASCII", encoding_id: :atari},

    %FontInfo{font_id: :ibm_vga, font_name: "IBM VGA", encoding_id: :cp437},
    %FontInfo{font_id: :ibm_vga50, font_name: "IBM VGA50", encoding_id: :cp437},
    %FontInfo{font_id: :ibm_vga25g, font_name: "IBM VGA25G", encoding_id: :cp437},
    %FontInfo{font_id: :ibm_ega, font_name: "IBM EGA", encoding_id: :cp437},
    %FontInfo{font_id: :ibm_ega43, font_name: "IBM EGA43", encoding_id: :cp437},
    %FontInfo{
      encoding_id: :cp437,
      font_id: :ibm_vga50_cp437,
      font_name: "IBM VGA50 437"
    },
    %FontInfo{
      encoding_id: :cp720,
      font_id: :ibm_vga50_cp720,
      font_name: "IBM VGA50 720"
    },
    %FontInfo{
      encoding_id: :cp737,
      font_id: :ibm_vga50_cp737,
      font_name: "IBM VGA50 737"
    },
    %FontInfo{
      encoding_id: :cp775,
      font_id: :ibm_vga50_cp775,
      font_name: "IBM VGA50 775"
    },
    %FontInfo{
      encoding_id: :cp819,
      font_id: :ibm_vga50_cp819,
      font_name: "IBM VGA50 819"
    },
    %FontInfo{
      encoding_id: :cp850,
      font_id: :ibm_vga50_cp850,
      font_name: "IBM VGA50 850"
    },
    %FontInfo{
      encoding_id: :cp852,
      font_id: :ibm_vga50_cp852,
      font_name: "IBM VGA50 852"
    },
    %FontInfo{
      encoding_id: :cp855,
      font_id: :ibm_vga50_cp855,
      font_name: "IBM VGA50 855"
    },
    %FontInfo{
      encoding_id: :cp857,
      font_id: :ibm_vga50_cp857,
      font_name: "IBM VGA50 857"
    },
    %FontInfo{
      encoding_id: :cp860,
      font_id: :ibm_vga50_cp860,
      font_name: "IBM VGA50 860"
    },
    %FontInfo{
      encoding_id: :cp861,
      font_id: :ibm_vga50_cp861,
      font_name: "IBM VGA50 861"
    },
    %FontInfo{
      encoding_id: :cp862,
      font_id: :ibm_vga50_cp862,
      font_name: "IBM VGA50 862"
    },
    %FontInfo{
      encoding_id: :cp863,
      font_id: :ibm_vga50_cp863,
      font_name: "IBM VGA50 863"
    },
    %FontInfo{
      encoding_id: :cp864,
      font_id: :ibm_vga50_cp864,
      font_name: "IBM VGA50 864"
    },
    %FontInfo{
      encoding_id: :cp865,
      font_id: :ibm_vga50_cp865,
      font_name: "IBM VGA50 865"
    },
    %FontInfo{
      encoding_id: :cp866,
      font_id: :ibm_vga50_cp866,
      font_name: "IBM VGA50 866"
    },
    %FontInfo{
      encoding_id: :cp869,
      font_id: :ibm_vga50_cp869,
      font_name: "IBM VGA50 869"
    },
    %FontInfo{
      encoding_id: :cp872,
      font_id: :ibm_vga50_cp872,
      font_name: "IBM VGA50 872"
    },
    %FontInfo{
      encoding_id: :kam,
      font_id: :ibm_vga50_kam,
      font_name: "IBM VGA50 KAM"
    },
    %FontInfo{
      encoding_id: :cp867,
      font_id: :ibm_vga50_cp867,
      font_name: "IBM VGA50 867"
    },
    %FontInfo{
      encoding_id: :cp895,
      font_id: :ibm_vga50_cp895,
      font_name: "IBM VGA50 895"
    },
    %FontInfo{
      encoding_id: :maz,
      font_id: :ibm_vga50_maz,
      font_name: "IBM VGA50 MAZ"
    },
    %FontInfo{
      encoding_id: :cp667,
      font_id: :ibm_vga50_cp667,
      font_name: "IBM VGA50 667"
    },
    %FontInfo{
      encoding_id: :cp790,
      font_id: :ibm_vga50_cp790,
      font_name: "IBM VGA50 790"
    },
    %FontInfo{
      encoding_id: :mik,
      font_id: :ibm_vga50_mik,
      font_name: "IBM VGA50 MIK"
    },
    %FontInfo{
      encoding_id: :cp437,
      font_id: :ibm_vga_cp437,
      font_name: "IBM VGA 437"
    },
    %FontInfo{
      encoding_id: :cp720,
      font_id: :ibm_vga_cp720,
      font_name: "IBM VGA 720"
    },
    %FontInfo{
      encoding_id: :cp737,
      font_id: :ibm_vga_cp737,
      font_name: "IBM VGA 737"
    },
    %FontInfo{
      encoding_id: :cp775,
      font_id: :ibm_vga_cp775,
      font_name: "IBM VGA 775"
    },
    %FontInfo{
      encoding_id: :cp819,
      font_id: :ibm_vga_cp819,
      font_name: "IBM VGA 819"
    },
    %FontInfo{
      encoding_id: :cp850,
      font_id: :ibm_vga_cp850,
      font_name: "IBM VGA 850"
    },
    %FontInfo{
      encoding_id: :cp852,
      font_id: :ibm_vga_cp852,
      font_name: "IBM VGA 852"
    },
    %FontInfo{
      encoding_id: :cp855,
      font_id: :ibm_vga_cp855,
      font_name: "IBM VGA 855"
    },
    %FontInfo{
      encoding_id: :cp857,
      font_id: :ibm_vga_cp857,
      font_name: "IBM VGA 857"
    },
    %FontInfo{
      encoding_id: :cp860,
      font_id: :ibm_vga_cp860,
      font_name: "IBM VGA 860"
    },
    %FontInfo{
      encoding_id: :cp861,
      font_id: :ibm_vga_cp861,
      font_name: "IBM VGA 861"
    },
    %FontInfo{
      encoding_id: :cp862,
      font_id: :ibm_vga_cp862,
      font_name: "IBM VGA 862"
    },
    %FontInfo{
      encoding_id: :cp863,
      font_id: :ibm_vga_cp863,
      font_name: "IBM VGA 863"
    },
    %FontInfo{
      encoding_id: :cp864,
      font_id: :ibm_vga_cp864,
      font_name: "IBM VGA 864"
    },
    %FontInfo{
      encoding_id: :cp865,
      font_id: :ibm_vga_cp865,
      font_name: "IBM VGA 865"
    },
    %FontInfo{
      encoding_id: :cp866,
      font_id: :ibm_vga_cp866,
      font_name: "IBM VGA 866"
    },
    %FontInfo{
      encoding_id: :cp869,
      font_id: :ibm_vga_cp869,
      font_name: "IBM VGA 869"
    },
    %FontInfo{
      encoding_id: :cp872,
      font_id: :ibm_vga_cp872,
      font_name: "IBM VGA 872"
    },
    %FontInfo{
      encoding_id: :kam,
      font_id: :ibm_vga_kam,
      font_name: "IBM VGA KAM"
    },
    %FontInfo{
      encoding_id: :cp867,
      font_id: :ibm_vga_cp867,
      font_name: "IBM VGA 867"
    },
    %FontInfo{
      encoding_id: :cp895,
      font_id: :ibm_vga_cp895,
      font_name: "IBM VGA 895"
    },
    %FontInfo{
      encoding_id: :maz,
      font_id: :ibm_vga_maz,
      font_name: "IBM VGA MAZ"
    },
    %FontInfo{
      encoding_id: :cp667,
      font_id: :ibm_vga_cp667,
      font_name: "IBM VGA 667"
    },
    %FontInfo{
      encoding_id: :cp790,
      font_id: :ibm_vga_cp790,
      font_name: "IBM VGA 790"
    },
    %FontInfo{
      encoding_id: :mik,
      font_id: :ibm_vga_mik,
      font_name: "IBM VGA MIK"
    },
    %FontInfo{
      encoding_id: :cp437,
      font_id: :ibm_vga25g_cp437,
      font_name: "IBM VGA25G 437"
    },
    %FontInfo{
      encoding_id: :cp720,
      font_id: :ibm_vga25g_cp720,
      font_name: "IBM VGA25G 720"
    },
    %FontInfo{
      encoding_id: :cp737,
      font_id: :ibm_vga25g_cp737,
      font_name: "IBM VGA25G 737"
    },
    %FontInfo{
      encoding_id: :cp775,
      font_id: :ibm_vga25g_cp775,
      font_name: "IBM VGA25G 775"
    },
    %FontInfo{
      encoding_id: :cp819,
      font_id: :ibm_vga25g_cp819,
      font_name: "IBM VGA25G 819"
    },
    %FontInfo{
      encoding_id: :cp850,
      font_id: :ibm_vga25g_cp850,
      font_name: "IBM VGA25G 850"
    },
    %FontInfo{
      encoding_id: :cp852,
      font_id: :ibm_vga25g_cp852,
      font_name: "IBM VGA25G 852"
    },
    %FontInfo{
      encoding_id: :cp855,
      font_id: :ibm_vga25g_cp855,
      font_name: "IBM VGA25G 855"
    },
    %FontInfo{
      encoding_id: :cp857,
      font_id: :ibm_vga25g_cp857,
      font_name: "IBM VGA25G 857"
    },
    %FontInfo{
      encoding_id: :cp860,
      font_id: :ibm_vga25g_cp860,
      font_name: "IBM VGA25G 860"
    },
    %FontInfo{
      encoding_id: :cp861,
      font_id: :ibm_vga25g_cp861,
      font_name: "IBM VGA25G 861"
    },
    %FontInfo{
      encoding_id: :cp862,
      font_id: :ibm_vga25g_cp862,
      font_name: "IBM VGA25G 862"
    },
    %FontInfo{
      encoding_id: :cp863,
      font_id: :ibm_vga25g_cp863,
      font_name: "IBM VGA25G 863"
    },
    %FontInfo{
      encoding_id: :cp864,
      font_id: :ibm_vga25g_cp864,
      font_name: "IBM VGA25G 864"
    },
    %FontInfo{
      encoding_id: :cp865,
      font_id: :ibm_vga25g_cp865,
      font_name: "IBM VGA25G 865"
    },
    %FontInfo{
      encoding_id: :cp866,
      font_id: :ibm_vga25g_cp866,
      font_name: "IBM VGA25G 866"
    },
    %FontInfo{
      encoding_id: :cp869,
      font_id: :ibm_vga25g_cp869,
      font_name: "IBM VGA25G 869"
    },
    %FontInfo{
      encoding_id: :cp872,
      font_id: :ibm_vga25g_cp872,
      font_name: "IBM VGA25G 872"
    },
    %FontInfo{
      encoding_id: :kam,
      font_id: :ibm_vga25g_kam,
      font_name: "IBM VGA25G KAM"
    },
    %FontInfo{
      encoding_id: :cp867,
      font_id: :ibm_vga25g_cp867,
      font_name: "IBM VGA25G 867"
    },
    %FontInfo{
      encoding_id: :cp895,
      font_id: :ibm_vga25g_cp895,
      font_name: "IBM VGA25G 895"
    },
    %FontInfo{
      encoding_id: :maz,
      font_id: :ibm_vga25g_maz,
      font_name: "IBM VGA25G MAZ"
    },
    %FontInfo{
      encoding_id: :cp667,
      font_id: :ibm_vga25g_cp667,
      font_name: "IBM VGA25G 667"
    },
    %FontInfo{
      encoding_id: :cp790,
      font_id: :ibm_vga25g_cp790,
      font_name: "IBM VGA25G 790"
    },
    %FontInfo{
      encoding_id: :mik,
      font_id: :ibm_vga25g_mik,
      font_name: "IBM VGA25G MIK"
    },
    %FontInfo{
      encoding_id: :cp437,
      font_id: :ibm_ega_cp437,
      font_name: "IBM EGA 437"
    },
    %FontInfo{
      encoding_id: :cp720,
      font_id: :ibm_ega_cp720,
      font_name: "IBM EGA 720"
    },
    %FontInfo{
      encoding_id: :cp737,
      font_id: :ibm_ega_cp737,
      font_name: "IBM EGA 737"
    },
    %FontInfo{
      encoding_id: :cp775,
      font_id: :ibm_ega_cp775,
      font_name: "IBM EGA 775"
    },
    %FontInfo{
      encoding_id: :cp819,
      font_id: :ibm_ega_cp819,
      font_name: "IBM EGA 819"
    },
    %FontInfo{
      encoding_id: :cp850,
      font_id: :ibm_ega_cp850,
      font_name: "IBM EGA 850"
    },
    %FontInfo{
      encoding_id: :cp852,
      font_id: :ibm_ega_cp852,
      font_name: "IBM EGA 852"
    },
    %FontInfo{
      encoding_id: :cp855,
      font_id: :ibm_ega_cp855,
      font_name: "IBM EGA 855"
    },
    %FontInfo{
      encoding_id: :cp857,
      font_id: :ibm_ega_cp857,
      font_name: "IBM EGA 857"
    },
    %FontInfo{
      encoding_id: :cp860,
      font_id: :ibm_ega_cp860,
      font_name: "IBM EGA 860"
    },
    %FontInfo{
      encoding_id: :cp861,
      font_id: :ibm_ega_cp861,
      font_name: "IBM EGA 861"
    },
    %FontInfo{
      encoding_id: :cp862,
      font_id: :ibm_ega_cp862,
      font_name: "IBM EGA 862"
    },
    %FontInfo{
      encoding_id: :cp863,
      font_id: :ibm_ega_cp863,
      font_name: "IBM EGA 863"
    },
    %FontInfo{
      encoding_id: :cp864,
      font_id: :ibm_ega_cp864,
      font_name: "IBM EGA 864"
    },
    %FontInfo{
      encoding_id: :cp865,
      font_id: :ibm_ega_cp865,
      font_name: "IBM EGA 865"
    },
    %FontInfo{
      encoding_id: :cp866,
      font_id: :ibm_ega_cp866,
      font_name: "IBM EGA 866"
    },
    %FontInfo{
      encoding_id: :cp869,
      font_id: :ibm_ega_cp869,
      font_name: "IBM EGA 869"
    },
    %FontInfo{
      encoding_id: :cp872,
      font_id: :ibm_ega_cp872,
      font_name: "IBM EGA 872"
    },
    %FontInfo{
      encoding_id: :kam,
      font_id: :ibm_ega_kam,
      font_name: "IBM EGA KAM"
    },
    %FontInfo{
      encoding_id: :cp867,
      font_id: :ibm_ega_cp867,
      font_name: "IBM EGA 867"
    },
    %FontInfo{
      encoding_id: :cp895,
      font_id: :ibm_ega_cp895,
      font_name: "IBM EGA 895"
    },
    %FontInfo{
      encoding_id: :maz,
      font_id: :ibm_ega_maz,
      font_name: "IBM EGA MAZ"
    },
    %FontInfo{
      encoding_id: :cp667,
      font_id: :ibm_ega_cp667,
      font_name: "IBM EGA 667"
    },
    %FontInfo{
      encoding_id: :cp790,
      font_id: :ibm_ega_cp790,
      font_name: "IBM EGA 790"
    },
    %FontInfo{
      encoding_id: :mik,
      font_id: :ibm_ega_mik,
      font_name: "IBM EGA MIK"
    },
    %FontInfo{
      encoding_id: :cp437,
      font_id: :ibm_ega43_cp437,
      font_name: "IBM EGA43 437"
    },
    %FontInfo{
      encoding_id: :cp720,
      font_id: :ibm_ega43_cp720,
      font_name: "IBM EGA43 720"
    },
    %FontInfo{
      encoding_id: :cp737,
      font_id: :ibm_ega43_cp737,
      font_name: "IBM EGA43 737"
    },
    %FontInfo{
      encoding_id: :cp775,
      font_id: :ibm_ega43_cp775,
      font_name: "IBM EGA43 775"
    },
    %FontInfo{
      encoding_id: :cp819,
      font_id: :ibm_ega43_cp819,
      font_name: "IBM EGA43 819"
    },
    %FontInfo{
      encoding_id: :cp850,
      font_id: :ibm_ega43_cp850,
      font_name: "IBM EGA43 850"
    },
    %FontInfo{
      encoding_id: :cp852,
      font_id: :ibm_ega43_cp852,
      font_name: "IBM EGA43 852"
    },
    %FontInfo{
      encoding_id: :cp855,
      font_id: :ibm_ega43_cp855,
      font_name: "IBM EGA43 855"
    },
    %FontInfo{
      encoding_id: :cp857,
      font_id: :ibm_ega43_cp857,
      font_name: "IBM EGA43 857"
    },
    %FontInfo{
      encoding_id: :cp860,
      font_id: :ibm_ega43_cp860,
      font_name: "IBM EGA43 860"
    },
    %FontInfo{
      encoding_id: :cp861,
      font_id: :ibm_ega43_cp861,
      font_name: "IBM EGA43 861"
    },
    %FontInfo{
      encoding_id: :cp862,
      font_id: :ibm_ega43_cp862,
      font_name: "IBM EGA43 862"
    },
    %FontInfo{
      encoding_id: :cp863,
      font_id: :ibm_ega43_cp863,
      font_name: "IBM EGA43 863"
    },
    %FontInfo{
      encoding_id: :cp864,
      font_id: :ibm_ega43_cp864,
      font_name: "IBM EGA43 864"
    },
    %FontInfo{
      encoding_id: :cp865,
      font_id: :ibm_ega43_cp865,
      font_name: "IBM EGA43 865"
    },
    %FontInfo{
      encoding_id: :cp866,
      font_id: :ibm_ega43_cp866,
      font_name: "IBM EGA43 866"
    },
    %FontInfo{
      encoding_id: :cp869,
      font_id: :ibm_ega43_cp869,
      font_name: "IBM EGA43 869"
    },
    %FontInfo{
      encoding_id: :cp872,
      font_id: :ibm_ega43_cp872,
      font_name: "IBM EGA43 872"
    },
    %FontInfo{
      encoding_id: :kam,
      font_id: :ibm_ega43_kam,
      font_name: "IBM EGA43 KAM"
    },
    %FontInfo{
      encoding_id: :cp867,
      font_id: :ibm_ega43_cp867,
      font_name: "IBM EGA43 867"
    },
    %FontInfo{
      encoding_id: :cp895,
      font_id: :ibm_ega43_cp895,
      font_name: "IBM EGA43 895"
    },
    %FontInfo{
      encoding_id: :maz,
      font_id: :ibm_ega43_maz,
      font_name: "IBM EGA43 MAZ"
    },
    %FontInfo{
      encoding_id: :cp667,
      font_id: :ibm_ega43_cp667,
      font_name: "IBM EGA43 667"
    },
    %FontInfo{
      encoding_id: :cp790,
      font_id: :ibm_ega43_cp790,
      font_name: "IBM EGA43 790"
    },
    %FontInfo{
      encoding_id: :mik,
      font_id: :ibm_ega43_mik,
      font_name: "IBM EGA43 MIK"
    }
  ]


  @font_options [
    %FontOption{
      font_id: :ibm_vga,
      properties: %FontProperties{
        font_size: {9, 16},
        resolution: {720, 400},
        display: {4, 3},
        pixel_ratio: {20, 27},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga,
      properties: %FontProperties{
        font_size: {8, 16},
        resolution: {640, 400},
        display: {4, 3},
        pixel_ratio: {6, 5},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga50,
      properties: %FontProperties{
        font_size: {9, 16},
        resolution: {720, 400},
        display: {4, 3},
        pixel_ratio: {20, 27},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga50,
      properties: %FontProperties{
        font_size: {8, 8},
        resolution: {640, 400},
        display: {4, 3},
        pixel_ratio: {5, 6},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga25g,
      properties: %FontProperties{
        font_size: {8, 19},
        resolution: {640, 480},
        display: {4, 3},
        pixel_ratio: {1, 1},
        vertical_stretch: 0.0
      }
    },
    %FontOption{
      font_id: :ibm_ega,
      properties: %FontProperties{
        font_size: {8, 14},
        resolution: {640, 350},
        display: {4, 3},
        pixel_ratio: {35, 48},
        vertical_stretch: 37.14
      }
    },
    %FontOption{
      font_id: :ibm_ega43,
      properties: %FontProperties{
        font_size: {8, 8},
        resolution: {640, 350},
        display: {4, 3},
        pixel_ratio: {35, 48},
        vertical_stretch: 37.14
      }
    },
    %FontOption{
      font_id: :amiga_topaz_1,
      properties: %FontProperties{
        font_size: {8, 8},
        resolution: {640, 200},
        display: {4, 3},
        pixel_ratio: {5, 12},
        vertical_stretch: 140.0
      }
    },
    %FontOption{
      font_id: :amiga_topaz_1_plus,
      properties: %FontProperties{
        font_size: {8, 8},
        resolution: {640, 200},
        display: {4, 3},
        pixel_ratio: {5, 12},
        vertical_stretch: 140.0
      }
    },
    %FontOption{
      font_id: :amiga_topaz_2,
      properties: %FontProperties{
        font_size: {8, 8},
        resolution: {640, 200},
        display: {4, 3},
        pixel_ratio: {5, 12},
        vertical_stretch: 140.0
      }
    },
    %FontOption{
      font_id: :amiga_topaz_2_plus,
      properties: %FontProperties{
        font_size: {8, 8},
        resolution: {640, 200},
        display: {4, 3},
        pixel_ratio: {5, 12},
        vertical_stretch: 140.0
      }
    },
    %FontOption{
      font_id: :amiga_pot_noodle,
      properties: %FontProperties{
        font_size: {8, 8},
        resolution: {640, 200},
        display: {4, 3},
        pixel_ratio: {5, 12},
        vertical_stretch: 140.0
      }
    },
    %FontOption{
      font_id: :amiga_micro_knight,
      properties: %FontProperties{
        font_size: {8, 8},
        resolution: {640, 200},
        display: {4, 3},
        pixel_ratio: {5, 12},
        vertical_stretch: 140.0
      }
    },
    %FontOption{
      font_id: :amiga_micro_knight_plus,
      properties: %FontProperties{
        font_size: {8, 8},
        resolution: {640, 200},
        display: {4, 3},
        pixel_ratio: {5, 12},
        vertical_stretch: 140.0
      }
    },
    %FontOption{
      font_id: :amiga_mo_soul,
      properties: %FontProperties{
        font_size: {8, 8},
        resolution: {640, 200},
        display: {4, 3},
        pixel_ratio: {5, 12},
        vertical_stretch: 140.0
      }
    },
    %FontOption{
      font_id: :c64_petscii_unshifted,
      properties: %FontProperties{
        font_size: {8, 8},
        resolution: {320, 200},
        display: {4, 3},
        pixel_ratio: {5, 6},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :c64_petscii_shifted,
      properties: %FontProperties{
        font_size: {8, 8},
        resolution: {320, 200},
        display: {4, 3},
        pixel_ratio: {5, 6},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :atari_atascii,
      properties: %FontProperties{
        font_size: {8, 8},
        resolution: {390, 192},
        display: {4, 3},
        pixel_ratio: {4, 5},
        vertical_stretch: 25.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_mik,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_mik,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp790,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp790,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp667,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp667,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_maz,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_maz,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp895,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp895,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp867,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp867,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_kam,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_kam,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp872,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp872,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp869,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp869,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp866,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp866,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp865,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp865,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp864,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp864,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp863,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp863,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp862,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp862,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp861,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp861,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp860,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp860,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp857,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp857,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp855,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp855,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp852,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp852,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp850,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp850,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp819,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp819,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp775,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp775,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp737,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp737,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp720,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp720,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp437,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      }
    },
    %FontOption{
      font_id: :ibm_vga_cp437,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    }
  ]

  @doc """
  Creates a list of valid fonts for use with SAUCE that have full font information, including display properties.
  """
  @spec sauce_fonts() :: [SauceFont.t()]
  def sauce_fonts() do
    make_sauce_fonts(@font_options)
  end

  @doc """
  Returns a list of SAUCE fonts for the given `font_id`.

  ## Examples

      iex> Saucexages.Font.sauce_fonts(:ibm_vga)
      [
        %Saucexages.SauceFont{
          display: {4, 3},
          encoding_id: :cp437,
          font_id: :ibm_vga,
          font_name: "IBM VGA",
          font_size: {9, 16},
          pixel_ratio: {20, 27},
          resolution: {720, 400},
          vertical_stretch: 35.0
        },
        %Saucexages.SauceFont{
          display: {4, 3},
          encoding_id: :cp437,
          font_id: :ibm_vga,
          font_name: "IBM VGA",
          font_size: {8, 16},
          pixel_ratio: {6, 5},
          resolution: {640, 400},
          vertical_stretch: 20.0
        }
      ]

  """
  @spec sauce_fonts(font_id()) :: [SauceFont.t()]
  def sauce_fonts(font_id) do
    font_options(font_id) |> make_sauce_fonts()
  end

  @doc """
  Returns the SAUCE font for the given `font_id` and specified size.

  ## Examples

      iex> Saucexages.Font.sauce_font_for(:ibm_vga, {9, 16})
      %Saucexages.SauceFont{
         display: {4, 3},
         encoding_id: :cp437,
         font_id: :ibm_vga,
         font_name: "IBM VGA",
         font_size: {9, 16},
         pixel_ratio: {20, 27},
         resolution: {720, 400},
         vertical_stretch: 35.0
      }

  """
  @spec sauce_font_for(font_id(), font_size()) :: SauceFont.t()
  def sauce_font_for(font_id, font_size) do
    font_option_for(font_id, font_size) |> make_sauce_font()
  end

  defp make_sauce_font(%{font_id: font_id, properties: properties} = _font_option) do
      font_info(font_id)
      |> SauceFont.new(properties)
  end

  defp make_sauce_font(_font_option) do
    nil
  end

  defp make_sauce_fonts(font_option_list) when is_list(font_option_list) do
    Enum.flat_map(font_option_list, fn(font_option) ->
    case make_sauce_font(font_option) do
      nil -> []
      sauce_font when is_map(sauce_font) -> [sauce_font]
    end

    end)
  end

  @doc """
  Lists all the possible font options according to the SAUCE standard.
  """
  @spec font_options() :: [FontOption.t()]
  defmacro font_options() do
    @font_options
    |> Macro.escape()
  end

  @doc """
  Returns the font options for the given `font_id`. Each font id may have one or more options

  ## Examples

      iex> Saucexages.Font.font_options(:ibm_vga)
      [
       %Saucexages.FontOption{
       font_id: :ibm_vga,
       properties: %Saucexages.FontProperties {
         display: {4, 3},
         font_size: {9, 16},
         pixel_ratio: {20, 27},
         resolution: {720, 400},
         vertical_stretch: 35.0
       }
       },
       %Saucexages.FontOption{
         font_id: :ibm_vga,
         properties: %Saucexages.FontProperties{
           display: {4, 3},
           font_size: {8, 16},
           pixel_ratio: {6, 5},
           resolution: {640, 400},
           vertical_stretch: 20.0
         }
        }
      ]

  """
  @spec font_options(font_id()) :: [FontOption.t()]
  def font_options(font_id)
  for {font_id, font_option_group} <- Enum.group_by(@font_options, fn (%{font_id: font_id}) -> font_id end) do
    def font_options(unquote(font_id)) do
      unquote(
        font_option_group
        |> Macro.escape()
      )
    end
  end

  def font_options(_font_id) do
    []
  end

  @doc """
  Returns the font option for the given `font_id` and `font_size`. Each font id should have 0 to one font option for a given size.


  ## Examples

      iex> Saucexages.Font.font_option_for(:ibm_vga, {9, 16})
      %Saucexages.FontOption{
        font_id: :ibm_vga,
        properties: %Saucexages.FontProperties{
          display: {4, 3},
          font_size: {9, 16},
          pixel_ratio: {20, 27},
          resolution: {720, 400},
          vertical_stretch: 35.0
        }
      }

  """
  @spec font_option_for(font_id(), font_size()) :: FontOption.t()
  def font_option_for(font_id, font_size)
  for %{
        font_id: font_id,
        properties: %{
          font_size: font_size
        }
      } = font_option <- @font_options do
    def font_option_for(unquote(font_id), unquote(font_size)) do
      unquote(
        font_option
        |> Macro.escape()
      )
    end
  end

  def font_option_for(_font_id, _font_size) do
    nil
  end

  @doc """
  Builds a font option name for the given font option.

  Useful for interface building, logging, and labeling.

  ## Examples

      iex> Saucexages.Font.option_name(:ibm_vga, 9, 16)
      "IBM VGA 9x16"

  """
  @spec option_name(FontOption.t()) :: String.t()
  def option_name(
        %{
          font_id: font_id,
          properties: %{
            font_size: {font_width, font_height}
          }
        }
      ) do
    option_name(font_id, font_width, font_height)
  end

  def option_name(_font_option) do
    raise ArgumentError, "font_option must be a valid FontOption with a font id, width, and height."
  end

  @doc """
  Builds a font option name for the given font information.

  Useful for interface building, logging, and labeling.
  """
  @spec option_name(font_id(), pos_integer(), pos_integer()) :: String.t()
  def option_name(font_id, width, height) when is_atom(font_id) and is_integer(width) and is_integer(height) and width > 0 and height > 0 do
    name = case font_name(font_id) do
      nil -> to_string(font_id)
      name when is_binary(name) ->
        name
    end

    Enum.join([name, <<32>>, width, "x", height])
  end

  def option_name(_font_id, _width, _height) do
    raise ArgumentError, "font id must be a valid font id, and height and width must be greater than zero."
  end

  @doc """
  Lists all the default fonts, with their font info as supported by the SAUCE standard.
  """
  @spec default_fonts() :: [FontInfo.t()]
  defmacro default_fonts() do
    @default_fonts
    |> Macro.escape()
  end

  @doc """
  Lists all the default font ids as supported by the SAUCE standard.
  """
  @spec default_font_ids() :: [atom()]
  defmacro default_font_ids() do
    Enum.map(@default_fonts, fn (%{font_id: font_id}) -> font_id end)
  end

  @doc """
  Lists all the default font names as supported by the SAUCE standard.

  These names are each valid values within a sauce record for any record that has a corresponding mapping to FontName for t_info_s. For instance, these values may appear in the t_info_s for any file with its sauce record set to :ansi in the data_type_id field.
  """
  @spec default_font_names() :: [String.t()]
  defmacro default_font_names() do
    Enum.map(@default_fonts, fn (%{font_name: font_name}) -> font_name end)
  end

  @doc """
  Returns the full font info for a given `font_id` or `font_name`.

  ## Examples

      iex> Saucexages.Font.font_info(:ibm_vga)
      %Saucexages.FontInfo{
         encoding_id: :cp437,
         font_id: :ibm_vga,
         font_name: "IBM VGA"
       }

  """
  @spec font_info(font_id() | font_name()) :: FontInfo.t()
  def font_info(font_id)
  for %{font_id: font_id, font_name: font_name} = font <- @default_fonts do
    def font_info(unquote(font_id)) do
      unquote(
        font
        |> Macro.escape()
      )
    end

    def font_info(unquote(font_name)) do
      unquote(
        font
        |> Macro.escape()
      )
    end
  end

  def font_info(_font_id) do
    nil
  end

  @doc """
  Returns the `font_id` corresponding to the given `font_name`.

  Useful for translating SAUCE record font names found t_info_s fields into font ids.

  ## Examples

      iex> Saucexages.Font.font_id("Amiga Topaz 1")
      :amiga_topaz_1

      iex> Saucexages.Font.font_id("IBM VGA")
      :ibm_vga

  """
  @spec font_id(font_name()) :: font_id() | nil
  def font_id(font_name)
  for %{font_name: font_name, font_id: font_id} <- @default_fonts do
    def font_id(unquote(font_name)) do
      unquote(font_id)
    end
  end

  def font_id(_font_name) do
    nil
  end

  @doc """
  Returns the font name that corresponds to the given font id.

  # Examples

      iex> Saucexages.Font.font_name(:amiga_topaz_1)
      "Amiga Topaz 1"

      iex> Saucexages.Font.font_name(:ibm_vga)
      "IBM VGA"

  """
  @spec font_name(font_id()) :: font_name() | nil
  def font_name(font_id)
  for %{font_name: font_name, font_id: font_id} <- @default_fonts do
    def font_name(unquote(font_id)) do
      unquote(font_name)
    end
  end

  def font_name(_font_name) do
    nil
  end

  @doc """
  Lists all encodings supported by the SAUCE standard.
  """
  @spec supported_encodings() :: [FontEncoding.t()]
  defmacro supported_encodings() do
    @supported_encodings
    |> Macro.escape()
  end

  @doc """
  Lists all encoding ids supported by the SAUCE standard.
  """
  @spec supported_encoding_ids() :: [encoding_id()]
  defmacro supported_encoding_ids() do
    Enum.map(@supported_encodings, fn (%{encoding_id: encoding_id}) -> encoding_id end)
  end

  @doc """
  Lists all encoding names supported by the SAUCE standard.
  """
  @spec supported_encoding_names() :: [String.t()]
  defmacro supported_encoding_names() do
    Enum.map(@supported_encodings, fn (%{encoding_name: encoding_name}) -> encoding_name end)
  end

  @doc """
  Returns the corresponding encoding name for a given encoding id.

  ## Examples

      iex> Saucexages.Font.encoding_name(:cp437)
      "437"

  """
  @spec encoding_name(encoding_id()) :: String.t()
  def encoding_name(encoding_id)
  for %{encoding_id: encoding_id, encoding_name: encoding_name} <- @supported_encodings do
    def encoding_name(unquote(encoding_id)) do
      unquote(encoding_name)
    end
  end

  def encoding_name(_encoding_id) do
    nil
  end

  @doc """
  Returns the corresponding encoding for a given encoding id.

  ## Examples

      iex> Saucexages.Font.encoding(:cp437)
      %Saucexages.FontEncoding{
        encoding_id: :cp437,
        encoding_name: "437",
        friendly_name: "MS-DOS Latin US"
      }

  """
  @spec encoding(encoding_id()) :: FontEncoding.t()
  def encoding(encoding_id)
  for %{encoding_id: encoding_id} = encoding <- @supported_encodings do
    def encoding(unquote(encoding_id)) do
      unquote(
        encoding
        |> Macro.escape()
      )
    end
  end

  def encoding(_encoding_id) do
    nil
  end

  @doc """
  Generates a list of Font Info based on a set of encodings and a font name.

  This scheme is used in the SAUCE standard commonly in the form of `FONT NAME ###` where `FONT_NAME` corresponds to a font name, ex: `IBM VGA 50` and `###` corresponds to an encoding name, ex: `437`.
  """
  @spec generate_font_info_group(font_id(), [FontEncoding.t()]) :: [FontInfo.t()] | []
  def generate_font_info_group(font_id, encodings \\ supported_encodings())
  for font_id <- @groupable_font_ids do
    def generate_font_info_group(unquote(font_id), encodings) do
      do_generate_font_info_group(unquote(font_id), encodings)
    end
  end

  def generate_font_info_group(_font_id, _encodings) do
    []
  end

  defp do_generate_font_info_group(font_id, encodings) do
    base_font_name = font_name(font_id)
    Enum.map(encodings, fn (%{encoding_id: encoding_id, encoding_name: encoding_name}) ->
      %FontInfo{font_id: :"#{font_id}_#{encoding_id}",
        font_name: Enum.join([base_font_name, <<32>>, encoding_name]), encoding_id: encoding_id} end)
  end

  @doc """
  Generates a full list of Font Info based on all fonts that support multiple encodings.

  This scheme is used in the SAUCE standard commonly in the form of `FONT NAME ###` where `FONT_NAME` corresponds to a font name, ex: `IBM VGA 50` and `###` corresponds to an encoding name, ex: `437`.
  """
  @spec generate_all_font_info_groups([FontEncoding.t()]) :: [FontInfo.t()]
  def generate_all_font_info_groups(encodings \\ supported_encodings()) do
    Enum.reduce(
      @groupable_font_ids,
      [],
      fn (font_id, acc) -> case generate_font_info_group(font_id, encodings) do
                             font_infos = [_ | _] -> font_infos ++ acc
                             _ -> acc end
      end
    )
  end

  @doc """
  Generates a list of Font Options based on a set of encodings and a font name.

  This scheme is used in the SAUCE standard commonly in the form of `FONT NAME ###` where `FONT_NAME` corresponds to a font name, ex: `IBM VGA 50` and `###` corresponds to an encoding name, ex: `437`.
  """
  @spec generate_font_option_group(font_id(), [FontEncoding.t()]) :: [FontOption.t()] | []
  def generate_font_option_group(font_id, encodings \\ supported_encodings())
  for font_id <- @groupable_font_ids do
    def generate_font_option_group(unquote(font_id), encodings) do
      do_generate_font_option_group(unquote(font_id), encodings)
    end
  end

  def generate_font_option_group(_font_id, _encodings) do
    []
  end

  defp do_generate_font_option_group(font_id, encodings) do
    base_font_properties = font_options(font_id)

    Enum.reduce(
      encodings,
      [],
      fn (%{encoding_id: encoding_id}, acc) ->
        Enum.map(base_font_properties, fn (%{properties: props}) -> %FontOption{font_id: :"#{font_id}_#{encoding_id}", properties: props} end) ++ acc
      end
    )
  end

  @doc """
  Generates a full list of Font Options based on all fonts that support multiple encodings.

  This scheme is used in the SAUCE standard commonly in the form of `FONT NAME ###` where `FONT_NAME` corresponds to a font name, ex: `IBM VGA 50` and `###` corresponds to an encoding name, ex: `437`.
  """
  @spec generate_all_font_option_groups([FontEncoding.t()]) :: [FontOption.t()]
  def generate_all_font_option_groups(encodings \\ supported_encodings()) do
    Enum.reduce(
      @groupable_font_ids,
      [],
      fn (font_id, acc) -> case generate_font_option_group(font_id, encodings) do
                             font_opts = [_ | _] -> font_opts ++ acc
                             _ -> acc end
      end
    )
  end

end

