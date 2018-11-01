defmodule Saucexages.MediaInfoTest do
  use ExUnit.Case, async: true
  doctest Saucexages.MediaInfo
  import Saucexages.MediaInfo
  alias Saucexages.{MediaInfo}


  #TODO: more/better test data

  test "new/3 creates MediaInfo structs from a required file type and data type" do
    media_info = MediaInfo.new(1, 2)
    assert media_info.file_type == 1
    assert media_info.data_type == 2
    assert media_info.file_size == 0
    assert media_info.t_info_1 == 0
    assert media_info.t_info_2 == 0
    assert media_info.t_info_3 == 0
    assert media_info.t_info_4 == 0
    assert media_info.t_info_s == nil
    assert media_info.t_flags == 0

    media_info_optional = MediaInfo.new(2, 3, file_size: 42, t_info_1: 1, t_info_2: 2, t_info_3: 3, t_info_4: 4, t_info_s: "IBM VGA", t_flags: 17)

    assert media_info_optional.file_type == 2
    assert media_info_optional.data_type == 3
    assert media_info_optional.file_size == 42
    assert media_info_optional.t_info_1 == 1
    assert media_info_optional.t_info_2 == 2
    assert media_info_optional.t_info_3 == 3
    assert media_info_optional.t_info_4 == 4
    assert media_info_optional.t_info_s == "IBM VGA"
    assert media_info_optional.t_flags == 17
  end

  test "media_meta/0 returns all meta information for all file types" do
    meta_info = media_meta()

    assert is_list(meta_info)
    refute meta_info == []
    assert Enum.count(meta_info) == Enum.count(media_type_ids())

    ansi_meta_info = %Saucexages.MediaInfoMeta{
      data_type_id: :character,
      file_type: 1,
      media_type_id: :ansi,
      name: "ANSi",
      t_flags: :ansi_flags,
      t_info_1: :character_width,
      t_info_2: :number_of_lines,
      t_info_3: nil,
      t_info_4: nil,
      t_info_s: :font_id
    }
    assert Enum.member?(meta_info, ansi_meta_info)
  end

  test "media_meta_by/1 returns all the meta information for a single file type id" do
    ansi_meta_info = media_meta_by(:ansi)
    assert ansi_meta_info == %Saucexages.MediaInfoMeta{
      data_type_id: :character,
      file_type: 1,
      media_type_id: :ansi,
      name: "ANSi",
      t_flags: :ansi_flags,
      t_info_1: :character_width,
      t_info_2: :number_of_lines,
      t_info_3: nil,
      t_info_4: nil,
      t_info_s: :font_id
    }

    assert media_meta_by(:chicken) == nil
  end

  test "media_type_ids/0 list all known file types" do
    ids = media_type_ids()
    assert is_list(ids)
    assert Enum.count(ids) == 66
    assert Enum.member?(ids, :gif)
    assert Enum.member?(ids, :ansi)
    assert Enum.member?(ids, :none)
    assert Enum.member?(ids, :"3ds")
    assert Enum.member?(ids, :mod)
    assert Enum.member?(ids, :xbin)
    assert Enum.member?(ids, :binary_text)
    assert Enum.member?(ids, :tar)
    assert Enum.member?(ids, :executable)
  end

  test "media_type_ids_for/1 returns the possible file type ids for a given data type" do
    assert media_type_ids_for(:none) == [:none]
    assert media_type_ids_for(:chicken) == []

    expected_character_types = [:ascii, :ansi, :ansimation, :rip, :pcboard, :avatar, :html, :source, :tundra_draw]
    assert (media_type_ids_for(:character) -- expected_character_types) == []
    assert (media_type_ids_for(1) -- expected_character_types) == []
    assert media_type_ids_for(:binary_text) == [:binary_text]
  end

  test "file_types_for/1 returns the possible file types for a given data type" do
    assert file_types_for(:none) == [0]
    assert file_types_for(:chicken) == []

    expected_character_types = [0, 1, 2, 3, 4, 5, 6, 7, 8]
    assert (file_types_for(:character) -- expected_character_types) == []
    assert (file_types_for(1) -- expected_character_types) == []
    assert file_types_for(:binary_text) == []
  end


  test "data_type_id/1 extracts the data type id component from a file type id" do
    assert data_type_id(:none) == :none
    assert data_type_id(:ansi) == :character
    assert data_type_id(:gif) == :bitmap
    assert data_type_id(:dxf) == :vector
    assert data_type_id(:mod) == :audio
    assert data_type_id(:binary_text) == :binary_text
    assert data_type_id(:xbin) == :xbin
    assert data_type_id(:zip) == :archive
    assert data_type_id(:executable) == :executable
    assert data_type_id(:chicken) == :none
  end

  test "data_type/2 extracts the data type component from a file type id" do
    assert data_type(:none) == 0
    assert data_type(:ansi) == 1
    assert data_type(:gif) == 2
    assert data_type(:dxf) == 3
    assert data_type(:mod) == 4
    assert data_type(:binary_text) == 5
    assert data_type(:xbin) == 6
    assert data_type(:zip) == 7
    assert data_type(:executable) == 8
    assert data_type(:chicken) == 0
  end

  test "type_fields/0 returns a list of all type dependent fields" do
    assert type_fields() == [:t_info_1, :t_info_2, :t_info_3, :t_info_4, :t_flags, :t_info_s]
  end

  test "type fields/1 returns a list of all type dependent fields valid for the given file type id" do
    assert type_fields(:ansi) == [:t_flags, :t_info_1, :t_info_2, :t_info_s]
    assert type_fields(:gif) == [:t_info_1, :t_info_2, :t_info_3]
    assert type_fields(:smp8) == [:t_info_1]
    assert type_fields(:binary_text) == [:t_flags, :t_info_s]
    assert type_fields(:xbin) == [:t_info_1, :t_info_2]
    assert type_fields(:tundra_draw) == [:t_info_1, :t_info_2]
    assert type_fields(:source) == []
    assert type_fields(:none) == []
    assert type_fields(:chicken) == []
  end

  test "type fields/2 returns a list of all type dependent fields valid for the given file type and data type" do
    assert type_fields(1, 1) == [:t_flags, :t_info_1, :t_info_2, :t_info_s]
    assert type_fields(0, 2) == [:t_info_1, :t_info_2, :t_info_3]
    assert type_fields(16, 4) == [:t_info_1]
    assert type_fields(0, 5) == [:t_flags, :t_info_s]
    assert type_fields(42, 5) == [:t_flags, :t_info_s]
    assert type_fields(0, 6) == [:t_info_1, :t_info_2]
    assert type_fields(8, 1) == [:t_info_1, :t_info_2]
    assert type_fields(7, 1) == []
    assert type_fields(0, 0) == []
    assert type_fields(42, 42) == []
  end

  test "media_type_id/1 returns the media_type_id for MediaInfo" do
    assert MediaInfo.new(0, 0)
           |> MediaInfo.media_type_id() == :none
    assert MediaInfo.new(1, 1)
           |> MediaInfo.media_type_id() == :ansi
    assert MediaInfo.new(2, 1)
           |> MediaInfo.media_type_id() == :ansimation
    assert MediaInfo.new(1, 2)
           |> MediaInfo.media_type_id() == :pcx
    assert MediaInfo.new(0, 2)
           |> MediaInfo.media_type_id() == :gif
    assert MediaInfo.new(0, 3)
           |> MediaInfo.media_type_id() == :dxf
    assert MediaInfo.new(16, 4)
           |> MediaInfo.media_type_id() == :smp8
    assert MediaInfo.new(0, 5)
           |> MediaInfo.media_type_id() == :binary_text
    assert MediaInfo.new(42, 5)
           |> MediaInfo.media_type_id() == :binary_text
    assert MediaInfo.new(0, 6)
           |> MediaInfo.media_type_id() == :xbin
    assert MediaInfo.new(1, 7)
           |> MediaInfo.media_type_id() == :arj
    assert MediaInfo.new(42, 42)
           |> MediaInfo.media_type_id() == :none
  end

  test "media_type_id/2 returns the media_type_id for the given file type and data type" do
    assert MediaInfo.media_type_id(0, 0) == :none
    assert MediaInfo.media_type_id(1, 1) == :ansi
    assert MediaInfo.media_type_id(2, 1) == :ansimation
    assert MediaInfo.media_type_id(1, 2) == :pcx
    assert MediaInfo.media_type_id(0, 2) == :gif
    assert MediaInfo.media_type_id(0, 3) == :dxf
    assert MediaInfo.media_type_id(16, 4) == :smp8
    assert MediaInfo.media_type_id(0, 5) == :binary_text
    assert MediaInfo.media_type_id(42, 5) == :binary_text
    assert MediaInfo.media_type_id(24, 42) == :none
    assert MediaInfo.media_type_id(0, 6) == :xbin
    assert MediaInfo.media_type_id(1, 7) == :arj
    assert MediaInfo.media_type_id(0, 8) == :executable

    assert MediaInfo.media_type_id(0, :none) == :none
    assert MediaInfo.media_type_id(1, :character) == :ansi
    assert MediaInfo.media_type_id(2, :character) == :ansimation
    assert MediaInfo.media_type_id(1, :bitmap) == :pcx
    assert MediaInfo.media_type_id(0, :bitmap) == :gif
    assert MediaInfo.media_type_id(0, :vector) == :dxf
    assert MediaInfo.media_type_id(16, :audio) == :smp8
    assert MediaInfo.media_type_id(0, :binary_text) == :binary_text
    assert MediaInfo.media_type_id(42, :binary_text) == :binary_text
    assert MediaInfo.media_type_id(0, 6) == :xbin
    assert MediaInfo.media_type_id(1, 7) == :arj
    assert MediaInfo.media_type_id(0, :executable) == :executable
    assert MediaInfo.media_type_id(24, 42) == :none
  end

  test "file_type/1 returns the file type for the given file type id" do
    assert MediaInfo.file_type(:none) == 0
    assert MediaInfo.file_type(:ansi) == 1
    assert MediaInfo.file_type(:ansimation) == 2
    assert MediaInfo.file_type(:source) == 7
    assert MediaInfo.file_type(:pcx) == 1
    assert MediaInfo.file_type(:gif) == 0
    assert MediaInfo.file_type(:dxf) == 0
    assert MediaInfo.file_type(:mod) == 0
    assert MediaInfo.file_type(:smp8) == 16
    assert MediaInfo.file_type(:binary_text) == 0
    assert MediaInfo.file_type(:xbin) == 0
    assert MediaInfo.file_type(:arj) == 1
    assert MediaInfo.file_type(:zip) == 0
    assert MediaInfo.file_type(:executable) == 0
    assert MediaInfo.file_type(:chicken) == 0
  end

  test "type_handle/1 returns a type handle for the given file type id" do
    assert MediaInfo.type_handle(:none) == {0, 0}
    assert MediaInfo.type_handle(:ansi) == {1, 1}
    assert MediaInfo.type_handle(:ansimation) == {2, 1}
    assert MediaInfo.type_handle(:pcx) == {1, 2}
    assert MediaInfo.type_handle(:gif) == {0, 2}
    assert MediaInfo.type_handle(:dxf) == {0, 3}
    assert MediaInfo.type_handle(:smp8) == {16, 4}
    assert MediaInfo.type_handle(:binary_text) == {0, 5}
    assert MediaInfo.type_handle(:chicken) == {0, 0}
    assert MediaInfo.type_handle(:xbin) == {0, 6}
    assert MediaInfo.type_handle(:arj) == {1, 7}
    assert MediaInfo.type_handle(:executable) == {0, 8}
  end

  test "basic_info/1 returns a map of information about the given media info" do
    assert MediaInfo.new(1, 1)
           |> basic_info() == %{data_type_id: :character, media_type_id: :ansi, name: "ANSi"}
    assert basic_info(:ansi) == %{data_type_id: :character, media_type_id: :ansi, name: "ANSi"}
    assert MediaInfo.new(10, 2)
           |> basic_info() == %{data_type_id: :bitmap, media_type_id: :png, name: "PNG"}
    assert basic_info(:png) == %{data_type_id: :bitmap, media_type_id: :png, name: "PNG"}
    assert MediaInfo.new(10, :binary_text)
           |> basic_info() == %{data_type_id: :binary_text, media_type_id: :binary_text, name: "Binary Text"}
    assert basic_info(:binary_text) == %{data_type_id: :binary_text, media_type_id: :binary_text, name: "Binary Text"}
    assert MediaInfo.new(1, 10)
           |> basic_info() == %{data_type_id: :none, media_type_id: :none, name: "Undefined"}
    assert basic_info(:none) == %{data_type_id: :none, media_type_id: :none, name: "Undefined"}
    assert MediaInfo.new(42, 42)
           |> basic_info() == %{data_type_id: :none, media_type_id: :none, name: "Undefined"}
    assert basic_info(:chicken) == %{data_type_id: :none, media_type_id: :none, name: "Undefined"}
  end

  test "details/1 returns a detailed map of information about the given media info" do
    media_info = %MediaInfo{file_type: 1, data_type: 1, t_flags: 17, t_info_1: 80, t_info_2: 250, t_info_s: "IBM VGA"}

    assert media_info
           |> details() == %{
             ansi_flags: %Saucexages.AnsiFlags{
               aspect_ratio: :modern,
               letter_spacing: :none,
               non_blink_mode?: true
             },
             character_width: 80,
             data_type: 1,
             data_type_id: :character,
             file_size: 0,
             file_type: 1,
             media_type_id: :ansi,
             font_id: :ibm_vga,
             name: "ANSi",
             number_of_lines: 250,
             t_info_3: 0,
             t_info_4: 0
           }

    none_details = MediaInfo.new(0, 0)
                   |> details()
    assert none_details == %{
             data_type: 0,
             data_type_id: :none,
             file_size: 0,
             file_type: 0,
             media_type_id: :none,
             name: "Undefined",
             t_flags: 0,
             t_info_1: 0,
             t_info_2: 0,
             t_info_3: 0,
             t_info_4: 0,
             t_info_s: nil
           }

    refute Map.has_key?(none_details, :character_width)
    refute Map.has_key?(none_details, :pixel_depth)
    refute Map.has_key?(none_details, :pixel_height)
    refute Map.has_key?(none_details, :pixel_width)
    refute Map.has_key?(none_details, :font_id)
    refute Map.has_key?(none_details, :number_of_lines)
    refute Map.has_key?(none_details, :sample_rate)
  end

  test "media_details/1 returns a detailed map of information about the given media's type dependent fields" do
    media_info = %MediaInfo{file_type: 1, data_type: 1, t_flags: 17, t_info_1: 80, t_info_2: 250, t_info_s: "IBM VGA"}

    assert media_info
           |> media_details() == %{
             ansi_flags: %Saucexages.AnsiFlags{
               aspect_ratio: :modern,
               letter_spacing: :none,
               non_blink_mode?: true
             },
             character_width: 80,
             data_type: 1,
             file_size: 0,
             file_type: 1,
             font_id: :ibm_vga,
             number_of_lines: 250,
             t_info_3: 0,
             t_info_4: 0
           }

    none_details = MediaInfo.new(0, 0)
                   |> media_details()
    assert none_details == %{
             data_type: 0,
             file_size: 0,
             file_type: 0,
             t_flags: 0,
             t_info_1: 0,
             t_info_2: 0,
             t_info_3: 0,
             t_info_4: 0,
             t_info_s: nil
           }

    refute Map.has_key?(none_details, :character_width)
    refute Map.has_key?(none_details, :pixel_depth)
    refute Map.has_key?(none_details, :pixel_height)
    refute Map.has_key?(none_details, :pixel_width)
    refute Map.has_key?(none_details, :font_id)
    refute Map.has_key?(none_details, :number_of_lines)
    refute Map.has_key?(none_details, :sample_rate)
  end

  test "type_field_mapping/1 returns any type-dependent field mappings" do
    assert type_field_mapping(:ansi) == [t_flags: :ansi_flags, t_info_1: :character_width, t_info_2: :number_of_lines, t_info_s: :font_id]
    assert type_field_mapping(:tundra_draw) == [t_info_1: :character_width, t_info_2: :number_of_lines]
    assert type_field_mapping(:gif) == [t_info_1: :pixel_width, t_info_2: :pixel_height, t_info_3: :pixel_depth]
    assert type_field_mapping(:smp8) == [t_info_1: :sample_rate]
    assert type_field_mapping(:binary_text) == [t_flags: :ansi_flags, t_info_s: :font_id]
    assert type_field_mapping(:xbin) == [t_info_1: :character_width, t_info_2: :number_of_lines]
    assert type_field_mapping(:none) == []
    assert type_field_mapping(:chicken) == []
  end

  test "type_field_names/1 returns any type-dependent field names" do
    assert type_field_names(:ansi) == [:ansi_flags, :character_width, :number_of_lines, :font_id]
    assert type_field_names(:tundra_draw) == [:character_width, :number_of_lines]
    assert type_field_names(:gif) == [:pixel_width, :pixel_height, :pixel_depth]
    assert type_field_names(:smp8) == [:sample_rate]
    assert type_field_names(:binary_text) == [:ansi_flags, :font_id]
    assert type_field_names(:xbin) == [:character_width, :number_of_lines]
    assert type_field_names(:none) == []
    assert type_field_names(:chicken) == []
  end

  test "read_field/2 returns the field name associated with a given file type and file type field" do
    assert field_type(:ansi, :t_flags) == :ansi_flags
    assert field_type(:ansi, :t_info_1) == :character_width
    assert field_type(:ansi, :t_info_2) == :number_of_lines
    assert field_type(:ansi, :t_info_s) == :font_id
    assert field_type(:tundra_draw, :t_info_1) == :character_width
    assert field_type(:tundra_draw, :t_info_2) == :number_of_lines
    assert field_type(:gif, :t_info_1) == :pixel_width
    assert field_type(:gif, :t_info_2) == :pixel_height
    assert field_type(:gif, :t_info_3) == :pixel_depth
    assert field_type(:smp8, :t_info_1) == :sample_rate
    assert field_type(:binary_text, :t_flags) == :ansi_flags
    assert field_type(:binary_text, :t_info_s) == :font_id
    assert field_type(:xbin, :t_info_1) == :character_width
    assert field_type(:xbin, :t_info_2) == :number_of_lines
    assert field_type(:none, :t_info_1) == nil
    assert field_type(:chicken, :t_info_1) == nil
  end

  test "read_media_field/4 converts type specific fields" do
    assert MediaInfo.new(1, 1, [t_flags: 17])
           |> read_media_field(:t_flags) == {
             :ansi_flags,
             %Saucexages.AnsiFlags{
               aspect_ratio: :modern,
               letter_spacing: :none,
               non_blink_mode?: true
             }
           }

    assert MediaInfo.new(1, 1, [t_flags: 17])
           |> read_media_field(:t_info_4) == {:t_info_4, 0}
    assert MediaInfo.new(1, 1, [t_flags: 17, t_info_4: 5])
           |> read_media_field(:t_info_4) == {:t_info_4, 5}
    assert MediaInfo.new(1, 1, [t_flags: 17, t_info_1: 80])
           |> read_media_field(:t_info_1) == {:character_width, 80}
    assert MediaInfo.new(1, 1, [t_flags: 17, t_info_2: 200])
           |> read_media_field(:t_info_2) == {:number_of_lines, 200}
    assert MediaInfo.new(1, 1, [t_flags: 17, t_info_s: "IBM VGA"])
           |> read_media_field(:t_info_s) == {:font_id, :ibm_vga}
    assert MediaInfo.new(1, 1, [t_flags: 17])
           |> read_media_field(:chicken) == {:chicken, nil}
    assert MediaInfo.new(1, 1, [t_flags: 17])
           |> read_media_field(:t_info_1) == {:character_width, 0}
  end


  test "read_fields/3 converts type specific fields with a default conversion function" do
    assert MediaInfo.new(1, 1, [t_flags: 17])
           |> read_fields([:t_flags]) == %{
             ansi_flags:
             %Saucexages.AnsiFlags{
               aspect_ratio: :modern,
               letter_spacing: :none,
               non_blink_mode?: true
             }
           }

    assert MediaInfo.new(1, 1, [t_flags: 17])
           |> read_fields([:t_info_4]) == %{t_info_4: 0}
    assert MediaInfo.new(1, 1, [t_flags: 17, t_info_4: 5])
           |> read_fields([:t_info_4]) == %{t_info_4: 5}
    assert MediaInfo.new(1, 1, [t_flags: 17, t_info_1: 80])
           |> read_fields([:t_info_1]) == %{character_width: 80}
    assert MediaInfo.new(1, 1, [t_flags: 17, t_info_2: 200])
           |> read_fields([:t_info_2]) == %{number_of_lines: 200}
    assert MediaInfo.new(1, 1, [t_flags: 17, t_info_s: "IBM VGA"])
           |> read_fields([:t_info_s]) == %{font_id: :ibm_vga}
    assert MediaInfo.new(1, 1, [t_flags: 17])
           |> read_fields([:chicken]) == %{}
    assert MediaInfo.new(1, 1, [t_flags: 17])
           |> read_fields([:t_info_1]) == %{character_width: 0}
    assert MediaInfo.new(1, 1, [t_info_1: 80, t_info_2: 200, t_flags: 17, t_info_s: "IBM VGA"])
           |> read_fields([:t_info_1, :t_info_2, :t_flags, :t_info_s]) == %{
             ansi_flags: %Saucexages.AnsiFlags{
               aspect_ratio: :modern,
               letter_spacing: :none,
               non_blink_mode?: true
             },
             character_width: 80,
             font_id: :ibm_vga,
             number_of_lines: 200
           }

    assert MediaInfo.new(1, 1, [t_info_1: 80, t_info_2: 200, t_info_3: 5, t_info_4: 42, t_flags: 17, t_info_s: "IBM VGA"])
           |> read_fields([:t_info_1, :t_info_2, :t_info_2, :t_info_3, :t_info_4, :t_flags, :t_info_s]) == %{
             ansi_flags: %Saucexages.AnsiFlags{
               aspect_ratio: :modern,
               letter_spacing: :none,
               non_blink_mode?: true
             },
             character_width: 80,
             font_id: :ibm_vga,
             number_of_lines: 200,
             t_info_3: 5,
             t_info_4: 42
           }
  end

  test "read_field_value/4 dynamically reads type specific fields" do
    assert read_field(:ansi, :t_flags, 17) == {
             :ansi_flags,
             %Saucexages.AnsiFlags{
               aspect_ratio: :modern,
               letter_spacing: :none,
               non_blink_mode?: true
             }
           }

    assert read_field(:ansi, :t_info_4, 5) == {:t_info_4, 5}
    assert read_field(:ansi, :t_info_1, 80) == {:character_width, 80}
    assert read_field(:ansi, :t_info_2, 200) == {:number_of_lines, 200}
    assert read_field(:ansi, :t_info_s, "IBM VGA") == {:font_id, :ibm_vga}
    assert read_field(:ansi, :chicken, nil) == {:chicken, nil}
    assert read_field(:tundra_draw, :t_info_1, 80) == {:character_width, 80}
    assert read_field(:tundra_draw, :t_info_2, 200) == {:number_of_lines, 200}
    assert read_field(:gif, :t_info_1, 640) == {:pixel_width, 640}
    assert read_field(:gif, :t_info_2, 480) == {:pixel_height, 480}
    assert read_field(:gif, :t_info_3, 8) == {:pixel_depth, 8}
    assert read_field(:smp8, :t_info_1, 44) == {:sample_rate, 44}
    assert read_field(:binary_text, :t_flags, 17) == {
             :ansi_flags,
             %Saucexages.AnsiFlags{
               aspect_ratio: :modern,
               letter_spacing: :none,
               non_blink_mode?: true
             }
           }
    assert read_field(:binary_text, :t_info_s, "IBM VGA") == {:font_id, :ibm_vga}
    assert read_field(:xbin, :t_info_1, 160) == {:character_width, 160}
    assert read_field(:xbin, :t_info_2, 1024) == {:number_of_lines, 1024}
  end

  test "media_type_id?/2 determines whether or not the given data type/file type combo is a valid media_type_id." do
    assert media_type_id?(1, 1) == true
    Enum.all?(MediaInfo.media_meta(), fn(%{file_type: file_type, media_type_id: media_type_id}) ->
      data_type = data_type(media_type_id)
      media_type_id?(file_type, data_type)
    end)

  end

end