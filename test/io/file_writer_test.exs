Code.require_file("test/support/sauce_helpers.exs")

defmodule Saucexages.FileWriterTest do
  use ExUnit.Case, async: true
  require Saucexages.Sauce
  require Saucexages.IO.FileReader
  require Saucexages.IO.FileWriter
  alias Saucexages.IO.{FileWriter, FileReader}
  alias Saucexages.{SauceBlock, Sauce}

  setup_all do
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

    %{ansi_block: ansi_block}
  end

  test "write/1 writes a SAUCE block to a file",
       %{ansi_block: ansi_block} do
    write_path = Path.join("tmp", "file_writer/write")
    file_path = Path.join(write_path, "write_block.ans")
    File.rm_rf!(write_path)
    File.mkdir_p!(write_path)
    bin = "hello"
    File.write!(file_path, bin)
    assert FileWriter.write(file_path, ansi_block) == :ok
    %{size: file_size} = File.stat!(file_path)
    assert file_size == byte_size(bin) + Sauce.sauce_byte_size(5) + byte_size(<<Sauce.eof_character()>>)

    assert FileReader.sauce?(file_path) == true
    assert FileReader.comments?(file_path) == true
  end

  test "write/1 transparently updates a SAUCE block",
       %{ansi_block: ansi_block} do
    write_path = Path.join("tmp", "file_writer/write_update")
    file_path = Path.join(write_path, "write_update.ans")
    File.rm_rf!(write_path)
    File.mkdir_p!(write_path)
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

    # write some base content
    bin = "hello"
    File.write!(file_path, bin)

    assert FileWriter.write(file_path, ansi_block) == :ok
    # replace the constructed bin with an updated version that should be different
    assert FileWriter.write(file_path, updated_block) == :ok
    FileReader.sauce?(file_path)
    FileReader.comments?(file_path)
    # read the block in and ensure transparency
    refute FileReader.sauce(file_path) == {:ok, ansi_block}
    assert FileReader.sauce(file_path) == {:ok, updated_block}
  end

  test "remove_comments/1 removes comments from a SAUCE file",
       %{ansi_block: ansi_block} do

    write_path = Path.join("tmp", "file_writer/remove_comments")
    file_path = Path.join(write_path, "remove_comments.ans")
    File.rm_rf!(write_path)
    File.mkdir_p!(write_path)

    # write some base content
    bin = "hello"
    File.write!(file_path, bin)

    FileWriter.write(file_path, ansi_block)

    assert FileReader.comments?(file_path) == true
    assert FileWriter.remove_comments(file_path) == :ok
    assert FileReader.sauce?(file_path) == true
    assert FileReader.comments?(file_path) == false
  end

  test "remove_comments/1 works even if a file has no comments",
       %{ansi_block: ansi_block} do

    write_path = Path.join("tmp", "file_writer/remove_comments")
    file_path = Path.join(write_path, "remove_no_comments.ans")
    File.rm_rf!(write_path)
    File.mkdir_p!(write_path)

    # write some base content
    bin = "hello"
    File.write!(file_path, bin)
    no_comments_block = %{ansi_block | comments: []}
    FileWriter.write(file_path, no_comments_block)

    assert FileReader.comments?(file_path) == false
    assert FileWriter.remove_comments(file_path) == :ok
    assert FileReader.sauce?(file_path) == true
    assert FileReader.comments?(file_path) == false
  end

  test "remove_comments/1 leaves a file untouched if it has no SAUCE" do
    write_path = Path.join("tmp", "file_writer/remove_comments")
    file_path = Path.join(write_path, "remove_no_sauce.ans")
    File.rm_rf!(write_path)
    File.mkdir_p!(write_path)

    # write some base content
    bin = "hello"
    File.write!(file_path, bin)

    assert FileReader.comments?(file_path) == false
    assert FileWriter.remove_comments(file_path) == :ok
    assert FileReader.sauce?(file_path) == false
    assert FileReader.comments?(file_path) == false
  end

  test "remove_sauce/1 removes a SAUCE block from a SAUCE file",
       %{ansi_block: ansi_block} do

    write_path = Path.join("tmp", "file_writer/remove_sauce")
    file_path = Path.join(write_path, "remove_sauce.ans")
    File.rm_rf!(write_path)
    File.mkdir_p!(write_path)

    # write some base content
    bin = <<"hello", Sauce.eof_character>>
    File.write!(file_path, bin)

    FileWriter.write(file_path, ansi_block)

    assert FileReader.sauce?(file_path)
    assert FileReader.comments?(file_path) == true
    assert FileWriter.remove_sauce(file_path) == :ok
    assert FileReader.sauce?(file_path) == false
    assert FileReader.comments?(file_path) == false
    %{size: file_size} = File.stat!(file_path)
    assert file_size == byte_size(bin)
  end

  test "remove_sauce/1 works even if a file has no SAUCE and leaves a file untouched" do
    write_path = Path.join("tmp", "file_writer/remove_sauce")
    file_path = Path.join(write_path, "remove_no_sauce.ans")
    File.rm_rf!(write_path)
    File.mkdir_p!(write_path)

    # write some base content
    bin = "hello"
    File.write!(file_path, bin)

    assert FileReader.sauce?(file_path) == false
    assert {:error, :no_sauce} = FileWriter.remove_sauce(file_path)
    assert FileReader.sauce?(file_path) == false
  end

end