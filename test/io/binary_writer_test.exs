Code.require_file("test/support/sauce_helpers.exs")

defmodule Saucexages.BinaryWriterTest do
  use ExUnit.Case, async: true
  require Saucexages.IO.SauceBinary
  require Saucexages.Sauce
  require Saucexages.IO.BinaryReader
  require Saucexages.IO.BinaryWriter
  alias Saucexages.IO.{BinaryWriter, BinaryReader, SauceBinary}
  alias Saucexages.{SauceBlock, Sauce}

  setup_all do
    ansi_bin = SaucePack.path(:ansi)
               |> File.read!()
    no_comments_bin = SaucePack.path(:ansi_nocomments)
                      |> File.read!()

    ansi_block = %SauceBlock{
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

    %{ansi_bin: ansi_bin, no_comments_bin: no_comments_bin, ansi_block: ansi_block}
  end

  test "write/1 writes a SAUCE block to a binary",
       %{ansi_block: ansi_block} do
    bin = <<1, 2, 3, 4>>
    assert {:ok, updated_bin} = BinaryWriter.write(bin, ansi_block)
    assert byte_size(bin) + Sauce.sauce_byte_size(5) + byte_size(<<Sauce.eof_character()>>) ==
             byte_size(updated_bin)
    assert SauceBinary.sauce?(updated_bin) == true
    assert SauceBinary.comments?(updated_bin) == true
  end

  test "write/1 writes an update SAUCE block",
       %{ansi_block: ansi_block} do
    dt = Date.utc_today()
    updated_block = %{
      ansi_block |
      author: "Mass Delusion",
      comments: ["I meant no", "offense,", "just a test"],
      date: dt,
      group: "iCE Advertisments",
      title: "iCE Advertisments 1994 Member List",
      media_info: %Saucexages.MediaInfo{
        file_size: 999,
        file_type: 2,
        data_type: 2,
        t_flags: 16,
        t_info_1: 77,
        t_info_2: 96,
        t_info_3: 32,
        t_info_4: 69,
        t_info_s: "rack of lamb",
      }
    }

    bin = <<1, 2, 3, 4>>
    assert {:ok, sauced_bin} = BinaryWriter.write(bin, ansi_block)
    # replace the constructed bin with an updated version that should be different
    assert {:ok, updated_bin} = BinaryWriter.write(sauced_bin, updated_block)
    assert SauceBinary.sauce?(updated_bin) == true
    assert SauceBinary.comments?(updated_bin) == true
    refute bin == updated_bin
    refute sauced_bin == updated_bin
    assert byte_size(bin) + Sauce.sauce_byte_size(3) + byte_size(<<Sauce.eof_character()>>) ==
             byte_size(updated_bin)
  end

  test "write/1 writes a SAUCE block that can be transparently read",
       %{ansi_bin: ansi_bin} do
    dt = Date.utc_today()
    {:ok, sauce_block} = BinaryReader.sauce(ansi_bin)

    updated_block = %{
      sauce_block |
      author: "Mass Delusion",
      comments: ["I meant no", "offense,", "just a test"],
      date: dt,
      group: "iCE Advertisments",
      title: "iCE Advertisments 1994 Member List",
      media_info: %Saucexages.MediaInfo{
        file_size: 999,
        file_type: 2,
        data_type: 2,
        t_flags: 16,
        t_info_1: 77,
        t_info_2: 96,
        t_info_3: 32,
        t_info_4: 69,
        t_info_s: "rack of lamb",
      }
    }

    assert {:ok, updated_bin} = BinaryWriter.write(ansi_bin, updated_block)
    assert {:ok, new_sauce_block} = BinaryReader.sauce(updated_bin)
    refute sauce_block == new_sauce_block
    assert new_sauce_block == updated_block
  end

  test "remove_comments/1 removes comments from a SAUCE binary",
       %{ansi_bin: ansi_bin} do
    assert SauceBinary.comments?(ansi_bin) == true
    assert {:ok, no_comments_bin} = BinaryWriter.remove_comments(ansi_bin)
    assert SauceBinary.sauce?(no_comments_bin) == true
    assert SauceBinary.comments?(no_comments_bin) == false
  end

  test "remove_comments/1 removes comments doesn't need to know if a SAUCE has comments",
       %{no_comments_bin: no_comments_bin} do
    assert SauceBinary.comments?(no_comments_bin) == false
    assert {:ok, updated_bin} = BinaryWriter.remove_comments(no_comments_bin)
    assert SauceBinary.sauce?(updated_bin)
    assert SauceBinary.comments?(updated_bin) == false
    # ensure the binary was not tampered with in the process
    assert updated_bin == no_comments_bin
  end

  test "remove_comments/1 removes comments can fix an erroneous comment lines SAUCE record",
       %{no_comments_bin: no_comments_bin} do
    # definitely no comments to start
    assert SauceBinary.comments?(no_comments_bin) == false

    # write some corrupted data
    assert {:ok, corrupted_bin} = SauceBinary.write_field(no_comments_bin, :comment_lines, <<20>>)
    # verify the data was written
    assert {:ok, <<20>>} = SauceBinary.read_field(corrupted_bin, :comment_lines)

    assert {:ok, updated_bin} = BinaryWriter.remove_comments(corrupted_bin)
    assert SauceBinary.sauce?(updated_bin)
    # verify there are definitely no comments
    assert SauceBinary.comments?(updated_bin) == false
    # verify the comment lines field was cleaned properly
    assert {:ok, <<0>>} = SauceBinary.read_field(updated_bin, :comment_lines)
  end

  test "remove_comments/1 leaves a binary untouched if it has no SAUCE" do
    bin = <<1, 2, 3, 4>>
    assert {:ok, updated_bin} = BinaryWriter.remove_comments(bin)
    assert updated_bin == bin
  end

  test "remove_sauce/1 removes a SAUCE block from a binary",
       %{ansi_bin: ansi_bin} do
    assert SauceBinary.sauce?(ansi_bin)
    assert SauceBinary.comments?(ansi_bin)

    assert {:ok, updated_bin} = BinaryWriter.remove_sauce(ansi_bin)

    refute updated_bin == ansi_bin
    assert byte_size(updated_bin) < byte_size(ansi_bin)
    assert SauceBinary.comments?(updated_bin) == false
    assert SauceBinary.sauce?(updated_bin) == false
  end

  test "remove_sauce/1 leaves a binary untouched if it has no SAUCE" do
    bin = <<1, 2, 3, 4>>
    assert {:ok, updated_bin} = BinaryWriter.remove_sauce(bin)
    assert updated_bin == bin
  end

end