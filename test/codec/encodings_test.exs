defmodule Saucexages.EncodingsTest do
  use ExUnit.Case, async: true
  import Saucexages.Codec.Encodings


  test "encoding/1 returns the appropriate codepage name for an alias for wrapping Codepagex" do
    assert encoding(:ascii) == "VENDORS/MISC/US-ASCII-QUOTES"
    assert encoding(:cp437) == "VENDORS/MICSFT/PC/CP437"
    assert encoding(:utf8) == "UTF8"
  end

  test "aliases/0 returns a list of all aliases available for encoding/decoding" do
    assert aliases() -- [:ascii, :cp437, :utf8] == []
  end

end