defmodule Saucexages.AnsiFlagsTest do
  use ExUnit.Case, async: true
  doctest Saucexages.AnsiFlags
  import Saucexages.AnsiFlags

  test "ansi_flags/1 decodes and returns ansi flags for rendering" do
    assert ansi_flags(0) ==
    %Saucexages.AnsiFlags{
      aspect_ratio: :none,
      letter_spacing: :none,
      non_blink_mode?: false
    }

    assert ansi_flags(17) ==
    %Saucexages.AnsiFlags{
      aspect_ratio: :modern,
      letter_spacing: :none,
      non_blink_mode?: true
    }

    assert ansi_flags(2) ==
    %Saucexages.AnsiFlags{
      aspect_ratio: :none,
      letter_spacing: :eight_pixel_font,
      non_blink_mode?: false
    }

    assert ansi_flags(5) ==
    %Saucexages.AnsiFlags{
      aspect_ratio: :none,
      letter_spacing: :nine_pixel_font,
      non_blink_mode?: true
    }

  end

  test "aspect_ratio/1 returns the aspect ratio for the given flags" do
    assert aspect_ratio(0) == :none
    assert aspect_ratio(<<16>>) == :modern
    assert aspect_ratio(1) == :none
    assert aspect_ratio(8) == :legacy
    assert aspect_ratio(16) == :modern
  end

  test "letter_spacing/1 returns the letter spacing for the given ansi flags" do
    assert letter_spacing(0) == :none
    assert letter_spacing(<<2>>) == :eight_pixel_font
    assert letter_spacing(11) == :eight_pixel_font
    assert letter_spacing(12) == :nine_pixel_font
    assert letter_spacing(14) == :invalid
  end

  test "non_blink_mode?/1 returns whether or not the given flags indicate non-blink mode" do
    assert non_blink_mode?(<<16>>) == false
    assert non_blink_mode?(<<17>>) == true
    assert non_blink_mode?(16) == false
    assert non_blink_mode?(17) == true
  end

  test "to_binary/1 converts integer flags to binary" do
    assert to_binary(0) == <<0>>
    #ensure wrap
    assert to_binary(65535) == <<255>>
  end

  test "to_integer/1 converts an integer to binary" do
    assert to_integer(<<0>>) == 0
    assert to_integer(<<255>>) == 255
  end

end