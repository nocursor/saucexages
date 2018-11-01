Code.require_file("test/support/sauce_helpers.exs")

defmodule Saucexages.BinaryReaderTest do
  use ExUnit.Case, async: true
  require Saucexages.IO.SauceBinary
  require Saucexages.Sauce
  require Saucexages.IO.BinaryReader
  alias Saucexages.IO.{BinaryReader, SauceBinary}
  alias Saucexages.{SauceBlock, Sauce}

  setup_all do
    ansi_bin = SaucePack.path(:ansi)
               |> File.read!()
    no_comments_bin = SaucePack.path(:ansi_nocomments)
                      |> File.read!()

    %{ansi_bin: ansi_bin, no_comments_bin: no_comments_bin}
  end

  test "sauce/1 reads a SAUCE record and returns a SAUCE block", %{ansi_bin: ansi_bin} do
    assert {:ok, sauce_block} = BinaryReader.sauce(ansi_bin)
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

  test "sauce/1 reads a SAUCE record with no comments", %{no_comments_bin: no_comments_bin} do
    assert {:ok, sauce_block} = BinaryReader.sauce(no_comments_bin)
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

  test "sauce/1 returns an error if there is no SAUCE" do
    assert {:error, :no_sauce} = BinaryReader.sauce(<<0, 1, 2, 3>>)
    assert {:error, :no_sauce} = BinaryReader.sauce(<<>>)
    assert {:error, :no_sauce} = BinaryReader.sauce(<<"SAUCE">>)
  end

  test "sauce/1 return an error if there is invalid SAUCE" do
    filler = :binary.copy(<<0>>, Sauce.sauce_data_byte_size())
    assert {:error, :no_sauce} = BinaryReader.sauce(<<"SAUCE", filler :: binary>>)
  end

  test "raw/1 returns the raw SAUCE binary", %{ansi_bin: ansi_bin} do
    assert {:ok, {sauce_bin, comments_bin}} = BinaryReader.raw(ansi_bin)
    assert SauceBinary.sauce?(sauce_bin) == true
    assert SauceBinary.comments_fragment?(comments_bin) == true
  end

  test "comments/1 returns the comments from a SAUCE block", %{ansi_bin: ansi_bin} do
    assert {:ok, comments} = BinaryReader.comments(ansi_bin)
    assert comments == [
             "test notes",
             "second line",
             "more test",
             "",
             "after a blank line"
           ]
  end

  test "contents/1 returns the contents of a binary containing a SAUCE without the SAUCE block", %{ansi_bin: ansi_bin} do
    assert {:ok, contents} = BinaryReader.contents(ansi_bin)
    # the byte size of contents should be the file - the sauce contents, or in other words adding them back should be the same as the full file
    assert byte_size(contents) + Sauce.sauce_byte_size(5) == byte_size(ansi_bin)
  end

  test "contents/1 returns the contents of a binary without a sauce", %{ansi_bin: ansi_bin} do
    assert {:ok, contents} = BinaryReader.contents(<<1, 2, 3, 4, 5>>)
    assert contents == <<1, 2, 3, 4, 5>>
    assert {:ok, contents_2} = BinaryReader.contents(ansi_bin)
    assert {:ok, contents_3} = BinaryReader.contents(contents_2)
    assert contents_3 == contents_2
  end

  test "comments?/1 checks if a binary has comments", %{ansi_bin: ansi_bin} do
    assert BinaryReader.comments?(ansi_bin) == true
    assert BinaryReader.comments?(<<>>) == false
  end

  test "comments?/1 returns false for comment fragments", %{ansi_bin: ansi_bin} do
    {:ok, {comments, 5}} = SauceBinary.comments(ansi_bin)
    # a comments fragment is not considered a comment because it cannot stand alone without the SAUCE as a header
    assert BinaryReader.comments?(comments) == false
  end

  test "comments?/1 returns true for a full SAUCE block with comments", %{ansi_bin: ansi_bin} do
    assert {:ok, sauce_block_bin} = SauceBinary.sauce_block(ansi_bin)
    assert BinaryReader.comments?(sauce_block_bin) == true
  end

  test "sauce?/1 checks if a binary has a SAUCE record", %{ansi_bin: ansi_bin} do
    assert BinaryReader.sauce?(ansi_bin) == true
    assert BinaryReader.sauce?(<<>>) == false
    assert BinaryReader.sauce?(<<"SAUCE">>) == false

    filler = :binary.copy(<<0>>, Sauce.sauce_data_byte_size())
    assert BinaryReader.sauce?(<<Sauce.sauce_id(), filler :: binary - size(Sauce.sauce_data_byte_size())>>) == false
  end

end