# moonrockz/expect

A fluent assertion library for MoonBit.

## Install

```bash
moon add moonrockz/expect
```

Then import the package for tests in your `moon.pkg`:

```moonbit
import {
  "moonrockz/expect",
} for "test"
```

## Usage

```moonbit
test "basic assertions" {
  // Equality
  @expect.expect(1 + 1).to_equal(2)
  @expect.expect(1).to_not_equal(2)

  // Booleans
  @expect.expect(true).to_be_true()
  @expect.expect(false).to_be_false()

  // Options
  @expect.expect(Some(42)).to_be_some()
  @expect.expect((None : Int?)).to_be_none()

  // Strings
  @expect.expect("hello world").to_contain("world")
  @expect.expect("").to_be_empty_string()
  @expect.expect("abc").to_have_length_string(3)

  // Arrays
  @expect.expect([1, 2, 3]).to_contain_element(2)
  @expect.expect(([] : Array[Int])).to_be_empty()
  @expect.expect([1, 2, 3]).to_have_length(3)
}
```

All assertions raise `Failure` with descriptive messages on failure.

Failure messages use the `Debug` trait from `moonbitlang/core/debug` to show
values, so strings appear quoted and escaped. Custom types must derive `Debug`
(and `Eq` where the matcher compares values):

```moonbit
struct Point {
  x : Int
  y : Int
} derive(Eq, Debug)
```

## License

Apache-2.0
