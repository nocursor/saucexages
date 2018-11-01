defmodule Saucexages.MixProject do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/nocursor/saucexages"

  def project do
    [
      app: :saucexages,
      version: @version,
      elixir: ">= 1.6.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: "A SAUCE library for reading, writing, fixing, introspecting, and building SAUCE-aware applications.",
      package: package(),

      # Docs
      name: "Saucexages",
      source_url: @source_url,
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :codepagex]
    ]
  end

  defp package do
    [
      maintainers: [
        "nocursor",
      ],
      licenses: ["MIT"],
      links: %{github: @source_url},
      files: ~w(lib NEWS.md LICENSE.md mix.exs README.md)
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "overview",
      #logo: "logo.png",
      extra_section: "PAGES",
      assets: "docs/assets",
      groups_for_modules: groups_for_modules(),
      extras: extras(),
      groups_for_extras: groups_for_extras()
    ]
  end

  defp extras do
    [
      "docs/overview.md",
      "docs/FAQ.md",
      "docs/rationale.md",
    ]
  end

  defp groups_for_extras do
    [
    ]
  end

  defp groups_for_modules do
    [
      "Saucexages.IO": [
        Saucexages.IO.SauceBinary,
        Saucexages.IO.BinaryReader,
        Saucexages.IO.BinaryWriter,
        Saucexages.IO.FileReader,
        Saucexages.IO.FileWriter,
        Saucexages.IO.SauceFile,
      ],
      "Saucexages.Codec": [
        Saucexages.Codec.Encoder,
        Saucexages.Codec.Decoder,
        Saucexages.Codec.SauceFieldDecoder,
      ],
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], runtime: false},
      {:codepagex, "~> 0.1.4"},
      {:ex_doc, "~> 0.13", only: [:dev], runtime: false},
    ]
  end
end
