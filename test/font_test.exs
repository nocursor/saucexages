defmodule Saucexages.FontTest do
  use ExUnit.Case, async: true
  doctest Saucexages.Font
  import Saucexages.Font
  require Saucexages.SauceFont
  alias Saucexages.{SauceFont, FontOption, FontInfo, FontProperties, FontEncoding}

  test "sauce_fonts/0 returns all the possible SAUCE fonts that are used by the SAUCE spec" do
    fonts = sauce_fonts()

    refute is_nil(fonts)
    refute fonts == []
    assert Enum.all?(
             fonts,
             fn
               %SauceFont{} -> true
               _ -> false
             end
           )
    # max number of combinations based on spec
    assert Enum.count(fonts) == 68
  end

  test "sauce_fonts/1 returns all the possible SAUCE fonts for a given font id" do
    ibm_vga_fonts = [
      %SauceFont{
        display: {4, 3},
        encoding_id: :cp437,
        font_id: :ibm_vga,
        font_name: "IBM VGA",
        font_size: {9, 16},
        pixel_ratio: {20, 27},
        resolution: {720, 400},
        vertical_stretch: 35.0
      },
      %SauceFont{
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

    assert sauce_fonts(:ibm_vga) == ibm_vga_fonts

    topaz_1_fonts = [
      %SauceFont{
        display: {4, 3},
        encoding_id: :amiga,
        font_id: :amiga_topaz_1,
        font_name: "Amiga Topaz 1",
        font_size: {8, 8},
        pixel_ratio: {5, 12},
        resolution: {640, 200},
        vertical_stretch: 140.0
      }
    ]

    assert sauce_fonts(:amiga_topaz_1) == topaz_1_fonts
    assert sauce_fonts(:chicken) == []
  end

  test "sauce_font_for/2 returns the SAUCE font for the given size" do
    assert sauce_font_for(:ibm_vga, {9, 16}) == %SauceFont{
             display: {4, 3},
             encoding_id: :cp437,
             font_id: :ibm_vga,
             font_name: "IBM VGA",
             font_size: {9, 16},
             pixel_ratio: {20, 27},
             resolution: {720, 400},
             vertical_stretch: 35.0
           }

    assert sauce_font_for(:ibm_vga, {8, 16}) == %SauceFont{
             display: {4, 3},
             encoding_id: :cp437,
             font_id: :ibm_vga,
             font_name: "IBM VGA",
             font_size: {8, 16},
             pixel_ratio: {6, 5},
             resolution: {640, 400},
             vertical_stretch: 20.0
           }

    assert sauce_font_for(:ibm_vga, {0, 16}) == nil
    assert sauce_font_for(:chicken, {9, 16}) == nil
  end

  test "font_options/0 lists all possible SAUCE font options" do
    options = font_options()

    refute is_nil(options)
    refute options == []
    assert Enum.all?(
             options,
             fn
               %FontOption{} -> true
               _ -> false
             end
           )
    # max number of combinations based on spec
    assert Enum.count(options) == 68
  end

  test "font_options/1 lists all possible font options for a font id" do
    ibm_vga_fonts = [
      %FontOption{
        font_id: :ibm_vga,
        properties: %FontProperties {
          display: {4, 3},
          font_size: {9, 16},
          pixel_ratio: {20, 27},
          resolution: {720, 400},
          vertical_stretch: 35.0
        }
      },
      %FontOption{
        font_id: :ibm_vga,
        properties: %FontProperties{
          display: {4, 3},
          font_size: {8, 16},
          pixel_ratio: {6, 5},
          resolution: {640, 400},
          vertical_stretch: 20.0
        }
      }
    ]

    assert font_options(:ibm_vga) == ibm_vga_fonts

    topaz_1_fonts = [
      %FontOption{
        font_id: :amiga_topaz_1,
        properties: %FontProperties{
          display: {4, 3},
          font_size: {8, 8},
          pixel_ratio: {5, 12},
          resolution: {640, 200},
          vertical_stretch: 140.0
        }
      }
    ]

    assert font_options(:amiga_topaz_1) == topaz_1_fonts
    assert font_options(:chicken) == []
  end

  test "font_option_for returns the font option for a font id and the given size" do
    assert font_option_for(:ibm_vga, {9, 16}) == %FontOption{
             font_id: :ibm_vga,
             properties: %FontProperties{
               display: {4, 3},
               font_size: {9, 16},
               pixel_ratio: {20, 27},
               resolution: {720, 400},
               vertical_stretch: 35.0
             }
           }

    assert font_option_for(:ibm_vga, {8, 16}) == %FontOption{
             font_id: :ibm_vga,
             properties: %FontProperties{
               display: {4, 3},
               font_size: {8, 16},
               pixel_ratio: {6, 5},
               resolution: {640, 400},
               vertical_stretch: 20.0
             }
           }

    assert font_option_for(:ibm_vga, {0, 16}) == nil
    assert font_option_for(:chicken, {9, 16}) == nil
  end

  test "option_name/1 creates labels for font options" do
    ibm_vga = %FontOption{
      font_id: :ibm_vga,
      properties: %FontProperties{
        display: {4, 3},
        font_size: {8, 16},
        pixel_ratio: {6, 5},
        resolution: {640, 400},
        vertical_stretch: 20.0
      }
    }

    assert option_name(ibm_vga) == "IBM VGA 8x16"
    assert_raise ArgumentError, fn ->
      option_name(%FontOption{font_id: :blah, properties: nil})
    end
  end

  test "option_name/2 creates labels for the given font info" do
    assert option_name(:ibm_vga, 9, 16) == "IBM VGA 9x16"
    assert option_name(:ibm_vga, 8, 16) == "IBM VGA 8x16"
    assert option_name(:blah, 9, 16) == "blah 9x16"
    assert_raise ArgumentError, fn ->
      option_name(:blah, -20, -50)
    end
  end

  test "default_fonts/0 returns all SAUCE default font information" do
    fonts = default_fonts()

    refute is_nil(fonts)
    refute fonts == []
    assert Enum.all?(
             fonts,
             fn
               %FontInfo{} -> true
               _ -> false
             end
           )
    # max number of combinations based on spec
    assert Enum.count(fonts) == 141
  end

  test "default_font_ids/0 returns all SAUCE default font ids" do
    fonts = default_font_ids()

    refute is_nil(fonts)
    refute fonts == []
    assert Enum.all?(
             fonts,
             fn (font) -> is_atom(font) end
           )
    # max number of combinations based on spec
    assert Enum.count(fonts) == 141
  end

  test "default_font_names/0 returns all SAUCE default font names" do
    fonts = default_font_names()

    refute is_nil(fonts)
    refute fonts == []
    assert Enum.all?(
             fonts,
             fn (font_name) -> String.valid?(font_name) end
           )
    # max number of combinations based on spec
    assert Enum.count(fonts) == 141
  end

  test "font_info/1 returns font information for a font id or font name" do
    ibm_vga = %FontInfo{
      encoding_id: :cp437,
      font_id: :ibm_vga,
      font_name: "IBM VGA"
    }
    assert font_info(:ibm_vga) == ibm_vga
    assert font_info("IBM VGA") == ibm_vga

    assert font_info(:ibm_vga_cp819) == %FontInfo{
             encoding_id: :cp819,
             font_id: :ibm_vga_cp819,
             font_name: "IBM VGA 819"
           }

    assert font_info(:chicken) == nil
  end

  test "font_id/1 returns the font id for a given font name" do
    assert font_id("IBM VGA") == :ibm_vga
    assert font_id("Amiga Topaz 1") == :amiga_topaz_1
    assert font_id("Smelly Man") == nil
    assert font_id("") == nil
  end

  test "font_name/1 returns the font name for the given font_id" do
    assert font_name(:ibm_vga) == "IBM VGA"
    assert font_name(:amiga_topaz_1) == "Amiga Topaz 1"
    assert font_name(:chicken) == nil
  end

  test "encoding_name/1 returns the encoding name for a given encoding id" do
    assert encoding_name(:cp437) == "437"
    assert encoding_name(:cp667) == "667"
    assert encoding_name(:chicken) == nil
  end

  test "encoding/1 returns the encoding for the given encoding id" do
    assert encoding(:cp437) == %FontEncoding{
             encoding_id: :cp437,
             encoding_name: "437",
             friendly_name: "MS-DOS Latin US"
           }
    assert encoding(:cp667) == %FontEncoding{
             encoding_id: :cp667,
             encoding_name: "667",
             friendly_name: "Mazovia"
           }

    assert encoding(:blah) == nil
  end

end