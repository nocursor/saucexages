defmodule Saucexages do
  @moduledoc """

  Saucexages is a library that provides functionality for reading, writing, interrogating, and fixing [SAUCE](http://www.acid.org/info/sauce/sauce.htm) – Standard Architecture for Universal Comment Extensions.

  The primary use of SAUCE is to add or augment metadata for files. This metadata has historically been focused on supporting art scene formats such as ANSi art (ANSI), but also supports many other formats. SAUCE support includes popular formats often found in various underground and computing communities, including, but not limited to:

    * `Character` - ANSI, ASCII, RIP, etc.
    * `Bitmap` - GIF, JPEG, PNG, etc
    * `Audio` - S3M, IT, MOD, XM, etc.
    * `Binary Text` - BIN
    * `Extended Binary Text` - XBIN
    * `Archive` - ZIP, LZH, TAR, RAR, etc.
    * `Executable` - EXE, COM, BAT, etc.

  Saucexages was created to help make handling SAUCE data contained in such file easier and available in the BEAM directly. As such, a number of features are included, such as:

  * Reading and writing all SAUCE fields, including comments
  * Cleaning SAUCE entries, including removal of both SAUCE records and comments
  * Encoding/Decoding of all SAUCE fields, including type dependent fields
  * Encoding/Decoding fallbacks based on real-world data
  * Proper padding and truncation handling per the SAUCE spec
  * Full support of all file and data types in the SAUCE spec
  * Compiled and optimized binary handling that respects output from `ERL_COMPILER_OPTIONS=bin_opt_info`
  * Choice of pure binary or positional file-based interface
  * Complete metadata related to all types, footnotes, and fields in the SAUCE spec
  * Sugar functions for dealing with interface building, dynamic behaviors, and media-specific handling
  * Macros for compile time guarantees, efficiency, and ease-of-use and to allow further use of metadata in guards, matches, and binaries as consumers see fit.

  ## Overview

  The Saucexages codebase is divided into 3 major namespaces:

    * `Saucexages` - Core namespace with a wrapper API and various types and functions useful for working with SAUCE. This includes facilities for decoding font information, ANSi flags, data type, file information, and general media info.
    * `Saucexages.Codec` - Contains functionality for encoding and decoding SAUCE data on a per-field and per-binary basis. An effort has been made to ensure that these functions attempt to work with binary as efficiently as possible.
    * `Saucexages.IO` - Modules for handling IO tasks including reading and writing both binaries and files.

  ## SAUCE Structure

  SAUCE is constructed via 2 major binary components, a SAUCE record and a comment block. The sum of these two parts can be thought of as a SAUCE block, or simply SAUCE. The SAUCE record is primarily what other libraries are referring to when they mention SAUCE or use the term. Saucexages attempts to make an effort when possible for clarity purposes to differentiate between the SAUCE block, SAUCE record, and SAUCE comment block.

  ## Location

  The SAUCE block itself is always written after an EOF character, and 128 bytes from the actual end of file. It is important to note there are possibly two EOF markers used in practice. The first is the modern notion of an EOF which means the end of the file data, as commonly recognized by modern OSs. The second marker is an EOF character,represented in hex by `0x1a`. The key to SAUCE co-existing with formats is the EOF character as its presence often signaled to viewers, readers, and other programs to stop reading data past the character in the file, or to stop interpreting this data as part of the format.

  Writing a SAUCE without an EOF character or before an EOF character will interfere with reading many formats. It is important to note that this requirement means that the EOF character must be *before* a SAUCE record, however in practice this does *not* always mean it will be *adjacent* to the EOF character. The reasons for this can be many, but common ones are flawed SAUCE writers, co-existing with other EOF-based formats, and misc. data or even garbage that may have been written in the file by other programs.

  ## Sauce Record

  The SAUCE record is 128-bytes used to hold the majority of metadata to describe files using SAUCE. The SAUCE layout is extensively described in the [SAUCE specification](http://www.acid.org/info/sauce/sauce.htm).

  Saucexages follows the same layout and types, but in Elixir-driven way. Please see the specification for more detailed descriptions including size, encoding/decoding requirements, and limitations.

  All fields are fixed-size and are padded if shorter when written. As such, any integer fields are subject to wrap when encoding, and decoding. Likewise, any string fields are subject to truncation and padding when encoding/decoding accordingly.

  The fields contained within the SAUCE record are as follows:

    * `ID` - SAUCE identifier. Should always be "SAUCE". This field is defining for the format, used extensively to pattern match, and to find SAUCE records within binaries and files.
    * `Version` - The SAUCE version. Should generally be "00". Programs should set this value to "00" and avoid changing it arbitrarily.
    * `Title` - Title of the file.
    * `Author` - Author of the file.
    * `Group` - The group associated with the file, for example the name of an art scene group.
    * `Date` - File creation date in "CCYYMMDD" format.
    * `File Size` - The original file size, excluding the SAUCE data. Generally, this is the size of all the data before the SAUCE block, and typically this equates to all data before an EOF character.
    * `Data Type` - An integer corresponding to a data type identifier.
    * `File Type` - An integer corresponding to a file type identifier. This identifier is dependent on the data type as well for interpretation.
    * `TInfo 1` - File type identifier dependent field 1.
    * `TInfo 2` - File type identifier dependent field 2.
    * `TInfo 3` - File type identifier dependent field 3.
    * `TInfo 4` - File type identifier dependent field 4.
    * `Comments` - Comment lines in the SAUCE block. This field serves as a crucial pointer and is required to properly read a comments block.
    * `TFlags` - File type identifier dependent flags.
    * `TInfoS` - File type identifier dependent string.

  ## Comment Block

  The SAUCE comment block is an optional, variable sized binary structure that holds up to 255 lines of 64 bytes of information.

  The SAUCE comment block fields are as follows:

  * ID - Identifier for the comment block that should always be equal to "COMNT". This field is defining for the format, used extensively to pattern match, and to find SAUCE comments.
  * Comment Line - Fixed size (64 bytes) field of text. Each comment block consists of 1 or more lines.

  It is vital to note that the SAUCE comment block is often broken in practice in many files. Saucexages provides many functions for identifying, repairing, and dealing with such cases. When reading and writing SAUCE, however, by default the approach described in the SAUCE specification is used. That is, the comment block location and size is always read and written according to the SAUCE record comments (comment lines) field.

  ## Format

  The general format of a SAUCE binary is as follows:

    ```
    [contents][eof character][sauce block [comment block][sauce record]]
    ```

    Conceptually, the parts of a file with SAUCE data are as follows:

    * `Contents` - The file contents. Generally anything but the SAUCE data.
    * `EOF Character` - The EOF character, or `0x1a` in hex. Occupies a single byte.
    * `SAUCE Block` - The SAUCE record + optional comment block.
    * `SAUCE Record` - The 128-byte collection of fields outlined in this module, as defined by the SAUCE spec.
    * `Comment Block` - Optional comment block of variable size, consisting of a minimum of 69 characters, and a maximum of `5 + 64 * 255` bytes. Dependent on the comment field in the SAUCE record which determines the size and location of this block.

  In Elixir binary format, this takes the pseudo-form of:

  ```elixir
  <<contents::binary, eof_character::binary-size(1), comment_block::binary-size(comment_lines * 64 + 5), sauce_record::binary-size(128)>>
  ```

  The SAUCE comment block is optional and as such, the following format is also valid:

  ```elixir
  <<contents::binary, eof_character::binary-size(1), sauce_record::binary-size(128)>>
  ```

  Additionally, since the SAUCE block itself is defined from the EOF, and after the EOF character, the following form is also valid and includes combinations of the above forms:

  ```elixir
  <<contents::binary, eof_character::binary-size(1), other_content::binary, comment_block::binary-size(comment_lines * 64 + 5), sauce_record::binary-size(128)>>
  ```

  """

  require Saucexages.IO.BinaryReader
  alias Saucexages.IO.{BinaryWriter, BinaryReader}
  alias Saucexages.SauceBlock

  #TODO: in the future we my decide to make file or binary readers/writers pluggable via using/protocols

  @doc """
  Reads a binary containing a SAUCE record and returns decoded SAUCE information as `{:ok, sauce_block}`.

  If the binary does not contain a SAUCE record, `{:error, :no_sauce}` is returned.
  """
  @spec sauce(binary()) :: {:ok, SauceBlock.t} | {:error, :no_sauce} | {:error, :invalid_sauce} | {:error, term()}
  def sauce(bin) do
    BinaryReader.sauce(bin)
  end

  @doc """
  Reads a binary containing a SAUCE record and returns the raw binary in the form `{:ok, {sauce_bin, comments_bin}}`.

  If the binary does not contain a SAUCE record, `{:error, :no_sauce}` is returned.
  """
  @spec raw(binary()) :: {:ok, {binary(), binary()}} | {:error, :no_sauce} | {:error, term()}
  def raw(bin) do
    BinaryReader.raw(bin)
  end

  @doc """
  Reads a binary containing a SAUCE record and returns the decoded SAUCE comments.
  """
  @spec comments(binary()) :: {:ok, [String.t]} | {:error, :no_sauce} | {:error, :no_comments} | {:error, term()}
  def comments(bin) do
    BinaryReader.comments(bin)
  end

  @doc """
  Reads a binary and returns the contents without the SAUCE block.
  """
  @spec contents(binary()) :: {:ok, binary()} | {:error, term()}
  def contents(bin) do
    BinaryReader.contents(bin)
  end

  @doc """
  Reads a binary and returns whether or not a SAUCE record exists.

  Will match both binary that is a SAUCE record and binary that contains a SAUCE record.
  """
  @spec sauce?(binary()) :: boolean()
  def sauce?(bin) do
    BinaryReader.sauce?(bin)
  end

  @doc """
  Reads a binary and returns whether or not a SAUCE comments block exists within the SAUCE block.

  Will match a comments block only if it a SAUCE record exists. Comment fragments are not considered to be valid without the presence of a SAUCE record.
  """
  @spec comments?(binary()) :: boolean()
  def comments?(bin) when is_binary(bin) do
    BinaryReader.comments?(bin)
  end

  @doc """
  Writes the given SAUCE block to the provided binary.
  """
  @spec write(binary(), SauceBlock.t) :: {:ok, binary()} | {:error, term()}
  def write(bin, sauce_block) do
    BinaryWriter.write(bin, sauce_block)
  end

  @doc """
  Removes a SAUCE block from a binary.

  Both the SAUCE record and comments block will be removed.
  """
  @spec remove_sauce(binary()) :: {:ok, binary()} | {:error, term()}
  def remove_sauce(bin) when is_binary(bin) do
    BinaryWriter.remove_sauce(bin)
  end

  @doc """
  Removes any comments, if present from a SAUCE and rewrites the SAUCE accordingly.

  Can be used to remove a SAUCE comments block or to clean erroneous comment information such as mismatched comment lines or double comment blocks.
  """
  @spec remove_comments(binary()) :: {:ok, binary()} | {:error, :no_sauce} | {:error, term()}
  def remove_comments(bin) when is_binary(bin) do
    BinaryWriter.remove_comments(bin)
  end

  @doc """
  Returns a detailed map of all SAUCE block data.
  """
  @spec details(binary()) :: {:ok, map()} | {:error, term()}
  def details(bin) when is_binary(bin) do
    with {:ok, sauce_block} <- sauce(bin) do
      {:ok, SauceBlock.details(sauce_block)}
    else
      err -> err
    end
  end

end
