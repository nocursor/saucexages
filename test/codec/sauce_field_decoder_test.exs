defmodule Saucexages.SauceFieldDecoderTest do
  use ExUnit.Case, async: true
  import Saucexages.Codec.SauceFieldDecoder
  require Codepagex
  require Saucexages.Codec.Encodings
  alias Saucexages.Codec.Encodings
  alias Codepagex

  test "decode_string/3 decodes a SAUCE string, trimming any empty space" do
    assert decode_string("12345") == "12345"
    assert decode_string(<<"12345", 32, 32, 32, 32, 32>>) == "12345"
    assert decode_string(<<"12345", 32, 32, 32, 32, 32, 0, 0>>) == "12345"
  end

  test "decode_string/3 decodes an empty SAUCE string that has been padded" do
    assert decode_string(<<32, 32, 32, 32, 32, 32>>) == ""
    assert decode_string(<<32>>) == ""
  end

  test "decode_string/3 decodes a SAUCE string with a custom default value if data is invalid" do
    # per the SAUCE spec notes, we should handle the erroneous case of dumb people who have encoded zero instead of space
    assert decode_string(<<0>>, "A") == "A"
    # if garbage, decode should still map to "something"
    assert decode_string("チーズ", "A") == "πâüπâ╝πé║"
    assert decode_string(<<0>>, "Hello World") == "Hello World"
    assert decode_string(<<0, 0, 0>>, "Hello World") == "Hello World"
  end

  test "decode_cstring/3 decodes a SAUCE string, trimming any empty zeroes or spaces" do
    assert decode_cstring("12345") == "12345"
    assert decode_cstring(<<"12345", 0, 0, 0, 0, 0>>) == "12345"
    # a mix of nasty
    assert decode_cstring(<<"12345", 0, 32, 32>>) == "12345"
    assert decode_cstring(<<"12345", 32, 0 , 0>>) == "12345"
    assert decode_cstring(<<"12345", 32, 0 , 1, 2, 3, 4, 5>>) == "12345"

  end

  test "decode_cstring/3 decodes an empty SAUCE string that has been 0-padded" do
    assert decode_cstring(<<0, 0, 0, 0, 0, 0>>, "") == ""
    assert decode_cstring(<<0, 0, 0, 0, 0, 0>>) == nil
    assert decode_cstring(<<0>>) == nil
    assert decode_cstring(<<0>>, "") == ""
  end

  test "decode_cstring/3 decodes a SAUCE string with a custom default value if data is invalid" do
    assert decode_string(<<0>>, "A") == "A"
    # if garbage, decode should still map to "something"
    assert decode_string("チーズ", "A") == "πâüπâ╝πé║"
    assert decode_string(<<0>>, "Hello World") == "Hello World"
    assert decode_string(<<0, 0, 0>>, "Hello World") == "Hello World"
  end

  test "convert_string/2 converts a SAUCE string from the specified encodings in succession, lastly trying utf8" do
    assert convert_string("12345", [Encodings.encoding(:cp437)]) == {:ok, "12345", Encodings.encoding(:cp437)}
    #assert convert_string("12345", [Encodings.encoding(:ascii)]) == {:ok, "12345", Encodings.encoding(:ascii)}
    # if someone accidentally encoded utf-8 as can happen in the wild, this covers this case
    assert convert_string("チーズ", []) == {:ok, "チーズ", Encodings.encoding(:utf8)}
    assert convert_string("12345", []) == {:ok, "12345", Encodings.encoding(:utf8)}
  end

  test "decode_file_type/2 decodes a SAUCE file type to a valid file type" do
    assert decode_file_type(0, 0) == 0
    # invalid data type
    assert decode_file_type(0, 666) == 0

    # invalid file type
    assert decode_file_type(666, 0) == 0

    assert decode_file_type(1, 1) == 1
    assert decode_file_type(1, 2) == 1
    assert decode_file_type(1, 3) == 1
    assert decode_file_type(1, 4) == 1

    # invalid file types
    assert decode_file_type(1, 5) == 0
    assert decode_file_type(1, 6) == 0

    assert decode_file_type(1, 7) == 1

    # invalid file type
    assert decode_file_type(1, 8) == 0
  end

  test "decode_data_type/2 decodes a SAUCE data type to a valid data type" do
    assert decode_data_type(0) == 0
    assert decode_data_type(1) == 1
    assert decode_data_type(2) == 2
    assert decode_data_type(3) == 3
    assert decode_data_type(4) == 4
    assert decode_data_type(5) == 5
    assert decode_data_type(6) == 6
    assert decode_data_type(7) == 7
    assert decode_data_type(8) == 8
    # invalid
    assert decode_data_type(9) == 0
  end

  test "decode_date/1 decodes a SAUCE date into an elixir date" do
    assert decode_date("20000229") == ~D[2000-02-29]
    assert decode_date("20001201") == ~D[2000-12-01]
    assert decode_date("19940202") == ~D[1994-02-02]
    assert decode_date("199402029999") == nil
    assert decode_date("00000000") == nil
    assert decode_date("10009988") == nil
    assert decode_date("19941302") == nil
  end

  test "decode_comment_lines/1 decodes a SAUCE comment line value" do
    assert decode_comment_lines(0) == 0
    assert decode_comment_lines(1) == 1
    assert decode_comment_lines(<<1>>) == 1
    # overflow
    assert decode_comment_lines(234324324032432342342432) == 0
  end

end