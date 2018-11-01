Code.require_file("test/support/sauce_helpers.exs")

defmodule Saucexages.FileReaderTest do
  use ExUnit.Case, async: true
  require Saucexages.IO.SauceBinary
  require Saucexages.Sauce
  require Saucexages.IO.FileReader
  alias Saucexages.IO.{FileReader, SauceBinary}
  alias Saucexages.{SauceBlock, Sauce}

  setup do
    ansi_path = SaucePack.path(:ansi)
    no_sauce_path = SaucePack.path(:no_sauce)
    bad_sauce_path = SaucePack.path(:invalid_sauce)
    no_comments_path = SaucePack.path(:ansi_nocomments)
    %{ansi_path: ansi_path, no_sauce_path: no_sauce_path, bad_sauce_path: bad_sauce_path, no_comments_path: no_comments_path}
  end

  test "sauce/1 reads a SAUCE record and returns a SAUCE block",
       %{ansi_path: ansi_path} do
    assert {:ok, sauce_block} = FileReader.sauce(ansi_path)
    assert sauce_block == %SauceBlock{
             author: "",
             comments: ["test notes", "second line", "more test", "",
               "after a blank line"],
             date: ~D[1994-08-31],
             media_info: %Saucexages.MediaInfo{
               data_type: 1,
               file_size: 8900,
               file_type: 1,
               t_flags: 0,
               t_info_1: 80,
               t_info_2: 97,
               t_info_3: 16,
               t_info_4: 0,
               t_info_s: nil
             },
             group: "ACiD Productions",
             title: "ACiD 1994 Member/Board Listing",
             version: "00"
           }
  end

  test "sauce/1 reads a SAUCE record with no comments",
       %{no_comments_path: no_comments_path} do
    assert {:ok, sauce_block} = FileReader.sauce(no_comments_path)
    assert sauce_block == %SauceBlock{
             author: "Lord Jazz",
             comments: [],
             date: ~D[1996-10-01],
             media_info: %Saucexages.MediaInfo{
               data_type: 1,
               file_size: 35659,
               file_type: 1,
               t_flags: 0,
               t_info_1: 80,
               t_info_2: 155,
               t_info_3: 16,
               t_info_4: 0,
               t_info_s: nil
             },
             group: "ACiD Productions",
             title: "Neosporin",
             version: "00"
           }
  end

  test "sauce/1 returns an error if there is no SAUCE",
       %{no_sauce_path: no_sauce_path} do
    assert {:error, :no_sauce} = FileReader.sauce(no_sauce_path)
    assert {:error, :no_sauce} = FileReader.sauce(__ENV__.file)
  end

  test "sauce/1 return an error if there is invalid SAUCE",
       %{bad_sauce_path: bad_sauce_path} do
    assert {:error, :no_sauce} = FileReader.sauce(bad_sauce_path)
  end

  test "raw/1 returns the raw SAUCE binary", %{ansi_path: ansi_path} do
    assert {:ok, {sauce_bin, comments_bin}} = FileReader.raw(ansi_path)
    assert SauceBinary.sauce?(sauce_bin) == true
    assert SauceBinary.comments_fragment?(comments_bin) == true
  end

  test "comments/1 returns the comments from a SAUCE block",
       %{ansi_path: ansi_path} do
    assert {:ok, comments} = FileReader.comments(ansi_path)
    assert comments == [
             "test notes",
             "second line",
             "more test",
             "",
             "after a blank line"
           ]
  end

  test "contents/1 returns the contents of a file containing a SAUCE without the SAUCE block",
       %{ansi_path: ansi_path} do
    assert {:ok, contents} = FileReader.contents(ansi_path)
    # the byte size of contents should be the file - the sauce contents, or in other words adding them back should be the same as the full file
    %{size: file_size} = File.stat!(ansi_path)
    assert byte_size(contents) + Sauce.sauce_byte_size(5) == file_size
  end

  test "contents/1 returns the contents of a file without a sauce", %{no_sauce_path: no_sauce_path} do
    %{size: file_size} = File.stat!(no_sauce_path)
    assert {:ok, contents} = FileReader.contents(no_sauce_path)
    assert byte_size(contents) == file_size
  end
#
  test "comments?/1 checks if a binary has comments",
       %{ansi_path: ansi_path, no_comments_path: no_comments_path} do
    assert FileReader.comments?(ansi_path) == true
    assert FileReader.comments?(no_comments_path) == false
  end

#
  test "sauce?/1 checks if a file has a SAUCE record",
       %{ansi_path: ansi_path, no_comments_path: no_comments_path, no_sauce_path: no_sauce_path} do
    assert FileReader.sauce?(ansi_path) == true
    assert FileReader.sauce?(no_comments_path) == true
    assert FileReader.sauce?(no_sauce_path) == false
  end

end