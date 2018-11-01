Code.require_file("test/support/sauce_helpers.exs")

defmodule Saucexages.SauceBinaryTest do
  use ExUnit.Case, async: true
  require Saucexages.IO.SauceBinary
  require Saucexages.Sauce
  alias Saucexages.IO.SauceBinary
  alias Saucexages.Sauce

  test "split_all/1 splits a binary containing a SAUCE into its 3 parts" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()

    {contents_bin, sauce_bin, comment_bin} = SauceBinary.split_all(ansi_bin)
    assert is_binary(contents_bin)
    assert is_binary(sauce_bin)
    assert is_binary(comment_bin)

    refute contents_bin == <<>>
    refute sauce_bin == <<>>
    refute comment_bin == <<>>

    assert :binary.part(sauce_bin, 0, 5) == Sauce.sauce_id()
    assert :binary.part(comment_bin, 0, 5) == Sauce.comment_id()
    assert byte_size(sauce_bin) == Sauce.sauce_record_byte_size()
    assert byte_size(comment_bin) >= Sauce.minimum_comment_block_byte_size()
    assert byte_size(contents_bin) < byte_size(ansi_bin)
    assert byte_size(contents_bin) + byte_size(sauce_bin) + byte_size(comment_bin) == byte_size(ansi_bin)
  end

  test "split_all/1 splits a binary without comments" do
    ansi_bin = SaucePack.path(:ansi_nocomments) |> File.read!()
    {contents_bin, sauce_bin, comment_bin} = SauceBinary.split_all(ansi_bin)
    assert is_binary(contents_bin)
    assert is_binary(sauce_bin)
    assert is_binary(comment_bin)

    refute contents_bin == <<>>
    refute sauce_bin == <<>>
    assert comment_bin == <<>>

    assert :binary.part(sauce_bin, 0, 5) == Sauce.sauce_id()
    assert byte_size(sauce_bin) == Sauce.sauce_record_byte_size()

    assert byte_size(contents_bin) + byte_size(sauce_bin) + byte_size(comment_bin) == byte_size(ansi_bin)
  end

  test "split_all/1 splits a binary without a SAUCE" do
    bin = SaucePack.path(:no_sauce) |> File.read!()
    {contents_bin, sauce_bin, comment_bin} = SauceBinary.split_all(bin)
    assert is_binary(contents_bin)
    assert is_binary(sauce_bin)
    assert is_binary(comment_bin)

    refute contents_bin == <<>>
    assert sauce_bin == <<>>
    assert comment_bin == <<>>

    assert byte_size(contents_bin) + byte_size(sauce_bin) + byte_size(comment_bin) == byte_size(bin)
  end

  test "split_sauce/1 splits a binary into only its sauce components" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()

    {sauce_bin, comment_bin} = SauceBinary.split_sauce(ansi_bin)
    assert is_binary(sauce_bin)
    assert is_binary(comment_bin)

    refute sauce_bin == <<>>
    refute comment_bin == <<>>

    assert :binary.part(sauce_bin, 0, 5) == Sauce.sauce_id()
    assert :binary.part(comment_bin, 0, 5) == Sauce.comment_id()
    assert byte_size(sauce_bin) == Sauce.sauce_record_byte_size()
    assert byte_size(comment_bin) >= Sauce.minimum_comment_block_byte_size()
  end

  test "split_sauce/1 splits a binary without SAUCE comments" do
    bin = SaucePack.path(:ansi_nocomments) |> File.read!()
    {sauce_bin, comment_bin} = SauceBinary.split_sauce(bin)
    assert is_binary(sauce_bin)
    assert is_binary(comment_bin)

    refute sauce_bin == <<>>
    assert comment_bin == <<>>

    assert :binary.part(sauce_bin, 0, 5) == Sauce.sauce_id()
    assert byte_size(sauce_bin) == Sauce.sauce_record_byte_size()
  end

  test "split_sauce/1 splits a binary without a SAUCE" do
    bin = SaucePack.path(:no_sauce) |> File.read!()
    {sauce_bin, comment_bin} = SauceBinary.split_sauce(bin)
    assert is_binary(sauce_bin)
    assert is_binary(comment_bin)

    assert sauce_bin == <<>>
    assert comment_bin == <<>>
  end

  test "split_record/1 splits a binary containing a SAUCE into its sauce record and contents" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()

    {contents_bin, sauce_bin} = SauceBinary.split_record(ansi_bin)
    assert is_binary(contents_bin)
    assert is_binary(sauce_bin)

    refute contents_bin == <<>>
    refute sauce_bin == <<>>

    assert :binary.part(sauce_bin, 0, 5) == Sauce.sauce_id()
    assert byte_size(sauce_bin) == Sauce.sauce_record_byte_size()
    assert byte_size(contents_bin) < byte_size(ansi_bin)
  end

  test "split_record/1 splits a binary without comments" do
    ansi_bin = SaucePack.path(:ansi_nocomments) |> File.read!()
    {contents_bin, sauce_bin} = SauceBinary.split_record(ansi_bin)
    assert is_binary(contents_bin)
    assert is_binary(sauce_bin)

    refute contents_bin == <<>>
    refute sauce_bin == <<>>

    assert :binary.part(sauce_bin, 0, 5) == Sauce.sauce_id()
    assert byte_size(sauce_bin) == Sauce.sauce_record_byte_size()
    assert byte_size(contents_bin) < byte_size(ansi_bin)
  end

  test "split_record/1 splits a binary without a SAUCE" do
    bin = SaucePack.path(:no_sauce) |> File.read!()
    {contents_bin, sauce_bin} = SauceBinary.split_record(bin)
    assert is_binary(contents_bin)
    assert is_binary(sauce_bin)

    refute contents_bin == <<>>
    assert sauce_bin == <<>>
    assert byte_size(contents_bin) == byte_size(bin)
  end

  test "split_with/1 splits a binary containing a SAUCE into its 3 parts, using a pre-determined comment line count to split comments" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()

    {contents_bin, sauce_bin, comment_bin} = SauceBinary.split_with(ansi_bin, 5)
    assert is_binary(contents_bin)
    assert is_binary(sauce_bin)
    assert is_binary(comment_bin)

    refute contents_bin == <<>>
    refute sauce_bin == <<>>
    refute comment_bin == <<>>

    assert :binary.part(sauce_bin, 0, 5) == Sauce.sauce_id()
    assert :binary.part(comment_bin, 0, 5) == Sauce.comment_id()
    assert byte_size(sauce_bin) == Sauce.sauce_record_byte_size()
    assert byte_size(comment_bin) >= Sauce.minimum_comment_block_byte_size()
    assert byte_size(contents_bin) < byte_size(ansi_bin)
    assert byte_size(contents_bin) + byte_size(sauce_bin) + byte_size(comment_bin) == byte_size(ansi_bin)
  end

  test "split_with/1 will not return comments if the comment lines count does not match the actual comment lines" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()

    # there are 5 lines, not 2
    {contents_bin, sauce_bin, comment_bin} = SauceBinary.split_with(ansi_bin, 2)
    assert is_binary(contents_bin)
    assert is_binary(sauce_bin)
    assert is_binary(comment_bin)

    refute contents_bin == <<>>
    refute sauce_bin == <<>>
    assert comment_bin == <<>>

    # ensure we still got the SAUCE despite the mistake
    assert :binary.part(sauce_bin, 0, 5) == Sauce.sauce_id()
    assert byte_size(sauce_bin) == Sauce.sauce_record_byte_size()
  end

  test "clean_contents/1 returns contents before any EOF character, if one exists" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()
    contents_bin = SauceBinary.clean_contents(ansi_bin)

    assert is_binary(contents_bin)
    refute contents_bin == <<>>
    assert byte_size(contents_bin) < byte_size(ansi_bin)
    assert :binary.match(contents_bin, <<Sauce.eof_character()>>) == :nomatch

    assert SauceBinary.clean_contents(<<1, 2, 3>>) == <<1, 2, 3>>
  end

  test "contents/1 returns the contents in a SAUCE file" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()
    {:ok, contents_bin} = SauceBinary.contents(ansi_bin)

    assert is_binary(contents_bin)
    refute contents_bin == <<>>
    assert byte_size(contents_bin) < byte_size(ansi_bin)
    #maintains the EOF character as part of the contents
    refute :binary.match(contents_bin, <<Sauce.eof_character()>>) == :nomatch

    assert SauceBinary.contents(<<1, 2, 3>>) == {:ok, <<1, 2, 3>>}
    # Force eof termination, for example when we want to re-write a binary to disk or treat EOF uniformly elsewhere
    assert SauceBinary.contents(<<1, 2, 3>>, true) == {:ok, <<1, 2, 3, Sauce.eof_character()>>}
  end

  test "contents_size/1 returns the contents size in a SAUCE file" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()
    contents_size = SauceBinary.contents_size(ansi_bin)
    assert contents_size > 0
    assert contents_size < byte_size(ansi_bin)
  end

  test "maybe_sauce_record/1 returns data if the given binary is a SAUCE record" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()
    {:ok, sauce_bin} = SauceBinary.sauce_record(ansi_bin)
    assert SauceBinary.maybe_sauce_record(sauce_bin)
    assert SauceBinary.maybe_sauce_record(<<1, 2, 3>>) == <<>>
  end

  test "maybe_comments/1 returns data if the given binary is a SAUCE comments block" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()
    {:ok, {comments_bin, _}} = SauceBinary.comments(ansi_bin)
    assert SauceBinary.maybe_comments(comments_bin)
    assert SauceBinary.maybe_comments(<<1, 2, 3>>) == <<>>
  end

  test "matches_sauce?/1 returns if the given binary is a SAUCE record" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()
    {:ok, sauce_bin} = SauceBinary.sauce_record(ansi_bin)
    assert SauceBinary.matches_sauce?(sauce_bin) == true
    assert SauceBinary.matches_sauce?(<<1, 2, 3>>) == false
  end

  test "matches_comment_block?/1 returns if the given binary is a SAUCE comments block" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()
    {:ok, {comments_bin, _}} = SauceBinary.comments(ansi_bin)
    assert SauceBinary.matches_comment_block?(comments_bin) == true
    assert SauceBinary.matches_comment_block?(<<1, 2, 3>>) == false
  end

  test "verify_sauce_record/1 checks if the given binary is a SAUCE record" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()
    {:ok, sauce_bin} = SauceBinary.sauce_record(ansi_bin)
    assert SauceBinary.verify_sauce_record(sauce_bin) == :ok
    assert SauceBinary.verify_sauce_record(<<1, 2, 3>>) == {:error, :no_sauce}
  end

  test "verify_comment_block/1 returns if the given binary is a SAUCE comments block" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()
    {:ok, {comments_bin, _}} = SauceBinary.comments(ansi_bin)
    assert SauceBinary.verify_comment_block(comments_bin) == :ok
    assert SauceBinary.verify_comment_block(<<1, 2, 3>>) == {:error, :no_comments}
  end

  test "read_field!/2 dynamically reads and returns raw SAUCE fields" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()
    {:ok, sauce_bin} = SauceBinary.sauce_record(ansi_bin)

    assert SauceBinary.read_field!(sauce_bin, :sauce_id) == "SAUCE"
    assert SauceBinary.read_field!(sauce_bin, :version) == "00"
    assert SauceBinary.read_field!(sauce_bin, :title) == "ACiD 1994 Member/Board Listing     "
    assert SauceBinary.read_field!(sauce_bin, :version) == "00"
    assert SauceBinary.read_field!(sauce_bin, :author) == "                    "
    assert SauceBinary.read_field!(sauce_bin, :group) == "ACiD Productions    "
    assert SauceBinary.read_field!(sauce_bin, :date) == "19940831"
    assert SauceBinary.read_field!(sauce_bin, :file_size) == <<196, 34, 0, 0>>
    assert SauceBinary.read_field!(sauce_bin, :data_type) == <<1>>
    assert SauceBinary.read_field!(sauce_bin, :file_type) == <<1>>
    assert SauceBinary.read_field!(sauce_bin, :t_info_1) == <<80, 0>>
    assert SauceBinary.read_field!(sauce_bin, :t_info_2) == <<97, 0>>
    assert SauceBinary.read_field!(sauce_bin, :t_info_3) == <<16, 0>>
    assert SauceBinary.read_field!(sauce_bin, :t_info_4) == <<0, 0>>
    assert SauceBinary.read_field!(sauce_bin, :comment_lines) == <<5>>
    assert SauceBinary.read_field!(sauce_bin, :t_flags) == <<0>>
    assert SauceBinary.read_field!(sauce_bin, :t_info_s) == <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>

    assert_raise ArgumentError, fn ->
      SauceBinary.read_field!(<<1, 2, 3>>, :sauce_id) end
  end

  test "read_field/2 dynamically reads and returns raw SAUCE fields" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()
    {:ok, sauce_bin} = SauceBinary.sauce_record(ansi_bin)

    assert SauceBinary.read_field(sauce_bin, :sauce_id) == {:ok, "SAUCE"}
    assert SauceBinary.read_field(sauce_bin, :version) == {:ok, "00"}
    assert SauceBinary.read_field(sauce_bin, :title) == {:ok, "ACiD 1994 Member/Board Listing     "}
    assert SauceBinary.read_field(sauce_bin, :version) == {:ok, "00"}
    assert SauceBinary.read_field(sauce_bin, :author) == {:ok, "                    "}
    assert SauceBinary.read_field(sauce_bin, :group) == {:ok, "ACiD Productions    "}
    assert SauceBinary.read_field(sauce_bin, :date) == {:ok, "19940831"}
    assert SauceBinary.read_field(sauce_bin, :file_size) == {:ok, <<196, 34, 0, 0>>}
    assert SauceBinary.read_field(sauce_bin, :data_type) == {:ok, <<1>>}
    assert SauceBinary.read_field(sauce_bin, :file_type) == {:ok, <<1>>}
    assert SauceBinary.read_field(sauce_bin, :t_info_1) == {:ok, <<80, 0>>}
    assert SauceBinary.read_field(sauce_bin, :t_info_2) == {:ok, <<97, 0>>}
    assert SauceBinary.read_field(sauce_bin, :t_info_3) == {:ok, <<16, 0>>}
    assert SauceBinary.read_field(sauce_bin, :t_info_4) == {:ok, <<0, 0>>}
    assert SauceBinary.read_field(sauce_bin, :comment_lines) == {:ok, <<5>>}
    assert SauceBinary.read_field(sauce_bin, :t_flags) == {:ok, <<0>>}
    assert SauceBinary.read_field(sauce_bin, :t_info_s) == {:ok, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>}

    assert SauceBinary.read_field(<<"SAUCE">>, :sauce_id) == {:error, :no_sauce}
    assert SauceBinary.read_field(<<"SAUCE00">>, :version) == {:error, :no_sauce}
    assert SauceBinary.read_field(<<"SAUCE">>, :title) == {:error, :no_sauce}
    assert SauceBinary.read_field(<<1, 2, 3>>, :author) == {:error, :no_sauce}
    assert SauceBinary.read_field(<<>>, :group) == {:error, :no_sauce}
  end

  test "write_field/3 dynamically writes raw SAUCE fields" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()
    {:ok, sauce_bin} = SauceBinary.sauce_record(ansi_bin)

    assert {:ok, edited_bin} = SauceBinary.write_field(sauce_bin, :title, "ACiD 1994 Member/Board Listing Modified!")
    assert SauceBinary.read_field(edited_bin, :title) == {:ok, "ACiD 1994 Member/Board Listing Modi"}
    author = String.pad_trailing("TASManiac", Sauce.field_size(:author), <<32>>)
    assert {:ok, edited_bin2} = SauceBinary.write_field(sauce_bin, :author, author)
    assert SauceBinary.read_field(edited_bin2, :author) == {:ok, author}

    assert {:error, :no_sauce} = SauceBinary.write_field(<<0, 1>>, :title, "ACiD 1994 Member/Board Listing Modified!")
    # fields data must be of the proper size as this is a raw interface to the binary
    assert_raise ArgumentError, fn -> SauceBinary.write_field(sauce_bin, :title, "Jed, ruler of Ansimation!!!!!!!!") end
  end

  test "sauce_handle/1 retrieves a SAUCE record binary and a line count used as a pointer to retrieve comments" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()

    assert {:ok, {sauce_bin, comment_lines}} = SauceBinary.sauce_handle(ansi_bin)
    assert comment_lines == 5
    refute sauce_bin == <<>>

    assert :binary.part(sauce_bin, 0, 5) == Sauce.sauce_id()
    assert byte_size(sauce_bin) == Sauce.sauce_record_byte_size()
  end

  test "sauce/1 retrieves a SAUCE block binary and returns it as a binary of sauce record and comment block" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()

    assert {:ok, {sauce_bin, comment_bin}} = SauceBinary.sauce(ansi_bin)
    refute comment_bin == <<>>
    refute sauce_bin == <<>>

    assert :binary.part(sauce_bin, 0, 5) == Sauce.sauce_id()
    assert :binary.part(comment_bin, 0, 5) == Sauce.comment_id()
    assert byte_size(sauce_bin) == Sauce.sauce_record_byte_size()
    assert byte_size(comment_bin) == Sauce.comment_block_byte_size(5)
  end

  test "sauce_record/1 returns a SAUCE record binary" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()

    assert {:ok, sauce_bin} = SauceBinary.sauce_record(ansi_bin)
    refute sauce_bin == <<>>

    assert :binary.part(sauce_bin, 0, 5) == Sauce.sauce_id()
    assert byte_size(sauce_bin) == Sauce.sauce_record_byte_size()
    assert SauceBinary.sauce_record(<<1, 2, 3>>) == {:error, :no_sauce}
  end

  test "sauce_record!/1 returns a SAUCE record binary with no error info" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()

    assert sauce_bin = SauceBinary.sauce_record!(ansi_bin)
    refute sauce_bin == <<>>

    assert :binary.part(sauce_bin, 0, 5) == Sauce.sauce_id()
    assert byte_size(sauce_bin) == Sauce.sauce_record_byte_size()
    assert SauceBinary.sauce_record!(<<1, 2, 3>>) == <<>>
  end

  test "sauce?/1 check if a binary has a SAUCE record" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()
    sauce_bin = SauceBinary.sauce_record!(ansi_bin)
    # It is a SAUCE if it either *is* a SAUCE or *has* a SAUCE
    assert SauceBinary.sauce?(sauce_bin) == true
    assert SauceBinary.sauce?(ansi_bin) == true

    # not SAUCE
    assert SauceBinary.sauce?(<<>>) == false
    assert SauceBinary.sauce?(<<1, 2, 3>>) == false
    assert SauceBinary.sauce?(<<"SAUCE00">>) == false

    # length check
    assert SauceBinary.sauce?(:binary.copy(<<0>>, Sauce.sauce_record_byte_size())) == false
    # SAUCE must be at the end of a binary
    assert SauceBinary.sauce?(<<sauce_bin::binary-size(Sauce.sauce_record_byte_size()), 0>>) == false
  end

  test "comments/1 returns a SAUCE comment block with the number of lines that should be present" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()

    assert {:ok, {comments_bin, lines}} = SauceBinary.comments(ansi_bin)
    assert lines == 5
    refute comments_bin == <<>>

    assert :binary.part(comments_bin, 0, 5) == Sauce.comment_id()
    assert byte_size(comments_bin) == Sauce.comment_block_byte_size(lines)
    assert SauceBinary.comments(<<1, 2, 3>>) == {:error, :no_sauce}
  end

  test "comments/1 returns an error if no comments are present in a valid SAUCE block" do
    ansi_bin = SaucePack.path(:ansi_nocomments) |> File.read!()

    assert {:error, :no_comments} = SauceBinary.comments(ansi_bin)
  end

  test "comments?/1 returns if a SAUCE block has a comment block" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()
    assert SauceBinary.comments?(ansi_bin) == true
    filler = :binary.copy(<<"A">>, 64)

    # a comments fragment is still not a valid comments block because it can't exist in isolation without a SAUCE
    assert SauceBinary.comments?(<<Sauce.comment_id(), filler::binary-size(64)>>) == false

    ansi_bin2 = SaucePack.path(:ansi_nocomments) |> File.read!()
    assert SauceBinary.comments?(ansi_bin2) == false

    assert SauceBinary.comments?(<<>>) == false

    # too small
    filler = :binary.copy(<<0>>, 63)
    assert SauceBinary.comments?(<<Sauce.comment_id(), filler::binary-size(63)>>) == false
    assert SauceBinary.comments?(:binary.copy(<<0>>, Sauce.minimum_comment_block_byte_size())) == false
    # not a valid SAUCE anymore
    assert SauceBinary.comments?(<<ansi_bin::binary, 0>>) == false
  end

  test "comments_fragment/1 returns a SAUCE comment block with the number of lines that should be present" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()

    assert {:ok, comments_bin} = SauceBinary.comments_fragment(ansi_bin)
    refute comments_bin == <<>>

    assert :binary.part(comments_bin, 0, 5) == Sauce.comment_id()
    assert byte_size(comments_bin) == Sauce.comment_block_byte_size(5)
    assert SauceBinary.comments_fragment(<<1, 2, 3>>) == {:error, :no_sauce}

    filler = :binary.copy(<<"A">>, 64)
    frag = <<Sauce.comment_id(), filler::binary-size(64)>>
    assert {:ok, comments_frag_bin} = SauceBinary.comments_fragment(frag)

    assert {:ok, _} = SauceBinary.comments_fragment(<<frag::binary, 0>>)
    assert {:error, :no_sauce} = SauceBinary.comments_fragment(filler)

    ansi_bin2 = SaucePack.path(:ansi_nocomments) |> File.read!()
    assert {:error, :no_comments} = SauceBinary.comments_fragment(ansi_bin2)
  end

  test "comments_fragment?/1 returns if a binary is a comment block fragment" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()

    assert SauceBinary.comments_fragment?(ansi_bin) == true
    assert SauceBinary.comments_fragment?(<<1, 2, 3>>) == false

    filler = :binary.copy(<<"A">>, 64)
    frag = <<Sauce.comment_id(), filler::binary-size(64)>>
    assert SauceBinary.comments_fragment?(frag) == true

    assert SauceBinary.comments_fragment?(<<frag::binary, 0>>) == true
    assert SauceBinary.comments_fragment?(filler) == false

    ansi_bin2 = SaucePack.path(:ansi_nocomments) |> File.read!()
    assert SauceBinary.comments_fragment?(ansi_bin2) == false
  end

  test "count_comment_lines/1 returns the number of lines that should be present in a comments block dynamically" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()

    assert {:ok, lines} = SauceBinary.count_comment_lines(ansi_bin)
    assert lines == 5
  end

  test "count_comment_lines/1 returns an error if no comments are present in a valid SAUCE block" do
    ansi_bin = SaucePack.path(:ansi_nocomments) |> File.read!()

    assert {:error, :no_comments} = SauceBinary.count_comment_lines(ansi_bin)
  end

  test "count_comment_lines/1 returns an error if the source binary does not contain a SAUCE" do
    assert {:error, :no_sauce} = SauceBinary.count_comment_lines(<<>>)
    assert {:error, :no_sauce} = SauceBinary.count_comment_lines(<<"SAUCE">>)
    assert {:error, :no_sauce} = SauceBinary.count_comment_lines(<<1, 2, 3>>)
  end

  test "comment_lines/1 returns the number of comment lines according to the SAUCE record" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()

    {:ok, lines} = assert SauceBinary.comment_lines(ansi_bin)
    assert lines  == 5
  end

  test "comment_lines/1 returns if no comments are present in a valid SAUCE block" do
    ansi_bin = SaucePack.path(:ansi_nocomments) |> File.read!()

    assert {:ok, 0} = SauceBinary.comment_lines(ansi_bin)
  end

  test "comment_lines/1 returns an error if the source binary does not contain a SAUCE" do
    assert {:error, :no_sauce} = SauceBinary.comment_lines(<<>>)
    assert {:error, :no_sauce} = SauceBinary.comment_lines(<<"SAUCE">>)
    assert {:error, :no_sauce} = SauceBinary.comment_lines(<<1, 2, 3>>)
  end

  test "comment_block_lines/1 returns a list of comment line binaries" do
    ansi_bin = SaucePack.path(:ansi) |> File.read!()

    assert {:ok, line_bins} = SauceBinary.comment_block_lines(ansi_bin)
    assert Enum.count(line_bins) == 5
    assert SauceBinary.comment_block_lines(<<1, 2, 3>>) == {:error, :no_sauce}
  end

  test "eof_terminate/1 adds an EOF character to the end of a binary" do
    eof_bin = SauceBinary.eof_terminate(<<1, 2>>)
    assert byte_size(eof_bin) == 3
    assert :binary.last(eof_bin) == Sauce.eof_character()
    assert SauceBinary.eof_terminated?(eof_bin)
  end

end