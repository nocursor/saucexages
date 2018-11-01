Code.require_file("test/support/sauce_helpers.exs")

defmodule Saucexages.BinaryReaderRegressionTest do
  use ExUnit.Case, async: true
  require Saucexages.Sauce
  require Saucexages.IO.BinaryReader
  alias Saucexages.IO.{BinaryReader}
  alias Saucexages.{SauceBlock}

  test "read an ansi with comments" do
    bin = SaucePack.path(:ansi)
          |> File.read!()
    assert {:ok, sauce_block} = BinaryReader.sauce(bin)
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

  test "read an ansi with no comments" do
    bin = SaucePack.path(:ansi_nocomments)
          |> File.read!()
    assert {:ok, sauce_block} = BinaryReader.sauce(bin)
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

  test "read an ascii" do
    bin = SaucePack.path(:ascii)
          |> File.read!()
    assert {:ok, sauce_block} = BinaryReader.sauce(bin)
    assert sauce_block == %SauceBlock{
             author: "Lord Jazz",
             comments: [],
             date: ~D[1995-07-26],
             media_info: %Saucexages.MediaInfo{
               data_type: 1,
               file_size: 1201,
               file_type: 1,
               t_flags: 0,
               t_info_1: 80,
               t_info_2: 25,
               t_info_3: 0,
               t_info_4: 0,
               t_info_s: nil
             },
             group: "Bleach",
             title: "Tide Promotional",
             version: "00"
           }
  end

  test "read an xbin" do
    bin = SaucePack.path(:xbin)
          |> File.read!()
    assert {:ok, sauce_block} = BinaryReader.sauce(bin)
    assert sauce_block == %SauceBlock{
             author: "ACiD Staff",
             comments: [],
             date: nil,
             media_info: %Saucexages.MediaInfo{
               data_type: 6,
               file_size: 14500,
               file_type: 0,
               t_flags: 0,
               t_info_1: 80,
               t_info_2: 252,
               t_info_3: 0,
               t_info_4: 0,
               t_info_s: nil
             },
             group: "ACiD Productions",
             title: "September 1996 Member/Site Listing",
             version: "00"
           }
  end

  test "read a gif" do
    bin = SaucePack.path(:gif)
          |> File.read!()
    assert {:ok, sauce_block} = BinaryReader.sauce(bin)
    assert sauce_block == %SauceBlock{
             author: "Cat",
             comments: [],
             date: ~D[1995-01-01],
             media_info: %Saucexages.MediaInfo{
               data_type: 2,
               file_size: 147963,
               file_type: 0,
               t_flags: 0,
               t_info_1: 480,
               t_info_2: 640,
               t_info_3: 8,
               t_info_4: 0,
               t_info_s: nil
             },
             group: "ACiD Productions",
             title: "The BadLands",
             version: "00"
           }
  end


  test "read a bin" do
    bin = SaucePack.path(:bin)
          |> File.read!()
    assert {:ok, sauce_block} = BinaryReader.sauce(bin)
    assert sauce_block == %SauceBlock{
             author: "Halaster",
             comments: [],
             date: ~D[1995-04-01],
             media_info: %Saucexages.MediaInfo{
               data_type: 5,
               file_size: 19521,
               file_type: 0,
               t_flags: 0,
               t_info_1: 160,
               t_info_2: 61,
               t_info_3: 16,
               t_info_4: 0,
               t_info_s: nil
             },
             group: "ACiD Productions",
             title: "Harvest Moon",
             version: "00"
           }
  end

  test "read a rip" do
    bin = SaucePack.path(:rip)
          |> File.read!()
    assert {:ok, sauce_block} = BinaryReader.sauce(bin)
    assert sauce_block == %SauceBlock{
             author: "Peak Velocity",
             comments: [],
             date: ~D[1995-07-13],
             media_info: %Saucexages.MediaInfo{
               data_type: 1,
               file_size: 31796,
               file_type: 3,
               t_flags: 0,
               t_info_1: 640,
               t_info_2: 350,
               t_info_3: 16,
               t_info_4: 0,
               t_info_s: nil
             },
             group: "Union",
             title: "phear da k0w - Union '95",
             version: "00"
           }
  end

  test "read a txt" do
    bin = SaucePack.path(:txt)
          |> File.read!()
    assert {:ok, sauce_block} = BinaryReader.sauce(bin)
    assert sauce_block == %SauceBlock{
             author: "Tasmaniac",
             comments: [],
             date: ~D[1996-08-01],
             media_info: %Saucexages.MediaInfo{
               data_type: 1,
               file_size: 21032,
               file_type: 0,
               t_flags: 0,
               t_info_1: 80,
               t_info_2: 470,
               t_info_3: 0,
               t_info_4: 0,
               t_info_s: nil
             },
             group: "ACiD Productions",
             title: "eXtended BIN format specification",
             version: "00"
           }
  end

  test "read an s3m" do
    bin = SaucePack.path(:s3m)
          |> File.read!()
    assert {:ok, sauce_block} = BinaryReader.sauce(bin)
    assert sauce_block == %SauceBlock{
             author: "Xenoc",
             comments: [],
             date: ~D[1995-11-13],
             media_info: %Saucexages.MediaInfo{
               data_type: 4,
               file_size: 245728,
               file_type: 3,
               t_flags: 0,
               t_info_1: 80,
               t_info_2: 25,
               t_info_3: 0,
               t_info_4: 0,
               t_info_s: nil
             },
             group: "ROC",
             title: "Slowly Descending",
             version: "00"
           }
  end

  #TODO: more formats and examples

end