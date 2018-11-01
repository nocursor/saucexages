# FAQ

## Does SAUCE need to be at the end of a file or binary?

Yes. According to the spec and for practical reasons, Saucexages (nor does the spec suggest) does not seek through a file to try to find a SAUCE record.

## How much space does a SAUCE record require?

128 bytes is the fixed-size of a *SAUCE record*. All the fields are filled on write, so this size is constant no matter the total size of the data.

If you add comments, the *SAUCE block* size will increase, but the record itself will stay constant. The *SAUCE block* size increases because of the *comment* block. Each line is 64 bytes, with an additional 5 bytes reserved for the *comment block* ID (CMNT).

A simple example, given a SAUCE block with 2 comment lines, the size will be 261 bytes.

Saucexages gives several ways of calculating sizes using the `Saucexages.Sauce` module. These are also implemented as macros to allow you to use them for pattern matching and for working with binaries efficiently.

## What's the deal with comment lines?

Comment lines are stored in the SAUCE record to give readers a way to quickly seek to the location of a comment block, which consists of multiple comment lines. Unfortunately, not all SAUCE readers and writers correctly implemented comment handling. As such, sometimes the comment lines value in the SAUCE record is not consistent with the comment block binary data, thus the comment data cannot be predictably read. 

Saucexages provides many ways of interrogating and working around this issue in the `Saucexages.IO.SauceBinary` module.

Generally speaking, Saucexages treats the comment lines as a handle you can extract to allow you to decide whether or not you want to read the comments, and to be able to quickly seek to them.
 
## Can I add SAUCE to a type not listed in the spec?

Yes, but you should assume a type of `:none` with an integer value of 0 for both the file and data type fields. Do not attempt to add on your own types to either file type or data type. 

## What about OTP?

There are intentionally no GenServers or other OTP behaviors and constructs included in this library. Your approach should be to encapsulate calls to this library in such behaviors when you need them. As such, Saucexages does not force any supervision tree or other requirements on you such as ETS.

For more background why this might be a good thing, see [To spawn, or not to spawn](https://www.theerlangelist.com/article/spawn_or_not).

## What is the deal with EOF?

An end-of-file (EOF) character was often used as a way to signal to programs to stop reading a file. In the days of slower IO and CPUs, this was a design choice. It was common in DOS, which was a popular OS around the time SAUCE was created. SAUCE itself specifies that the SAUCE block should only be written after an EOF character.

The EOF character should not be confused with the concept of an EOF. Saucexages will handle EOF issues for you, inserting an EOF character as needed. There are several functions that allow explicit control in `Saucexages.IO.SauceBinary` should you require it.


## Why is my data mangled?

SAUCE is designed mainly around earlier code pages, mostly related to ASCII and highly biased toward DOS/IBM and to some degree Amiga. SAUCE was designed to encode data in `cp437`, though more lax encoding was present earlier in its lifetime.

Additionally, SAUCE itself uses fixed fields. This means that if your data is longer than the length of a fixed field, it will be truncated. You can freely access these lengths via the API in `Saucexages.Sauce` which provides both offsets and field sizes with regard to a SAUCE record.

It is best to ensure that your data can be read and written in `cp437` or generally `printable ASCII` and observes the various length limits. In the future, additional validation may be added for more feedback.

Regarding historical data, much of it was improperly encoded. As such, Saucexages by default tries a few code pages when decoding strings, but will attempt to write them correctly if the data is round-tripped to ensure future consistency. If you have identified some mangled historical data, please leave an issue so additional handling can be added if necessary.

## What formats can I consume SAUCE data in using this lib?

Saucexages is capable of returning SAUCE data as both raw binary or elixir structs. There are actually two varieties of structs, a SAUCE record that encapsulates a more raw view of the data where comments are not included, and a SAUCE blocks that include all data, including comments in a more logical structural. SAUCE blocks in general is the preferred way to work with SAUCE data internally and externally, though SAUCE records are provided as a convenience for those that want a simpler view of data.

Additionally, SAUCE blocks contain information that can be further decoded in case more details are required. An example of such a requirement is when working with type specific fields such as fonts, ansi flags, and other information commonly used for display purposes. In this case, Saucexages offers various ways to fully decode this information. The decoding is on-demand as generally Saucexages tries to avoid any unnecessary overhead. Many examples of how to use this functionality can be found in various module docs.

Raw data is provided for those users which might want to implement their own encoding and decoding schemes.

## Do all data and file types listed always have SAUCE data?

No, SAUCE data is opt-in. You can safely add or remove SAUCE data from the supported types, however.

## What's with all the extra stuff?

Working with legacy data can be problematic and there's no real universal approach. Most of the functions provided are being used in real applications.

It has largely been my experience as well that SAUCE libraries completely neglect the actual usage of SAUCE and push too much on to client implementations. This has lead to a lot of bad readers and writers out there, as well as bugs across SAUCE-aware apps

Most of the functionality exists to deal with realities of data in the wild, ensure efficient handling of binaries within Elixir, and implement the SAUCE spec fully, without exception or edge-case.

Simply providing a reader that returns a few fields as unsigned integers or a writer that is not aware of truncation, existing SAUCE records, and padding rules in my opinion is about 5% of the work and mostly worthless in reality.

## Where can I get more art packs?

* [Sixteen Colors Archive](https://github.com/sixteencolors/sixteencolors-archive)
* [Textfiles Artpack Archive](http://artscene.textfiles.com/artpacks/)
* [Artpacks.org](https://artpacks.org/)

## Favorite scene groups?

I don't really have any favorite groups as mostly it was always piece by piece for me. It's hard to think back what I loved the most, however in general some ANSi, ASCII, and music groups I frequently enjoyed:

* [ACiD](http://www.acid.org/)
* [iCE Advertisements](http://www.ice.org/)
* UNioN
* mOP
* Fire
* Dark
* Trank
* Future Crew
* Relic
* Remorse
* Fairlight
* Paradox
* Skid Row

## Favorite artists?

Again, it goes piece by piece. I can't really remember most anymore and certainly not all my favorites. Regardless, here's a few suggestions of names that are still with me after all these years if you want to go looking for their art:

* Lord Jazz
* Halaster
* Eerie
* Toon Goon
* JED
* Aphex Twin/Aphid Twix
* Number 28
* Prisoner #1
* Shaggy
 