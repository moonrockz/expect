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

  // Ordering (any type that implements Compare)
  @expect.expect(5).to_be_greater_than(3)
  @expect.expect(5).to_be_greater_than_or_equal(5)
  @expect.expect(3).to_be_less_than(5)
  @expect.expect(3).to_be_less_than_or_equal(3)
  @expect.expect(3).to_be_between(1, 5) // inclusive

  // Doubles
  @expect.expect(0.1 + 0.2).to_be_close_to(0.3) // default tolerance 1e-9
  @expect.expect(1.0).to_be_close_to(1.05, tolerance=0.1)

  // Options
  @expect.expect(Some(42)).to_be_some()
  @expect.expect((None : Int?)).to_be_none()

  // Results
  let ok : Result[Int, String] = Ok(1)
  @expect.expect(ok).to_be_ok()
  @expect.expect((Err("boom") : Result[Int, String])).to_be_err()

  // Strings
  @expect.expect("hello world").to_contain("world")
  @expect.expect("hello world").to_start_with("hello")
  @expect.expect("hello world").to_end_with("world")
  @expect.expect("order 42").to_match("[[:digit:]]+") // regex search

  // Arrays
  @expect.expect([1, 2, 3]).to_contain_element(2)
  @expect.expect([1, 2, 3]).to_contain_all([3, 1])
  @expect.expect([3, 1, 2]).to_equal_ignoring_order([1, 2, 3])
  @expect.expect([2, 4, 6]).to_all_satisfy(x => x % 2 == 0)
  @expect.expect([1, 2, 3]).to_contain_exactly([1, 2, 3]) // same order
  @expect.expect([1, 2, 2]).to_contain_only([2, 1]) // any order, repeats allowed
  @expect.expect([1, 2, 3]).to_contain_in_order([1, 3]) // gaps allowed
  @expect.expect([1, 2, 3]).to_start_with_elements([1, 2])
  @expect.expect([1, 2, 3]).to_end_with_elements([3])
  @expect.expect([1, 2, 3]).to_contain_none_of([4, 5])
  @expect.expect([1, 2, 3]).to_any_satisfy(x => x > 2)
  @expect.expect([1, 2, 3]).to_none_satisfy(x => x > 3)
  @expect.expect([1, 2, 3, 4]).to_have_count_satisfying(2, x => x % 2 == 0)
  @expect.expect([1, 2, 2]).to_be_sorted()
  @expect.expect(["a", "bb"]).to_be_sorted_by(s => s.length())
  @expect.expect([1, 2, 3]).to_have_no_duplicates()
  @expect.expect([1, 5]).to_satisfy_respectively([
    it => it.to_equal(1),
    it => it.to_be_greater_than(2),
  ])

  // Maps
  @expect.expect({ "a": 1 }).to_contain_key("a")

  // Length (String, Array, FixedArray, Bytes, Map, Set)
  @expect.expect("").to_be_empty()
  @expect.expect([1, 2, 3]).to_have_length(3)

  // Any value
  @expect.expect(4).to_satisfy(x => x % 2 == 0, description="is even")
}
```

### Negation

`not()` negates the next matcher:

```moonbit
@expect.expect(3).not().to_equal(5)
@expect.expect([1, 2]).not().to_be_empty()
```

### Chaining on inner values

`unwrap_some`, `unwrap_ok` and `unwrap_err` assert the variant, then return an
expectation on the inner value. You cannot use them after `not()`.

```moonbit
@expect.expect(Some(42)).unwrap_some().to_be_greater_than(40)
@expect.expect(parse("1")).unwrap_ok().to_equal(1)
@expect.expect(parse("x")).unwrap_err().to_equal(ParseError::Invalid)
```

`to_be_some` returns `Unit`, so it does not chain. MoonBit does not let a
statement ignore a returned value, so a return value would break code that
uses `to_be_some` as a statement.

### Navigation

Navigation methods return an expectation on a part of the value. The label
becomes the path to that part, so a failure shows where the value came from:

```moonbit
// Fails with: user.address.city: expect(received).to_equal(expected) ...
@expect.expect(user, label="user")
.get("address", u => u.address)
.get("city", a => a.city)
.to_equal("Paris")
```

| Method | On | Returns an expectation on | Fails when |
|---|---|---|---|
| `get(name, f)` | any value | `f(value)` | never |
| `element(i)` | `Array` | the element at index `i` | `i` is out of range |
| `first()`, `last()` | `Array` | the first or last element | the array is empty |
| `single()` | `Array` | the only element | the array does not have exactly one element |
| `value_at(key)` | `Map` | the value for `key` | the key is missing |
| `fst()`, `snd()` | pair | the first or second part | never |

Navigation changes the value under test, so you cannot use it after `not()`.

### Many matchers on one value

Matchers return `Unit`, so they do not chain. Use `all` to run several
matchers on the same value:

```moonbit
@expect.expect(age).all(it => {
  it.to_be_greater_than(0)
  it.to_be_less_than(150)
})
```

### Errors

Use `expect_call` with an arrow function to assert that code raises, or that
it returns:

```moonbit
@expect.expect_call(() => parse("x")).to_raise()
@expect.expect_call(() => parse("x")).to_raise(containing="invalid")
@expect.expect_call(() => parse("1")).not().to_raise()

