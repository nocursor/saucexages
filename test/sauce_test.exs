defmodule Saucexages.SauceTest do
  use ExUnit.Case, async: true
  doctest Saucexages.Sauce
  import Saucexages.Sauce

  @required_ids [:sauce_id, :version, :data_type, :file_type]

  test "eof_character/0 returns the correct DOS EOF character code" do
    assert eof_character() == 0x1a
  end

  test "field_size/1 returns field sizes according to SAUCE spec layout" do
    assert field_size(:sauce_id) == 5
    assert field_size(:version) == 2
    assert field_size(:title) == 35
    assert field_size(:author) == 20
    assert field_size(:group) == 20
    assert field_size(:date) == 8
    assert field_size(:file_size) == 4
    assert field_size(:data_type) == 1
    assert field_size(:file_type) == 1
    assert field_size(:t_info_1) == 2
    assert field_size(:t_info_2) == 2
    assert field_size(:t_info_3) == 2
    assert field_size(:t_info_4) == 2
    assert field_size(:comment_lines) == 1
    assert field_size(:t_flags) == 1
    assert field_size(:t_info_s) == 22
  end

  test "field_list/0 returns a full list of SAUCE record fields" do
    field_list = field_list()
    assert field_list |> Enum.count() == 16
  end

  test "field_position/2 returns the correct position offset for a SAUCE field" do
    assert field_position(:sauce_id) == 0
    assert field_position(:version) == 5
    assert field_position(:title) == 7
    assert field_position(:author) == 42
    assert field_position(:group) == 62
    assert field_position(:date) == 82
    assert field_position(:file_size) == 90
    assert field_position(:data_type) == 94
    assert field_position(:file_type) == 95
    assert field_position(:t_info_1) == 96
    assert field_position(:t_info_2) == 98
    assert field_position(:t_info_3) == 100
    assert field_position(:t_info_4) == 102
    assert field_position(:comment_lines) == 104
    assert field_position(:t_flags) == 105
    assert field_position(:t_info_s) == 106
  end

  test "field_position/2 returns the correct position offset for a SAUCE field from the ID field" do
    assert field_position(:version, true) == 0
    assert field_position(:title, true) == 2
    assert field_position(:author, true) == 37
    assert field_position(:group, true) == 57
    assert field_position(:date, true) == 77
    assert field_position(:file_size, true) == 85
    assert field_position(:data_type, true) == 89
    assert field_position(:file_type, true) == 90
    assert field_position(:t_info_1, true) == 91
    assert field_position(:t_info_2, true) == 93
    assert field_position(:t_info_3, true) == 95
    assert field_position(:t_info_4, true) == 97
    assert field_position(:comment_lines, true) == 99
    assert field_position(:t_flags, true) == 100
    assert field_position(:t_info_s, true) == 101
  end

  test "required_fields/0 returns a list of required fields required by SAUCE" do
    field_ids = required_fields() |> Enum.map(fn (%{field_id: field_id}) -> field_id end)

    assert (@required_ids -- field_ids) == []
  end

  test "required_field_ids/0 returns a list of required field ids required by SAUCE" do
    field_ids = required_field_ids()
    assert (@required_ids -- field_ids) == []
  end

  test "sauce_version/0 returns the SAUCE spec default version" do
    assert sauce_version() == "00"
  end

  test "sauce_id/0 returns the SAUCE spec SAUCE ID" do
    assert sauce_id() == "SAUCE"
  end

  test "comment_id/0 returns the SAUCE spec Comment block ID" do
    assert comment_id() == "COMNT"
  end

  test "comment_id_byte_size/0 returns the byte size of a SAUCE block Comment ID" do
    assert comment_id_byte_size() == 5
  end

  test "comments_byte_size/1 returns the total byte size for variable amounts of comment lines" do
    assert comments_byte_size(1) == 64
    assert comments_byte_size(2) == 128
    assert comments_byte_size(0) == 0
    assert comments_byte_size(255) == (255 * 64)
    assert_raise ArgumentError, fn ->
      comments_byte_size(-1)
    end
    assert_raise ArgumentError, fn ->
      comments_byte_size(256)
    end
  end

  test "max_comment_lines/0 returns the total number of comment lines according to the SAUCE spec" do
    assert max_comment_lines() == 255
  end

  test "sauce_record_byte_size/0 returns the byte size of a SAUCE record according to the SAUCE spec" do
    assert sauce_record_byte_size() == 128
  end

  test "sauce_data_byte_size/0 returns the byte size of a SAUCE record without the SAUCE ID according to the SAUCE spec" do
    assert sauce_data_byte_size() == (128 - 5)
  end

  test "sauce_id_byte_size/0 returns the byte size of a SAUCE record SAUCE ID according to the SAUCE spec" do
    assert sauce_id_byte_size() == 5
  end

  test "sauce_byte_size/1 returns the byte size of a SAUCE including the given comment lines" do
    assert sauce_byte_size(1) == 197
    assert sauce_byte_size(2) == 261
    assert sauce_byte_size(0) == 128
    assert_raise ArgumentError, fn ->
      sauce_byte_size(-1)
    end
    assert_raise ArgumentError, fn ->
      sauce_byte_size(256)
    end
  end

  test "comment_block_byte_size/1 returns the byte size of a SAUCE comment block given comment lines" do
    assert comment_block_byte_size(1) == 69
    assert comment_block_byte_size(2) == 133
    assert comment_block_byte_size(0) == 0
    assert_raise ArgumentError, fn ->
      comment_block_byte_size(-1)
    end
    assert_raise ArgumentError, fn ->
      comment_block_byte_size(256)
    end
  end

  test "minimum_comment_block_byte_size/0 returns the byte size of a comment block with at least 1 comment" do
    assert minimum_comment_block_byte_size() == 69
  end

  test "minimum_commented_sauce_size/0 returns the byte size of a SAUCE block with at least 1 comment" do
    assert minimum_commented_sauce_size() == 197
  end

  test "file_size_limit/0 returns the maximum SAUCE file size supported" do
    assert file_size_limit() == 4294967295
  end


end
