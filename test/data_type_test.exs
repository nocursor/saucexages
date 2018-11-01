defmodule Saucexages.DataTypeTest do
  use ExUnit.Case, async: true
  doctest Saucexages.DataType
  import Saucexages.DataType
  alias Saucexages.{DataType, DataTypeInfo}

  test "data_type_meta/0 returns a list of all SAUCE data type meta information" do
    all_data_types = DataType.data_type_meta()
    refute is_nil(all_data_types)
    refute all_data_types == []
    assert Enum.count(all_data_types) == 9
    assert Enum.all?(
             all_data_types, fn
               %DataTypeInfo{} -> true
               _ -> false
             end)

    character_type = %DataTypeInfo{data_type_id: :character, data_type: 1, name: "Character"}
    assert Enum.member?(all_data_types, character_type)
  end


  test "data_type_meta/1 returns the meta information about a given data type" do
    character_meta = data_type_meta(:character)
    assert is_map(character_meta)
    assert Map.get(character_meta, :data_type) == 1
    assert Map.get(character_meta, :data_type_id) == :character
    assert Map.get(character_meta, :name) == "Character"

    all_data_types = DataType.data_type_meta()
    assert Enum.all?(all_data_types, fn(%{data_type_id: data_type_id} = meta) ->
      data_type_meta(data_type_id) == meta
    end)

    assert data_type_meta(1) == character_meta

    assert data_type_meta(:chicken) == nil
  end

  test "data_type_ids/0 returns a list of all SAUCE data type IDs" do
    ids = data_type_ids()
    assert Enum.count(ids) == 9
    assert Enum.all?(ids, &is_atom/1)
    all_ids =  [:none, :character, :bitmap, :vector, :audio, :binary_text, :xbin, :archive, :executable]

    assert (all_ids -- ids) == []
  end

  test "data_type_id/1 returns the data type id that corresponds with the SAUCE data type integer" do
    assert data_type_id(0) == :none
    assert data_type_id(1) == :character
    assert data_type_id(2) == :bitmap
    assert data_type_id(3) == :vector
    assert data_type_id(4) == :audio
    assert data_type_id(5) == :binary_text
    assert data_type_id(6) == :xbin
    assert data_type_id(7) == :archive
    assert data_type_id(8) == :executable
    assert data_type_id(42) == :none
  end

  test "data_type/1 returns the SAUCE integer data type for data type ids" do
    assert data_type(:none) == 0
    assert data_type(:character) == 1
    assert data_type(:bitmap) == 2
    assert data_type(:vector) == 3
    assert data_type(:audio) == 4
    assert data_type(:binary_text) == 5
    assert data_type(:xbin) == 6
    assert data_type(:archive) == 7
    assert data_type(:executable) == 8

    assert data_type(:beef) == 0
  end

end