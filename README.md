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

[docs/matchers.md](docs/matchers.md) lists every matcher, grouped by the type
of the value under test, with an example of each.

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
  @expect.expect(4).to_be_between(1, 5, high_inclusive=false)

  // Signs (Int, Int16, Int64, UInt, UInt16, UInt64, Double, Float)
  @expect.expect(3).to_be_positive()
  @expect.expect(-3).to_be_negative()
  @expect.expect(0).to_be_zero()

  // Floating-point numbers (Double and Float)
  @expect.expect(0.1 + 0.2).to_be_close_to(0.3) // default tolerance 1e-9
  @expect.expect(1.0).to_be_close_to(1.05, tolerance=0.1) // absolute
  @expect.expect(1000.0).to_be_close_to(1001.0, relative=0.01) // 1%
  @expect.expect(1.0).to_be_close_to(1.0000000000000002, ulps=1)
  @expect.expect(0.0 / 0.0).to_be_nan()
  @expect.expect(1.0).to_be_finite()

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
  @expect.expect("42").to_match_fully("[[:digit:]]+") // whole string
  @expect.expect("Hello").to_equal_ignoring_case("hello")
  @expect.expect("a b\nc").to_equal_ignoring_whitespace("abc")
  @expect.expect(" \t").to_be_blank()
  @expect.expect("a-b-c").to_contain_times("-", 2)
  @expect.expect("one two three").to_contain_substrings_in_order(["one", "three"])

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
  @expect.expect({ "a": 1 }).to_contain_value(1)
  @expect.expect({ "a": 1, "b": 2 }).to_contain_entry("a", 1)
  @expect.expect({ "a": 1, "b": 2 }).to_contain_entries({ "b": 2 })

  // Length (String, Array, Map, Set, views, Deque, List, and the other core collections)
  @expect.expect("").to_be_empty()
  @expect.expect([1, 2, 3]).to_have_length(3)

  // Any value
  @expect.expect(4).to_satisfy(x => x % 2 == 0, description="is even")
  @expect.expect(2).to_be_one_of([1, 2, 3])
  @expect.expect(2).to_be_in(Set([1, 2, 3]))

  // Chars (ASCII, except to_be_whitespace)
  @expect.expect('7').to_be_digit()
  @expect.expect('a').to_be_letter()
  @expect.expect(' ').to_be_whitespace()
  @expect.expect('A').to_be_upper_case()
  @expect.expect('a').to_be_lower_case()
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

### Matcher values

A `Matcher[T]` is a matcher as a value. Run one with `to`, combine several,
or pass one to another matcher:

```moonbit
@expect.expect(age).to(@expect.all_of([
  @expect.satisfying(a => a >= 18, description=">= 18"),
  @expect.is_not(@expect.equal_to(99)),
]))

@expect.expect(users).to_contain_element_matching(
  @expect.field("name", u => u.name, @expect.equal_to("Ada")),
)
```

| Function | Matches values that |
|---|---|
| `equal_to(x)` | equal `x` |
| `satisfying(pred, description?)` | satisfy `pred` |
| `field(name, f, m)` | give a result that matches `m` when you apply `f` |
| `all_of([m1, m2])` | match every matcher |
| `any_of([m1, m2])` | match at least one matcher |
| `is_not(m)` | do not match `m` |
| `matching(description, block)` | pass the method matchers in `block` |

`matching` makes every method matcher available as a matcher value:

```moonbit
@expect.expect(users).to_contain_element_matching(
  @expect.field("age", u => u.age, @expect.matching("an adult", it => {
    it.to_be_greater_than_or_equal(18)
  })),
)
```

A failure names each part that does not match:

```text
expect(received).to(matcher)
Expected: all of (> 1, < 5, even)
Received: 7
Mismatch:
  < 5: was 7
  even: was 7
```

To write your own, build a `Matcher` with a struct literal. `describe` is
called only for failure messages, and `check` returns `None` for a match or
`Some(reason)` for a mismatch:

```moonbit
pub fn even() -> @expect.Matcher[Int] {
  {
    describe: () => "even",
    check: x => if x % 2 == 0 { None } else { Some("was odd") },
  }
}
```

Unlike custom matcher methods, these functions can be public, so a package
can share them.

### Property-based tests

`for_all` checks a property for many generated values with
`moonbitlang/core/quickcheck`. Write the property with matchers:

```moonbit
@expect.for_all((xs : Array[Int]) => {
  @expect.expect(xs.rev().rev()).to_equal(xs)
})
```

On failure, `for_all` shows the smallest counterexample that quickcheck
finds, and the matcher failure for it:

```text
for_all(property) failed after 3 test(s)
Counterexample: 50
Shrinks:        26 successful, 37 attempted
Failure:
  src/math_test.mbt:3:46-3:75@me/app: expect(received).to_be_less_than(expected)
  Expected: < 50
  Received: 50
```

`count`, `max_size`, `max_shrinks` and `seed` are passed to
`@quickcheck.check`. The value type must implement `@quickcheck.Arbitrary`
and `@quickcheck.Shrink`.

### Soft assertions

`expect_all` runs a block of assertions and reports every failure together,
instead of stopping at the first one. Create expectations with `s.expect` or
`s.expect_call`:

```moonbit
@expect.expect_all(s => {
  s.expect(user.name).to_equal("Ada")
  s.expect(user.age).to_be_greater_than(18)
  s.expect(user.tags).first().to_equal("admin")
})
```

