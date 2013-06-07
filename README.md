# standalone-haddock

standalone-haddock generates standalone haddock Haskell documentation.

When you simply run `cabal haddock`, the resulting HTML documentation contains
hyperlinks to other packages on your system. As a result, you cannot publish it
on the internet (well, you can, but the links will be broken).

standalone-haddock takes several packages for which you want to publish
documentation. It generates documentation for them with proper links:

* links to identifiers inside this package set are relative
* links to identifiers from external packages lead to hackage

Thus the resulting directory with HTML is relocatable and publishable.

**TL;DR**: it just works. See the [haskell-suite][] documentation for an example
output.

[haskell-suite]: http://haskell-suite.github.io/docs

## Usage

    Usage: standalone-haddock [--package-db DB-PATH] -o OUTPUT-PATH [PACKAGE-PATH]

    Available options:
      -h,--help                Show this help text
      --package-db DB-PATH     Additional package database
      -o OUTPUT-PATH           Directory where html files will be placed

`PACKAGE-PATH` is the path to the (unpacked) package — i.e. a directory with a
`.cabal` file.

For example:

    standalone-haddock -o doc haskell-names haskell-packages haskell-src-exts hse-cpp cabal/Cabal

**NOTE**: dependencies of every package need to be already installed in the
system with documentation (even those dependencies that themselves belong to the
current package set). If they are installed in a non-standard package database
(e.g. if you use sandboxes), use the `--package-db` option.

## Cabal dependency

The program only builds with (unreleased) Cabal 1.17 which you can get from
[github](https://github.com/haskell/cabal).

I spent some time trying to make it compatible with Cabal 1.16 (see
[Cabal-1.16][] branch), but the API seems to have changed too much.

If you seriously care about this, feel free to send a patch, but it's really
easier to just install Cabal HEAD.

[Cabal-1.16]: https://github.com/feuerbach/standalone-haddock/tree/Cabal-1.16
