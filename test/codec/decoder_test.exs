defmodule Saucexages.DecoderTest do
  use ExUnit.Case, async: true
  import Saucexages.Codec.Decoder
  require Codepagex
  require Saucexages.Sauce
  alias Codepagex
  alias Saucexages.{Sauce, SauceBlock}

  describe "decoding a SAUCE block" do
    setup do
      record_bin = <<83, 65, 85, 67, 69, 48, 48, 65, 67, 105, 68, 32, 49, 57, 57, 52, 32, 77, 101,
        109, 98, 101, 114, 47, 66, 111, 97, 114, 100, 32, 76, 105, 115, 116, 105,
        110, 103, 32, 32, 32, 32, 32, 82, 97, 68, 32, 77, 97, 78, 32, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32, 65, 67, 105, 68, 32, 80, 114, 111, 100, 117,
        99, 116, 105, 111, 110, 115, 32, 32, 32, 32, 49, 57, 57, 52, 48, 56, 51, 49,
        196, 34, 0, 0, 1, 1, 80, 0, 97, 0, 16, 0, 72, 0, 5, 52, 73, 66, 77, 32, 86,
        71, 65, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>

      comment_block_bin = <<67, 79, 77, 78, 84, 116, 101, 115, 116, 32, 110, 111, 116, 101, 115, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 115, 101, 99, 111,
        110, 100, 32, 108, 105, 110, 101, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
        32, 32, 32, 32, 109, 111, 114, 101, 32, 116, 101, 115, 116, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
        32, 97, 102, 116, 101, 114, 32, 97, 32, 98, 108, 97, 110, 107, 32, 108, 105,
        110, 101, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32, 32, 32, 32, 32>>

      record = %Saucexages.SauceRecord{
        author: "RaD MaN",
        comment_lines: 5,
        data_type: 1,
        date: ~D[1994-08-31],
        file_size: 8900,
        file_type: 1,
        group: "ACiD Productions",
        t_flags: 52,
        t_info_1: 80,
        t_info_2: 97,
        t_info_3: 16,
        t_info_4: 72,
        t_info_s: "IBM VGA",
        title: "ACiD 1994 Member/Board Listing",
        version: "00"
      }

      # here we have a comment that has a missing line, a quote, and is more than 1 comment which covers the vast majority of "bs"
      comments = ["test notes", "second line", "more test", "", "after a blank line"]


      %{record_bin: record_bin, comment_block_bin: comment_block_bin, record: record, comments: comments}
    end

    test "decode_record/1 decodes a SAUCE record binary", %{record_bin: record_bin, record: record} do
      {:ok, decoded_record} = decode_record(record_bin)
      assert is_map(decoded_record)
      assert decoded_record == record
    end

    test "decode_record/1 responds with an error if it encounters bad SAUCE data", %{record_bin: record_bin} do
      # SAUCE ID but without enough data....
      assert decode_record("SAUCE") == {:error, :no_sauce}

      # SAUCE but missing everything. Everything can be zero really but the version.
      filler = :binary.copy(<<0>>, Sauce.sauce_data_byte_size())
      bad_sauce = <<Sauce.sauce_id(), filler::binary-size(Sauce.sauce_data_byte_size())>>
      assert decode_record(bad_sauce) == {:error, :invalid_sauce}

      # Adding extra data to the end no longer makes it valid SAUCE
      assert decode_record(<<record_bin::binary-size(Sauce.sauce_record_byte_size()), 0>>) == {:error, :no_sauce}

      # An invalid SAUCE ID
      <<_sauce_id::binary-size(5), sauce_data::binary-size(Sauce.sauce_data_byte_size())>> = record_bin
      assert decode_record(<<"SAUCK", sauce_data::binary-size(Sauce.sauce_data_byte_size())>>) == {:error, :no_sauce}
    end

    test "decode_sauce/2 decodes a SauceRecord and a list of comments, transforming it into a SauceBlock",
         %{record: record, comments: comments} do
      {:ok, sauce_block} = decode_sauce(record, comments)
      assert is_map(sauce_block)

      assert sauce_block ==
               %SauceBlock{
                 comments: comments,
                 author: "RaD MaN",
                 title: "ACiD 1994 Member/Board Listing",
                 version: "00",
                 date: ~D[1994-08-31],
                 group: "ACiD Productions",
                 media_info: %Saucexages.MediaInfo{
                   data_type: 1,
                   file_size: 8900,
                   file_type: 1,
                   t_flags: 52,
                   t_info_1: 80,
                   t_info_2: 97,
                   t_info_3: 16,
                   t_info_4: 72,
                   t_info_s: "IBM VGA",
                 }
               }
    end

    test "decode_comments/2 decodes a SAUCE comment block",
         %{comment_block_bin: comment_block_bin, comments: comments} do
      {:ok, decoded_comments} = decode_comments(comment_block_bin, Enum.count(comments))
      assert is_list(decoded_comments)
      assert decoded_comments == comments
    end

    test "decode_comments/2 can handle an invalid comment pointer that is less than the size of the comment block",
         %{comment_block_bin: comment_block_bin, comments: comments} do
      {:ok, decoded_comments} = decode_comments(comment_block_bin, Enum.count(comments) - 1)
      assert is_list(decoded_comments)
      assert decoded_comments == Enum.take(comments, Enum.count(comments) - 1)

      assert decode_comments(comment_block_bin, 0) == {:ok, []}
    end

    test "decode_comments/2 can handle an invalid comment block" do
      comment_count = 5
      filler = :binary.copy(<<0>>, Sauce.comment_line_byte_size() * comment_count)
      assert decode_comments(<<Sauce.comment_id(), filler::binary>>, comment_count)
             == {:ok, []}
      assert decode_comments(<<"COMNS", filler::binary>>, comment_count)
             == {:error, :no_comments}
      assert decode_comments(filler, comment_count) == {:error, :no_comments}
    end
  end
end