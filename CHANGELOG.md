# Changelog

This file starts at 0.7.0. For older releases, see the
[GitHub releases](https://github.com/moonrockz/expect/releases).

## 0.7.0

### Highlights

This release moves the library to MoonBit 0.10.20. The public API does not
change. The source no longer uses the `view` methods of `String` and
`StringView`, which 0.10.20 deprecates. It uses `exact_view` instead.

### Minimum toolchain

The minimum toolchain is MoonBit 0.10.20 (moonc `v0.10.20+65efd5b93`,
moon `0.1.20261104`). MoonBit 0.10.18 and older are no longer supported. The
source uses the `#derive(...)` attribute, which 0.10.18 ignores, so
`moon check` and `moon test` of this module fail on those versions. CI and
the release workflow use 0.10.20 only.

### Changes

- #68 Upgrade MoonBit to 0.10.20, and pin CI and the release workflow to it.
