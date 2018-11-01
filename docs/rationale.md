# Rationale

There are many reasons that I created Saucexages. Overall, I have many personal projects that require the functionality provided. A secondary reason is that I have great respect for the SAUCE legacy and the benefits it provided, especially during the height of the ANSi art scene.

Underground scenes represent a valuable part of computing history. If we ignore our history, it is lost forever, mistakes are repeated, and entire groups of people are not able to enjoy the value of things past.

SAUCE may not be the most prevalent format, but it is still in continued use today. SAUCE-aware formats like ANSi live on today as terminals continue to be heavily used. Individuals and art groups such as [Blocktronics](http://blocktronics.org/) continue to find value in SAUCE. BBS software lives on via telnet and perhaps something more via efforts like [x84](https://github.com/jquast/x84) and [Oblivion/2 XRM](https://github.com/M-griffin/Oblivion2-XRM). SAUCE seems like it will live on too, and so this is my small contribution to help anyone who need it.

## Existing Libraries

Existing libraries exist to provide SAUCE support, but many are highly lacking or problematic for my use-cases, and in general, modern usage.

Some issues with existing libraries I have commonly found include:

* Many libraries lack a reader or a writer.
* Several SAUCE libraries in the wild do not support the latest SAUCE specification.
* Existing SAUCE libraries commonly neglect large portions of the spec, including:
    * File Type encoding/decoding
    * Data Type encoding/decoding
    * Comment encoding/decoding
    * File Type Flags and Fields support (t_info/t_info_s/t_flags)
    * Fonts
    * Ansi Flags
    * Proper encoding and decoding of string fields
* Intolerant readers are common
    * Many readers will crash completely on any bad data. Unfortunately bad data is common in SAUCE blocks.
    * Readers don't provide any tools to mitigate the issues caused by bad data such as skipping the field in decoding, partial decoding, or identifying the actual problems.
* File-centric
    * A huge number of readers make the assumption that all usage is from the local file-system and usually through an interface such as `fseek.`
    * File-centric interfaces are largely unsuitable for API, distributed, or scripting purposes.
* Leaks
    * Several libraries leak file or memory resources.
* Incomplete/Incorrect encoding/decoding
    * Many libraries simply return values from raw binary converted directly in their programming language without further decoding.
    * Many libraries write values without any encoding or validation.
    * Many libraries assume UTF-8 or ASCII for text, both of which are not correct.
    * String behavior is highly inconsistent both in terms of encoding and filler data (ex: 0 padded strings vs space padded strings).
             
## Use-Cases

The following use-cases drove the creation of this library:

* Creating online character-graphics (ex: ANSi) and music readers, writers, and editors.
* Bulk analysis and stream processing of existing data that uses SAUCE (ex: Ansi packs).
* Concurrent access to SAUCE data
* Usage in a modern BBS-software or BBS-inspired multi-paradigm socket server written in Elixir or Erlang.
* Fixing old, damaged data that was either written improperly or restored from archives as old as 5.25" disks.
* Preserving older formats + metadata, including but not limited to
    * Art Scene Related - ANSi, RIP, ANSimation, XBIN, BIN, etc.
    * Music/Demo Scene Related - MOD, S3M, STM, XM, IT, etc.
    * Warez/HPVAC - annotated DIZ, TXT, ZIP, etc.
* Scene stats and other fun number crunching
* Generating JSON and other metadata to help search, index, and view archives of SAUCE aware data such as the [Sixteen Colors Archive](https://github.com/sixteencolors/sixteencolors-archive).