// Check the type of the error with an `is` pattern
@expect.expect_call(() => parse("x")).to_raise_matching(
  e => e is ParseError::Invalid(_),
  description="an Invalid error",
)

// Chain on the error or on the returned value
@expect.expect_call(() => parse("x")).to_raise_error().message().to_contain("invalid")
@expect.expect_call(() => parse("1")).to_return().to_equal(1)
```

`containing` checks the error's `to_string()` output. `message()` gives the
error's `to_string()` output too, but for a `Failure` raised by `fail` it
leaves out the source location.

The function can return any type. When its return type is fully generic,
for example `() => fail("boom")`, MoonBit cannot infer the type and warns.
Give the function a type, or call a function that returns `Unit`.

### Regular expressions

`to_match` uses the regex syntax of `@string.Regex` from `moonbitlang/core`.
It searches the whole string, so use `^` and `$` to anchor the match. Use POSIX
classes such as `[[:digit:]]`, `[[:alpha:]]` and `[[:space:]]`: `\d`, `\s`
and `\w` are not supported. An invalid pattern fails the assertion.

### Labels

Give `expect` a label to add context to failure messages:

```moonbit
// Fails with: user id: expect(received).to_equal(expected) ...
@expect.expect(3, label="user id").to_equal(5)
```

### Custom types with a length

`to_be_empty` and `to_have_length` work on any type that implements the
`HasLength` trait. To use these matchers on your own type, implement the trait:

```moonbit
struct Bag {
  items : Array[Int]
} derive(Debug)

impl @expect.HasLength for Bag with length(self) {
  self.items.length()
}
```

`to_be_empty_string` and `to_have_length_string` are deprecated. Use
`to_be_empty` and `to_have_length` instead.

### Custom matchers

Write your own matcher as a method on `@expect.Expectation` in your test
package, and call `assert_that` to check the condition. `assert_that` gives
your matcher the same failure format as the built-in matchers: negation,
labels and the location of the failed call all work.

```moonbit
#callsite(autofill(loc))
fn @expect.Expectation::to_be_even(
  self : @expect.Expectation[Int],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.assert_that(
    self.actual % 2 == 0,
    "to_be_even",
    expected=() => "an even number",
    received=() => @debug.to_string(self.actual),
    loc~,
  )
}

