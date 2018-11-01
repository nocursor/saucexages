defmodule Saucexages.SauceBlockTest do
  use ExUnit.Case, async: true
  doctest Saucexages.SauceBlock
  alias Saucexages.{SauceBlock, MediaInfo}

  test "comment_lines/1 returns the number of comment lines in a SAUCE block" do
    comments = ["a", "hello", "to my friend,", " ", "the 5th line"]
    sauce_block = MediaInfo.new(1, 1) |> SauceBlock.new([comments: comments])
    assert SauceBlock.comment_lines(sauce_block) == 5
  end

  test "comment_lines/1 returns the number of comment lines in a list of comments" do
    comments = ["a", "hello", "to my friend,", " ", "the 5th line"]
    assert SauceBlock.comment_lines(comments) == 5
    assert SauceBlock.comment_lines([]) == 0
  end

  test "formatted_comments/1 returns comments as a string with the given separator per line" do
    comments = ["Hello", "Cleveland", "it is time to", "eat lettuceless burritos"]
    assert SauceBlock.formatted_comments(comments) == "Hello\nCleveland\nit is time to\neat lettuceless burritos"
    assert SauceBlock.formatted_comments(comments, ", ") == "Hello, Cleveland, it is time to, eat lettuceless burritos"
    assert SauceBlock.formatted_comments([]) == <<>>
    assert SauceBlock.formatted_comments([], ", ") == <<>>
  end

  test "media_type_id/1 returns the corresponding media_type_id based on data in a SauceBlock" do
    sauce_block = MediaInfo.new(1, 1) |> SauceBlock.new()
    assert SauceBlock.media_type_id(sauce_block) == :ansi

    binary_text_sauce_block = MediaInfo.new(99, 5) |> SauceBlock.new()
    assert SauceBlock.media_type_id(binary_text_sauce_block) == :binary_text

    none_sauce_block = MediaInfo.new(0, 0) |> SauceBlock.new()
    assert SauceBlock.media_type_id(none_sauce_block) == :none
  end

  test "data_type_id/1 returns the corresponding data_type_id based on data in a SauceBlock" do
    sauce_block = MediaInfo.new(1, 1) |> SauceBlock.new()
    assert SauceBlock.data_type_id(sauce_block) == :character

    binary_text_sauce_block = MediaInfo.new(99, 5) |> SauceBlock.new()
    assert SauceBlock.data_type_id(binary_text_sauce_block) == :binary_text

    none_sauce_block = MediaInfo.new(0, 0) |> SauceBlock.new()
    assert SauceBlock.data_type_id(none_sauce_block) == :none
  end

  test "add_comments/2 appends comments to a SAUCE block" do
    sauce_block = MediaInfo.new(1, 1) |> SauceBlock.new([comments: ["hello"]])

    assert Enum.count(sauce_block.comments) == 1
    assert SauceBlock.add_comments(sauce_block, ["world"]).comments |> Enum.count() == 2
    assert SauceBlock.add_comments(sauce_block, ["world"]).comments == ["hello", "world"]

    assert SauceBlock.add_comments(sauce_block, "world").comments |> Enum.count() == 2
    assert SauceBlock.add_comments(sauce_block, "world").comments == ["hello", "world"]

    assert SauceBlock.add_comments(sauce_block, "").comments |> Enum.count() == 2
    assert SauceBlock.add_comments(sauce_block, "").comments == ["hello", ""]

    assert SauceBlock.add_comments(sauce_block, ["world", "it was fun", "", "but now I'm hungry"]).comments |> Enum.count() == 5
    assert SauceBlock.add_comments(sauce_block, []).comments |> Enum.count() == 1

  end

  test "prepend_comment/2 prepends a comment to a SAUCE block" do
    sauce_block = MediaInfo.new(1, 1) |> SauceBlock.new([comments: ["hello"]])

    assert Enum.count(sauce_block.comments) == 1

    commented_block = SauceBlock.prepend_comment(sauce_block, "world")

    assert Enum.count(commented_block.comments) == 2
    assert commented_block.comments == ["world", "hello"]

    assert SauceBlock.prepend_comment(sauce_block, "").comments |> Enum.count() == 2
  end

  test "clear_comments/1 removes all comments from a SAUCE block" do
    sauce_block = MediaInfo.new(1, 1) |> SauceBlock.new([comments: ["hello", "world"]])
    uncommented_block = SauceBlock.clear_comments(sauce_block)

    assert Enum.count(uncommented_block.comments) == 0
    assert SauceBlock.comment_lines(uncommented_block) == 0
  end

  test "details/1 returns a map of detailed sauce block info" do
    sauce_block = %Saucexages.SauceBlock{
      version: "00",
      title: "cheese platter",
      author: "No Cursor",
      group: "Inconsequential",
      date: ~D[1994-01-01],
      media_info: %{
        file_type: 1,
        data_type: 1,
        t_flags: 17,
        t_info_1: 80,
        t_info_2: 250,
        t_info_s: "IBM VGA"
      }
    }
    assert Saucexages.SauceBlock.details(sauce_block) == %{
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

  end
end