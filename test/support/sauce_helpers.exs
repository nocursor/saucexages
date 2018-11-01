#defmodule SaucedFile do
#
#  defstruct [:file_name, :sauce]
#
#end

defmodule SaucePack do
  @file_names %{
    ansi_nocomments: "LD-NS1.ANS",
    ansi: "ACID0894.ANS",
    rip: "PV-UNI01.RIP",
    gif: "CS-BADL1.GIF",
    xbin: "ACID-50.XB",
    bin: "HAL-HM.BIN",
    ascii: "LD-TIDE.ASC",
    txt: "XBIN.TXT",
    s3m: "XC-SLOW2.S3M",
    no_sauce: "FILE_ID.DIZ",
    invalid_sauce: "LD-NS1-BADSAUCE.ANS",
  }

  def file_names() do
    @file_names
  end

  def path(sauce_type)
  for {sauce_type, path} <- @file_names do
    def path(unquote(sauce_type)) do
      Path.join("test/data", unquote(path))
    end
  end

  def path(_sauce_type) do
    raise ArgumentError, "You must provide a sauce type that is a member of the pack."
  end

end

defmodule SauceHelpers do

end