```text
2 of 3 assertions failed

(1) src/user_test.mbt:12:3-12:40@me/app: expect(received).to_equal(expected)
    Expected: "Ada"
    Received: "Bob"

(2) src/user_test.mbt:13:3-13:45@me/app: expect(received).to_be_greater_than(expected)
    Expected: > 18
    Received: 17
```

- The scope carries through `not()`, `because`, navigation and `all`, and
  custom matchers built on `assert_that` collect their failures too.
- A failure that leaves no value to go on with, such as `unwrap_some` on
  `None`, stops the block. So does any other error, for example a plain
  `@expect.expect` that fails in the block. The report says which failure
  stopped the block.
- `s.expect_all(inner => ...)` runs a nested scope. Its failures join the
  outer list, and when the nested block stops, the outer block goes on.

### Equivalence

`to_be_equivalent_to` compares two values field by field, and lists each
difference by path. The type does not need `Eq`:

```moonbit
@expect.expect(saved).to_be_equivalent_to(
  draft,
  excluding=["id", "items[*].id"], // skip these paths; [*] matches any index
  ignoring_order=true, // compare arrays as multisets, at every depth
  tolerance=0.01, // numbers may differ by up to 0.01
)
```

```text
expect(received).to_be_equivalent_to(expected)
Expected: equivalent to { id: 1, owner: "Ada", balance: { cents: 1050 } }
Received: { id: 1, owner: "Ada", balance: { cents: 1005 } }
Differences:
  balance.cents: expected 1050, received 1005
```

Equivalence compares what `Debug` shows. Fields that `Debug` hides, for
example with `Repr::omitted()`, always compare as equivalent. Values that
`Debug` shows as text, such as a custom `Repr::literal`, compare as text.

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

### Json

`at` navigates into a `Json` value with a path such as `items[0].sku`. Keys
are separated by `.`, and array indices are in brackets. The path appears
in the failure headline. `to_contain_json` checks a subset: other keys are
allowed, arrays must have the same length, and numbers compare by value.

```moonbit
let order : Json = { "id": 7, "items": [{ "sku": "A1", "qty": 2 }] }
@expect.expect(order).at("items[0].sku").to_equal("A1")
@expect.expect(order).to_contain_json({ "items": [{ "qty": 2 }] })
```

When a path does not exist, the failure shows the deepest part that does:

```text
expect(received).at(path)
Expected: a value at "items[3].sku"
Received: {"id":7,"items":[{"sku":"A1","qty":2}]}
Found:    items is an array of length 1
```

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

### Reasons

`because` gives the reason why an assertion must hold. A failure shows it on
a `Because` line:

```moonbit
// Fails with:
// retries: expect(received).to_equal(expected)
// Expected: 4
// Received: 3
// Because:  the client retries three times
@expect.expect(3, label="retries")
.because("the client retries three times")
.to_equal(4)
```

The reason stays through `not()` and navigation, and custom matchers show it
too.

### Other collections

Array matchers take an `Array`. For any other collection, use
`expect_elements` with its `iter()`, and all Array matchers and navigation
methods work:

```moonbit
@expect.expect_elements(deque.iter()).to_contain_element(3)
@expect.expect_elements(sorted_set.iter()).first().to_equal(1)
```

`to_be_empty` and `to_have_length` work on the core collections directly:
`ArrayView`, `StringView`, `BytesView`, `Deque`, `List`, `Queue`,
`PriorityQueue`, `HashMap`, `HashSet`, `SortedMap`, `SortedSet`, and the
`@immut` maps, sets, vectors and priority queue.

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

To test the failure messages of your matchers, use `failure_message` or
`expect_failure`. Both run a block that must fail, and give its message
without the source location, so the result does not change when the file
changes:

```moonbit
test "to_be_even message" {
  inspect(
    @expect.failure_message(() => @expect.expect(3).to_be_even()),
    content=(
      #|expect(received).to_be_even()
      #|Expected: an even number
      #|Received: 3
    ),
  )
  @expect.expect_failure(() => @expect.expect(3).to_be_even())
  .to_contain("Expected: an even number")
}
```

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
  ?     ^
   }
```

- The location is the matcher call, so a test with many assertions shows
  which one failed.
- `to_equal` adds a git-style line diff when a value spans more than one line
  once it is pretty-printed. That includes structs, arrays and
  multi-line strings. The values are pretty-printed with one field or element
  per line, so the diff shows exactly which fields changed. Unchanged lines
  far from a change are left out, and each group of changes gets its own
  `@@` hunk header. For long values, only the diff is shown.
- When one line replaces another and most of it is the same, a `?` line
  puts carets under the characters that changed.
- When `to_equal` fails on two single-line strings, a caret points at the
  first difference. Long strings are cut to the text around it:

  ```text
  Expected: "hello world"
  Received: "hello wurld"
                    ^ first difference at index 7
  ```

- `Bytes` values show as a hex dump, as `hexdump -C` does. When `to_equal`
  fails on two `Bytes` values, a `Difference` line shows the first differing
  offset.
- When `to_equal` fails on two maps, the message lists the `Missing`,
  `Extra` and `Changed` keys instead of a line diff. Maps are equal in any
  order, so a line diff could show changes that are only a different order.
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
  ?               ^^
   }
```

The line diff uses the same output, so your format also controls what the
diff shows.

Formatting does not change comparison: matchers still use `Eq`. If two values
differ only in a field that you hide, the assertion fails but the message
shows no difference. Hide a field only when it cannot be the cause of a
failure, or give it a short form, such as its length, instead of `...`.

## Development

Run the tests with `moon test`. After you add or change a public matcher,
run `mise run docs:catalog` to update `docs/matchers.md`. CI fails when the
catalog is out of date.

## License

Apache-2.0
