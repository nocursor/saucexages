Code.require_file("test/support/sauce_helpers.exs")

defmodule Saucexages.SaucexagesTest do
  use ExUnit.Case, async: true
  doctest Saucexages
  require Saucexages
  require Saucexages.Sauce

  setup_all do
    ansi_bin = SaucePack.path(:logo_ansi)
               |> File.read!()

    %{ansi_bin: ansi_bin}
  end

  test "sauce/1 reads a SAUCE record and returns a SAUCE block", %{ansi_bin: ansi_bin} do
    assert {:ok, sauce_block} = Saucexages.sauce(ansi_bin)
    assert sauce_block == %Saucexages.SauceBlock{
             author: "No Cursor",
             comments: ["Saucages?Snausages?Saucejes?Alfredo?",
               "Saucexages!Saucexages!Saucexages!"],
             date: ~D[2018-10-31],
             group: "Inconsequential",
             media_info: %Saucexages.MediaInfo{
               data_type: 1,
               file_size: 1236,
               file_type: 1,
               t_flags: 12,
               t_info_1: 80,
               t_info_2: 12,
               t_info_3: 0,
               t_info_4: 0,
               t_info_s: "IBM VGA"
             },
             title: "Saucexages",
             version: "00"
           }
  end

  test "write/1 writes a SAUCE block that can be transparently read",
       %{ansi_bin: ansi_bin} do
    dt = Date.utc_today()
    {:ok, sauce_block} = Saucexages.sauce(ansi_bin)

    updated_block = %{
      sauce_block |
      author: "no cursor",
      comments: ["just one comment now"],
      date: dt,
      group: "semi-consequential",
      title: "poor SAUCE",
      media_info: %Saucexages.MediaInfo{
        file_size: 999,
        file_type: 2,
        data_type: 2,
        t_flags: 16,
        t_info_1: 77,
        t_info_2: 96,
        t_info_3: 32,
        t_info_4: 69,
        t_info_s: "IBM VGA50",
      }
    }

    assert {:ok, updated_bin} = Saucexages.write(ansi_bin, updated_block)
    assert {:ok, new_sauce_block} = Saucexages.sauce(updated_bin)
    refute sauce_block == new_sauce_block
    assert new_sauce_block == updated_block
  end

end