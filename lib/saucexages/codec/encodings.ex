defmodule Saucexages.Codec.Encodings do
  @moduledoc false

  @aliases %{
    ascii: "VENDORS/MISC/US-ASCII-QUOTES",
    cp437: "VENDORS/MICSFT/PC/CP437",
    #latin_1: "ISO8859/8859-1",
    utf8:  "UTF8"
  }

  for {alias, encoding} <- @aliases do
    defmacro encoding(unquote(alias)), do: unquote(encoding)
  end

  defmacro aliases() do
    @aliases |> Map.keys()
  end

end