test "custom matcher" {
  @expect.expect(4).to_be_even()
  @expect.expect(3).not().to_be_even()
}
```

A failure shows:

```text
expect(received).to_be_even()
Expected: an even number
Received: 3
```

- `expected` describes what the matcher wants. After `not()`, the message
  adds `not` in front of it.
- `received` shows the value under test.
- `args` names the arguments in the headline, for example `args="total"`
  gives `to_have_total(total)`.
- `details` adds lines after `Received`, for example
  `details=() => [("Total", total.to_string())]`.

The text is built only when the assertion fails, so a passing matcher does not
pay to format values. Put `#callsite(autofill(loc))` on your matcher and pass
`loc~` to `assert_that`, so that the failure points at the line that calls
your matcher.

MoonBit lets a package add methods to a type from another package only when
the methods are private. So a custom matcher method is available only in the
package that defines it.

## Failure messages

All assertions raise `Failure`. The message starts with the location of the
failed assertion, then names the matcher and shows the values:

```text
src/point_test.mbt:10:3-10:58@me/app FAILED: expect(received).to_equal(expected)
Expected: { x: 1, y: 3 }
Received: { x: 1, y: 2 }
Diff (- expected, + received):
  @@ -1,4 +1,4 @@
   {
     x: 1,
  -  y: 3,
  +  y: 2,
   }
```

- The location is the matcher call, so a test with many assertions shows
  which one failed.
- `to_equal` adds a git-style line diff when a value spans more than one line
  once it is pretty-printed. That includes structs, arrays, maps and
  multi-line strings. The values are pretty-printed with one field or element
  per line, so the diff shows exactly which fields changed. Unchanged lines
  far from a change are left out, and each group of changes gets its own
  `@@` hunk header. For long values, only the diff is shown.
- Values that span more than one line start on their own line. Values longer
  than 30 lines are shortened.
- A negated matcher shows `.not` in the first line and `not` in the
  `Expected` line.

Failure messages use the `Debug` trait from `moonbitlang/core/debug` to show
values, so strings appear quoted and escaped. Custom types must derive `Debug`
(and `Eq` where the matcher compares values):

```moonbit
struct Point {
  x : Int
  y : Int
} derive(Eq, Debug)
```

### Custom formatting

To change how a type appears in failure messages, implement `Debug` by hand
instead of deriving it. Build the output with the `Repr` constructors from
`moonbitlang/core/debug`:

| Constructor | Use it to |
|---|---|
| `Repr::record(map)` | show a struct with the fields you choose, in your order |
| `Repr::ctor(name, args)` | show a constructor such as `Money(1050)` |
| `Repr::literal(text)` | show text as it is, without quotes, such as `$10.50` |
| `Repr::omitted()` | hide a value, shown as `...` |
| `Repr::opaque_(name, repr)` | show a wrapped value, such as `<Id: 42>` |
| `Repr(value)` | use the `Debug` output of a field |

This example shows money as dollars and hides a password:

```moonbit
struct Money {
  cents : Int
} derive(Eq)

impl @debug.Debug for Money with fn to_repr(self) {
  let dollars = self.cents / 100
  let cents = self.cents % 100
  let padding = if cents < 10 { "0" } else { "" }
  Repr::literal("$\{dollars}.\{padding}\{cents}")
}

struct Account {
  owner : String
  password : String
  balance : Money
} derive(Eq)

impl @debug.Debug for Account with fn to_repr(self) {
  Repr::record({
    "owner": Repr(self.owner),
    "password": Repr::omitted(),
    "balance": Repr(self.balance),
  })
}
```

A failed `to_equal` on two accounts then shows:

```text
expect(received).to_equal(expected)
Expected: { owner: "Ada", password: ..., balance: $10.50 }
Received: { owner: "Ada", password: ..., balance: $10.05 }
Diff (- expected, + received):
  @@ -1,5 +1,5 @@
   {
     owner: "Ada",
     password: ...,
  -  balance: $10.50,
  +  balance: $10.05,
   }
```

The line diff uses the same output, so your format also controls what the
diff shows.

Formatting does not change comparison: matchers still use `Eq`. If two values
differ only in a field that you hide, the assertion fails but the message
shows no difference. Hide a field only when it cannot be the cause of a
failure, or give it a short form, such as its length, instead of `...`.

## License

Apache-2.0
