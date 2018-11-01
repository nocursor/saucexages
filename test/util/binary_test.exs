defmodule Saucexages.BinaryTest do
  use ExUnit.Case, async: true
  require Saucexages.Util.Binary
  alias Saucexages.Util.Binary

  test "pad_trailing_bytes/3 pads a binary with the correct amount of trailing bytes" do
    assert Binary.pad_trailing_bytes(<<1, 2, 3>>, 6, <<6>>) == <<1, 2, 3, 6, 6, 6>>
    assert Binary.pad_trailing_bytes(<<1, 2, 3>>, 2, <<6>>) == <<1, 2, 3>>
    assert Binary.pad_trailing_bytes(<<1, 2, 3>>, 3, <<6>>) == <<1, 2, 3>>
    assert Binary.pad_trailing_bytes(<<1, 2, 3>>, 4, <<6>>) == <<1, 2, 3, 6>>
    assert Binary.pad_trailing_bytes(<<1, 2, 3>>, 6, <<6, 6, 6>>) == <<1, 2, 3, 6, 6, 6>>
    assert Binary.pad_trailing_bytes(<<1, 2, 3>>, 2, <<6, 6, 6>>) == <<1, 2, 3>>
    assert Binary.pad_trailing_bytes(<<1, 2, 3>>, 4, <<6, 6, 6>>) == <<1, 2, 3, 6>>
    assert Binary.pad_trailing_bytes(<<1, 2, 3>>, 7, <<6, 6, 6>>) == <<1, 2, 3, 6, 6, 6, 6>>
  end

  test "pad_leading_byte/3 pads a binary with the correct amount of leading bytes" do
    assert Binary.pad_leading_bytes(<<1, 2, 3>>, 6, <<6>>) == <<6, 6, 6, 1, 2, 3>>
    assert Binary.pad_leading_bytes(<<1, 2, 3>>, 2, <<6>>) == <<1, 2, 3>>
    assert Binary.pad_leading_bytes(<<1, 2, 3>>, 3, <<6>>) == <<1, 2, 3>>
    assert Binary.pad_leading_bytes(<<1, 2, 3>>, 4, <<6>>) == <<6, 1, 2, 3>>
    assert Binary.pad_leading_bytes(<<1, 2, 3>>, 6, <<6, 6, 6>>) == <<6, 6, 6, 1, 2, 3>>
    assert Binary.pad_leading_bytes(<<1, 2, 3>>, 2, <<6, 6, 6>>) == <<1, 2, 3>>
    assert Binary.pad_leading_bytes(<<1, 2, 3>>, 4, <<6, 6, 6>>) == <<6, 1, 2, 3>>
    assert Binary.pad_leading_bytes(<<1, 2, 3>>, 7, <<6, 6, 6>>) == <<6, 6, 6, 6, 1, 2, 3>>
  end


  test "pad_truncate/3 pads a binary with the correct amount of bytes" do
    assert Binary.pad_truncate(<<1, 2, 3>>, 6, <<6>>) == <<1, 2, 3, 6, 6, 6>>
    assert Binary.pad_truncate(<<1, 2, 3>>, 3, <<6>>) == <<1, 2, 3>>
    assert Binary.pad_truncate(<<1, 2, 3>>, 4, <<6>>) == <<1, 2, 3, 6>>
    assert Binary.pad_truncate(<<1, 2, 3>>, 5, <<6, 6, 6>>) == <<1, 2, 3, 6, 6>>
    assert Binary.pad_truncate(<<1, 2, 3>>, 6, <<6, 6, 6>>) == <<1, 2, 3, 6, 6, 6>>
    assert Binary.pad_truncate(<<1, 2, 3>>, 4, <<6, 6, 6>>) == <<1, 2, 3, 6>>
    assert Binary.pad_truncate(<<1, 2, 3>>, 7, <<6, 6, 6>>) == <<1, 2, 3, 6, 6, 6, 6>>
  end

  test "pad_truncate/3 truncates a binary with the correct amount of bytes" do
    assert Binary.pad_truncate(<<1, 2, 3>>, 2, <<6>>) == <<1, 2>>
    assert Binary.pad_truncate(<<1, 2, 3>>, 2, <<6, 6, 6>>) == <<1, 2>>
    assert Binary.pad_truncate(<<1, 2, 3>>, 3, <<6, 6, 6>>) == <<1, 2, 3>>
    assert Binary.pad_truncate(<<1, 2, 3>>, 4, <<6, 6, 6>>) == <<1, 2, 3, 6>>
  end

  test "replace_binary_at/3 replaces a binary at a specific position" do
    assert Binary.replace_binary_at(<<1, 2, 3, 4, 5, 6>>, 0, <<7, 8, 9>>) == <<7, 8, 9, 4, 5, 6>>
    assert Binary.replace_binary_at(<<1, 2, 3, 4, 5, 6>>, 1, <<7, 8, 9>>) == <<1, 7, 8, 9, 5, 6>>
    assert Binary.replace_binary_at(<<1, 2, 3, 4, 5, 6>>, 2, <<7, 8, 9>>) == <<1, 2, 7, 8, 9, 6>>
    assert Binary.replace_binary_at(<<1, 2, 3, 4, 5, 6>>, 5, <<7>>) == <<1, 2, 3, 4, 5, 7>>
    assert_raise ArgumentError, fn ->
      Binary.replace_binary_at(<<1, 2, 3, 4, 5, 6>>, 5, <<7, 8>>)
    end
    assert_raise ArgumentError, fn ->
      Binary.replace_binary_at(<<1, 2, 3, 4, 5, 6>>, 6, <<7, 8>>)
    end
  end

end