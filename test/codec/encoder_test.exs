defmodule Saucexages.EncoderTest do
  use ExUnit.Case, async: true
  import Saucexages.Codec.Encoder
  require Codepagex
  alias Codepagex
  alias Saucexages.SauceBlock

  test "encode_string/2 encodes a string to the proper size with space padding" do
    assert encode_string("12345", 5) == "12345"
    #overrun
    assert encode_string("12345", 4) == "1234"
    #underrun
    assert encode_string("12345", 6) == "12345 "
    assert encode_string("", 5) == <<32, 32, 32, 32, 32>>
  end

  test "encode_string/2 handles unicode characters" do
    #japanese cheese
    assert encode_string("チーズ", 3) == <<32, 32, 32>>
    assert encode_string("チーズ is chizu", 12) == <<32, 105, 115, 32, 99, 104, 105, 122, 117, 32, 32, 32>>
  end

  test "encode_cstring encodes a string to the proper size with 0 padding" do
    assert encode_cstring("12345", 5) == "12345"
    assert encode_cstring("12345", 4) == "1234"
    assert encode_cstring("12345", 6) == <<"12345", 0>>
    assert encode_cstring("", 5) == <<0, 0, 0, 0, 0>>
  end

  test "encode_cstring/2 handles unicode" do
    assert encode_cstring("チーズ", 3) == <<0, 0, 0>>
    assert encode_cstring("チーズ is chizu", 12) == <<32, 105, 115, 32, 99, 104, 105, 122, 117, 0, 0, 0>>
  end

  test "encode_date/1 encodes an elixir datetime as a SAUCE data" do
    # single digit month
    dt1 = %DateTime{
      year: 2000,
      month: 2,
      day: 29,
      zone_abbr: "AMT",
      hour: 23,
      minute: 0,
      second: 7,
      microsecond: {0, 0},
      utc_offset: -14400,
      std_offset: 0,
      time_zone: "America/Manaus"
    }

    # single digit day
    dt2 = %DateTime{
      year: 2000,
      month: 12,
      day: 1,
      zone_abbr: "AMT",
      hour: 23,
      minute: 0,
      second: 7,
      microsecond: {0, 0},
      utc_offset: -14400,
      std_offset: 0,
      time_zone: "America/Manaus"
    }

    # back when the world was good
    dt3 = %DateTime{
      year: 1994,
      month: 2,
      day: 2,
      zone_abbr: "AMT",
      hour: 23,
      minute: 59,
      second: 59,
      microsecond: {0, 0},
      utc_offset: -14400,
      std_offset: 0,
      time_zone: "America/Manaus"
    }

    assert encode_date(dt1) == "20000229"
    assert encode_date(dt2) == "20001201"
    assert encode_date(dt3) == "19940202"
  end

  test "encode_version/1 encodes a version string" do
    assert encode_version("00") == "00"
    assert encode_version("0") == <<"0", 32>>
    assert encode_version("チーズ") == <<32, 32>>
    assert encode_version(<<32, "00">>) == "00"
  end

  test "encode_integer/2 encodes a SAUCE integer of the given size" do
    assert encode_integer(0, 1) == <<0>>
    assert encode_integer(255, 1) == <<255>>
    assert encode_integer(32767, 2) == <<255, 127>>
  end

  test "encode_integer/2 handles overflow" do
    #overflow
    assert encode_integer(32767, 1) == <<255>>
  end

  test "encode_integer/2 handles underflow" do
    #padding
    assert encode_integer(0, 2) == <<0, 0>>
    assert encode_integer(2, 2) == <<2, 0>>
  end

  test "encode_integer/2 handles byte order" do
    #byte order
    assert encode_integer(32767, 3) == <<255, 127, 0>>
  end

  test "encode_integer/2 handles coercing to unsigned" do
    #unsigned coerce
    assert encode_integer(-255, 1) == <<1>>
  end

  describe "Encoding a SAUCE Block" do
    setup do
      ansi_sauce = %SauceBlock{
        author: "RaD MaN",
        comments: ["test notes", "second line", "more test", "",
          "after a blank line"],
        date: ~D[1994-08-31],
        media_info: %Saucexages.MediaInfo{
          data_type: 1,
          file_size: 8900,
          file_type: 1,
          t_flags: 52,
          t_info_1: 80,
          t_info_2: 97,
          t_info_3: 16,
          t_info_4: 72,
          t_info_s: "IBM VGA"
        },
        group: "ACiD Productions",
        title: "ACiD 1994 Member/Board Listing",
        version: "00"
      }

      rip_sauce = %SauceBlock{
        author: "ReDMaN",
        comments: [],
        date: ~D[1994-08-29],
        media_info: %Saucexages.MediaInfo{
          data_type: 1,
          file_size: 30441,
          file_type: 3,
          t_flags: 0,
          t_info_1: 640,
          t_info_2: 350,
          t_info_3: 16,
          t_info_4: 0,
          t_info_s: ""
        },
        group: "ACiD Productions",
        title: "Corruption Ad",
        version: "00"
      }

      %{ansi_sauce: ansi_sauce, rip_sauce: rip_sauce}
    end

    test "encode_field/1 handles encoding all specific SAUCE block fields to binary", %{ansi_sauce: ansi_sauce, rip_sauce: rip_sauce}  do
      assert encode_field(:version, ansi_sauce) == <<"00">>
      assert encode_field(:title, ansi_sauce) == "ACiD 1994 Member/Board Listing     "
      assert encode_field(:author, ansi_sauce) == "RaD MaN             "
      assert encode_field(:group, ansi_sauce) == "ACiD Productions    "
      assert encode_field(:date, ansi_sauce) == "19940831"
      assert encode_field(:file_size, ansi_sauce) == <<196, 34, 0, 0>>
      assert encode_field(:data_type, ansi_sauce) == <<1>>
      assert encode_field(:file_type, ansi_sauce) == <<1>>
      assert encode_field(:t_info_1, ansi_sauce) == <<80, 0>>
      assert encode_field(:t_info_2, ansi_sauce) == <<97, 0>>
      assert encode_field(:t_info_3, ansi_sauce) == <<16, 0>>
      assert encode_field(:t_info_4, ansi_sauce) == <<72, 0>>
      assert encode_field(:comment_lines, ansi_sauce) == <<5>>
      assert encode_field(:t_flags, ansi_sauce) == <<52>>
      assert encode_field(:t_info_s, ansi_sauce) == <<73, 66, 77, 32, 86, 71, 65, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>

      assert encode_field(:version, rip_sauce) == <<"00">>
      assert encode_field(:title, rip_sauce) == "Corruption Ad                      "
      assert encode_field(:author, rip_sauce) == "ReDMaN              "
      assert encode_field(:group, rip_sauce) == "ACiD Productions    "
      assert encode_field(:date, rip_sauce) == "19940829"
      assert encode_field(:file_size, rip_sauce) == <<233, 118, 0, 0>>
      assert encode_field(:data_type, rip_sauce) == <<1>>
      assert encode_field(:file_type, rip_sauce) == <<3>>
      assert encode_field(:t_info_1, rip_sauce) == <<128, 2>>
      assert encode_field(:t_info_2, rip_sauce) == <<94, 1>>
      assert encode_field(:t_info_3, rip_sauce) == <<16, 0>>
      assert encode_field(:t_info_4, rip_sauce) == <<0, 0>>
      assert encode_field(:comment_lines, rip_sauce) == <<0>>
      assert encode_field(:t_flags, rip_sauce) == <<0>>
      assert encode_field(:t_info_s, rip_sauce) == <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
    end

    test "encode_record/1 handles encoding a SAUCE block into a binary SAUCE record", %{ansi_sauce: ansi_sauce, rip_sauce: rip_sauce}  do
      {:ok, ansi_record} = encode_record(ansi_sauce)

      refute is_nil(ansi_record)
      assert is_binary(ansi_record)
      assert byte_size(ansi_record) == 128
      #ensure the header
      assert :binary.part(ansi_record, 0, 5) == "SAUCE"
      assert :binary.part(ansi_record, 5, 2) == "00"
      assert ansi_record ==  <<83, 65, 85, 67, 69, 48, 48, 65, 67, 105, 68, 32, 49, 57, 57, 52, 32, 77, 101,
               109, 98, 101, 114, 47, 66, 111, 97, 114, 100, 32, 76, 105, 115, 116, 105,
               110, 103, 32, 32, 32, 32, 32, 82, 97, 68, 32, 77, 97, 78, 32, 32, 32, 32, 32,
               32, 32, 32, 32, 32, 32, 32, 32, 65, 67, 105, 68, 32, 80, 114, 111, 100, 117,
               99, 116, 105, 111, 110, 115, 32, 32, 32, 32, 49, 57, 57, 52, 48, 56, 51, 49,
               196, 34, 0, 0, 1, 1, 80, 0, 97, 0, 16, 0, 72, 0, 5, 52, 73, 66, 77, 32, 86,
               71, 65, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>

      {:ok, rip_record} = encode_record(rip_sauce)
      refute is_nil(rip_record)
      assert is_binary(rip_record)
      assert byte_size(rip_record) == 128
      assert :binary.part(rip_record, 0, 5) == "SAUCE"
      assert :binary.part(rip_record, 5, 2) == "00"
      assert rip_record == <<83, 65, 85, 67, 69, 48, 48, 67, 111, 114, 114, 117, 112, 116, 105, 111, 110,
               32, 65, 100, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
               32, 32, 32, 32, 32, 32, 82, 101, 68, 77, 97, 78, 32, 32, 32, 32, 32, 32, 32,
               32, 32, 32, 32, 32, 32, 32, 65, 67, 105, 68, 32, 80, 114, 111, 100, 117, 99,
               116, 105, 111, 110, 115, 32, 32, 32, 32, 49, 57, 57, 52, 48, 56, 50, 57, 233,
               118, 0, 0, 1, 3, 128, 2, 94, 1, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
    end

    test "encode_comments/1 encodes the SAUCE block comments in a SAUCE comment block", %{ansi_sauce: ansi_sauce, rip_sauce: rip_sauce} do
      {:ok, ansi_comments} = encode_comments(ansi_sauce)
      assert byte_size(ansi_comments) == 325
      assert :binary.part(ansi_comments, 0, 5) == "COMNT"

      {:ok, rip_comments} = encode_comments(rip_sauce)
      assert byte_size(rip_comments) == 0
    end
  end

  test "encode_comment_block_line/1 encodes a single SAUCE comment line" do
    comment_line = "hello world"
    encoded_line = encode_comment_block_line(comment_line)

    assert byte_size(encoded_line) == 64
    assert encoded_line === "hello world                                                     "

    max_line = String.pad_trailing("", 64, "1")
    encoded_max_line = encode_comment_block_line(max_line)

    assert byte_size(encoded_max_line) == 64
    assert encoded_max_line == "1111111111111111111111111111111111111111111111111111111111111111"

  end

  test "encode_comment_block_line/1 truncates lines that are too long" do
    comment_line = String.pad_trailing("", 65, "1")
    encoded_line = encode_comment_block_line(comment_line)

    assert byte_size(encoded_line) == 64
    assert encoded_line === "1111111111111111111111111111111111111111111111111111111111111111"

  end

  test "encode_comment_block_line/1 handles unicode" do
    line_1 = encode_comment_block_line("チーズ")
    assert byte_size(line_1) == 64
    assert line_1 == "                                                                "

    line_2 = encode_comment_block_line("チーズ is chizu")
    assert line_2 == " is chizu                                                       "
    assert byte_size(line_2) == 64
  end

end