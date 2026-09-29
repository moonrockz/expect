///|
/// The failure message of `f`, without the `<loc> FAILED: ` prefix.
fn failure(f : () -> Unit raise Error) -> String raise Error {
  f() catch {
    error => return describe_error(error)
  }
  fail("expected a failure")
}

///|
/// The `file:line` part of a source location.
fn file_and_line(loc : String) -> String {
  let parts = loc.split(":").map(part => part.to_owned()).collect()
  "\{parts[0]}:\{parts[1]}"
}

///|
/// Run `f`, which must fail. Return the `file:line` of this call and the
/// `file:line` in the failure message.
#callsite(autofill(loc))
fn failure_lines(
  f : () -> Unit raise Error,
  loc~ : SourceLoc,
) -> (String, String) raise Error {
  f() catch {
    Failure(message) =>
      return (file_and_line(loc.to_string()), file_and_line(message))
    error => fail("expected a Failure, got \{error}")
  }
  fail("expected a failure")
}

///|
test "failure location is the matcher call, not the test" {
  let (call, failed) = failure_lines(() => expect(3).to_equal(5))
  inspect(call == failed, content="true")
  let one = Some(1)
  let (call, failed) = failure_lines(() => expect(one).unwrap_some().to_equal(2))
  inspect(call == failed, content="true")
}

///|
test "to_equal" {
  expect(42).to_equal(42)
  expect("hello").to_equal("hello")
  inspect(
    failure(() => expect(3).to_equal(5)),
    content=(
      #|expect(received).to_equal(expected)
      #|Expected: 5
      #|Received: 3
    ),
  )
  inspect(
    failure(() => expect("a\"b").to_equal("c")),
    content=(
      #|expect(received).to_equal(expected)
      #|Expected: "c"
      #|Received: "a\"b"
    ),
  )
}

///|
priv struct Point {
  x : Int
  y : Int
} derive(Eq, Debug)

///|
test "to_equal shows a structural diff" {
  expect({ x: 1, y: 2, }).to_equal({ x: 1, y: 2, })
  inspect(
    failure(() => expect({ x: 1, y: 2, }).to_equal({ x: 1, y: 3, })),
    content=(
      #|expect(received).to_equal(expected)
      #|Expected: { x: 1, y: 3 }
      #|Received: { x: 1, y: 2 }
      #|Diff (- expected, + received):
      #|  @@ -1,4 +1,4 @@
      #|   {
      #|     x: 1,
      #|  -  y: 3,
      #|  +  y: 2,
      #|   }
    ),
  )
}

///|
test "to_not_equal" {
  expect(3).to_not_equal(5)
  inspect(
    failure(() => expect(42).to_not_equal(42)),
    content=(
      #|expect(received).to_not_equal(expected)
      #|Expected: not 42
      #|Received: 42
    ),
  )
}

///|
test "not negates a matcher" {
  expect(3).not().to_equal(5)
  expect(3).not().not().to_equal(3)
  expect(false).not().to_be_true()
  inspect(
    failure(() => expect(3).not().to_equal(3)),
    content=(
      #|expect(received).not.to_equal(expected)
      #|Expected: not 3
      #|Received: 3
    ),
  )
}

///|
test "label starts the message" {
  inspect(
    failure(() => expect(3, label="user id").to_be_greater_than(10)),
    content=(
      #|user id: expect(received).to_be_greater_than(expected)
      #|Expected: > 10
      #|Received: 3
    ),
  )
  inspect(
    failure(() => expect(Some(1), label="lookup").unwrap_some().to_equal(2)),
    content=(
      #|lookup: expect(received).to_equal(expected)
      #|Expected: 2
      #|Received: 1
    ),
  )
}

///|
test "long values start on their own line and are shortened" {
  inspect(
    failure(() => expect(Array::makei(40, i => i)).to_contain_element(99)),
    content=(
      #|expect(received).to_contain_element(expected)
      #|Expected: containing 99
      #|Received:
      #|  [
      #|    0,
      #|    1,
      #|    2,
      #|    3,
      #|    4,
      #|    5,
      #|    6,
      #|    7,
      #|    8,
      #|    9,
      #|    10,
      #|    11,
      #|    12,
      #|    13,
      #|  ... 22 more lines ...
      #|    36,
      #|    37,
      #|    38,
      #|    39,
      #|  ]
    ),
  )
}

///|
test "to_satisfy" {
  expect(4).to_satisfy(x => x % 2 == 0)
  inspect(
    failure(() => {
      expect(3).to_satisfy(x => x % 2 == 0, description="an even number")
    }),
    content=(
      #|expect(received).to_satisfy(predicate)
      #|Expected: an even number
      #|Received: 3
    ),
  )
}

///|
test "to_be_true and to_be_false" {
  expect(true).to_be_true()
  expect(false).to_be_false()
  inspect(
    failure(() => expect(false).to_be_true()),
    content=(
      #|expect(received).to_be_true()
      #|Expected: true
      #|Received: false
    ),
  )
  inspect(
    failure(() => expect(true).to_be_false()),
    content=(
      #|expect(received).to_be_false()
      #|Expected: false
      #|Received: true
    ),
  )
}

///|
test "ordering matchers" {
  expect(5).to_be_greater_than(3)
  expect(5).to_be_greater_than_or_equal(5)
  expect(3).to_be_less_than(5)
  expect(5).to_be_less_than_or_equal(5)
  expect(5).to_be_between(1, 5)
  expect("b").to_be_greater_than("a")
  inspect(
    failure(() => expect(3).to_be_greater_than(3)),
    content=(
      #|expect(received).to_be_greater_than(expected)
      #|Expected: > 3
      #|Received: 3
    ),
  )
  inspect(
    failure(() => expect(2).to_be_greater_than_or_equal(3)),
    content=(
      #|expect(received).to_be_greater_than_or_equal(expected)
      #|Expected: >= 3
      #|Received: 2
    ),
  )
  inspect(
    failure(() => expect(3).to_be_less_than(3)),
    content=(
      #|expect(received).to_be_less_than(expected)
      #|Expected: < 3
      #|Received: 3
    ),
  )
  inspect(
    failure(() => expect(4).to_be_less_than_or_equal(3)),
    content=(
      #|expect(received).to_be_less_than_or_equal(expected)
      #|Expected: <= 3
      #|Received: 4
    ),
  )
  inspect(
    failure(() => expect(6).to_be_between(1, 5)),
    content=(
      #|expect(received).to_be_between(low, high)
      #|Expected: between 1 and 5 (inclusive)
      #|Received: 6
    ),
  )
  inspect(
    failure(() => expect(3).not().to_be_between(1, 5)),
    content=(
      #|expect(received).not.to_be_between(low, high)
      #|Expected: not between 1 and 5 (inclusive)
      #|Received: 3
    ),
  )
}

///|
test "to_be_close_to" {
  expect(0.1 + 0.2).to_be_close_to(0.3)
  expect(1.0).to_be_close_to(1.05, tolerance=0.1)
  expect(1.0).not().to_be_close_to(2.0)
  inspect(
    failure(() => expect(1.0).to_be_close_to(1.5, tolerance=0.1)),
    content=(
      #|expect(received).to_be_close_to(expected, tolerance)
      #|Expected:   within 0.1 of 1.5
      #|Received:   1.0
      #|Difference: 0.5
    ),
  )
  inspect(
    failure(() => expect(0.0 / 0.0).to_be_close_to(0.0 / 0.0)),
    content=(
      #|expect(received).to_be_close_to(expected, tolerance)
      #|Expected:   within 1e-9 of NaN
      #|Received:   NaN
      #|Difference: NaN
    ),
  )
}

///|
test "Option matchers" {
  expect(Some(42)).to_be_some()
  expect((None : Int?)).to_be_none()
  expect(Some(42)).unwrap_some().to_equal(42)
  inspect(
    failure(() => expect((None : Int?)).to_be_some()),
    content=(
      #|expect(received).to_be_some()
      #|Expected: Some(_)
      #|Received: None
    ),
  )
  inspect(
    failure(() => expect(Some(42)).to_be_none()),
    content=(
      #|expect(received).to_be_none()
      #|Expected: None
      #|Received: Some(42)
    ),
  )
  inspect(
    failure(() => expect(Some(1)).not().to_be_some()),
    content=(
      #|expect(received).not.to_be_some()
      #|Expected: not Some(_)
      #|Received: Some(_)
    ),
  )
  inspect(
    failure(() => expect((None : Int?)).unwrap_some().to_equal(1)),
    content=(
      #|expect(received).unwrap_some()
      #|Expected: Some(_)
      #|Received: None
    ),
  )
  inspect(
    failure(() => expect(Some(1)).not().unwrap_some().to_equal(1)),
    content=(
      #|expect(received).not.unwrap_some()
      #|Error: unwrap_some cannot be used after not()
    ),
  )
}

///|
test "Result matchers" {
  let ok : Result[Int, String] = Ok(1)
  let err : Result[Int, String] = Err("boom")
  expect(ok).to_be_ok()
  expect(err).to_be_err()
  expect(ok).not().to_be_err()
  expect(ok).unwrap_ok().to_equal(1)
  expect(err).unwrap_err().to_equal("boom")
  inspect(
    failure(() => expect(err).to_be_ok()),
    content=(
      #|expect(received).to_be_ok()
      #|Expected: Ok(_)
      #|Received: Err("boom")
    ),
  )
  inspect(
    failure(() => expect(ok).to_be_err()),
    content=(
      #|expect(received).to_be_err()
      #|Expected: Err(_)
      #|Received: Ok(1)
    ),
  )
  inspect(
    failure(() => expect(err).unwrap_ok().to_equal(1)),
    content=(
      #|expect(received).unwrap_ok()
      #|Expected: Ok(_)
      #|Received: Err("boom")
    ),
  )
  inspect(
    failure(() => expect(ok).unwrap_err().to_equal("x")),
    content=(
      #|expect(received).unwrap_err()
      #|Expected: Err(_)
      #|Received: Ok(1)
    ),
  )
}

///|
test "to_raise" {
  expect_call(() => fail("boom")).to_raise()
  expect_call(() => ()).not().to_raise()
  expect_call(() => fail("disk full")).to_raise(containing="disk full")
  expect_call(() => fail("disk full")).not().to_raise(containing="timeout")
  expect_call(() => ()).not().to_raise(containing="timeout")
  inspect(
    failure(() => expect_call(() => ()).to_raise()),
    content=(
      #|expect(received).to_raise()
      #|Expected: an error
      #|Received: no error
    ),
  )
  inspect(
    failure(() => expect_call(() => fail("boom")).not().to_raise()),
    content=(
      #|expect(received).not.to_raise()
      #|Expected: not an error
      #|Received: error "boom"
    ),
  )
  inspect(
    failure(() => {
      expect_call(() => fail("disk full")).to_raise(containing="timeout")
    }),
    content=(
      #|expect(received).to_raise(containing)
      #|Expected: an error containing "timeout"
      #|Received: error "disk full"
    ),
  )
  inspect(
    failure(() => {
      expect_call(() => fail("disk full")).not().to_raise(containing="disk")
    }),
    content=(
      #|expect(received).not.to_raise(containing)
      #|Expected: not an error containing "disk"
      #|Received: error "disk full"
    ),
  )
}

///|
test "string matchers" {
  expect("hello world").to_contain("world")
  expect("hello world").to_start_with("hello")
  expect("hello world").to_end_with("world")
  expect("abc").not().to_contain("x")
  inspect(
    failure(() => expect("hello").to_contain("xyz")),
    content=(
      #|expect(received).to_contain(expected)
      #|Expected: containing "xyz"
      #|Received: "hello"
    ),
  )
  inspect(
    failure(() => expect("hello").to_start_with("x")),
    content=(
      #|expect(received).to_start_with(expected)
      #|Expected: starting with "x"
      #|Received: "hello"
    ),
  )
  inspect(
    failure(() => expect("hello").to_end_with("x")),
    content=(
      #|expect(received).to_end_with(expected)
      #|Expected: ending with "x"
      #|Received: "hello"
    ),
  )
}

///|
test "to_match" {
  expect("order 42").to_match("[[:digit:]]+")
  expect("abc").to_match("^a.c$")
  expect("abc").not().to_match("^b")
  inspect(
    failure(() => expect("abc").to_match("^[[:digit:]]+$")),
    content=(
      #|expect(received).to_match(pattern)
      #|Expected: matching "^[[:digit:]]+$"
      #|Received: "abc"
    ),
  )
  inspect(
    failure(() => expect("abc").not().to_match("b")),
    content=(
      #|expect(received).not.to_match(pattern)
      #|Expected: not matching "b"
      #|Received: "abc"
    ),
  )
  inspect(
    failure(() => expect("abc").to_match("(unclosed")),
    content=(
      #|expect(received).to_match(pattern)
      #|Error: invalid regex pattern "(unclosed"
      #|Cause: ParserError at position 9: Unclosed group
    ),
  )
}

///|
test "array matchers" {
  expect([1, 2, 3]).to_contain_element(2)
  expect([1, 2, 3]).to_contain_all([3, 1])
  expect([1, 2, 3]).not().to_contain_all([1, 4])
  expect([3, 1, 2]).to_equal_ignoring_order([1, 2, 3])
  expect([1, 1, 2]).not().to_equal_ignoring_order([1, 2, 2])
  expect([1, 2]).not().to_equal_ignoring_order([1, 2, 3])
  expect([2, 4, 6]).to_all_satisfy(x => x % 2 == 0)
  expect(([] : Array[Int])).to_all_satisfy(_ => false)
  expect([2, 3]).not().to_all_satisfy(x => x % 2 == 0)
  inspect(
    failure(() => expect([1, 2, 3]).to_contain_element(5)),
    content=(
      #|expect(received).to_contain_element(expected)
      #|Expected: containing 5
      #|Received: [1, 2, 3]
    ),
  )
  inspect(
    failure(() => expect([1, 2, 3]).to_contain_all([1, 4, 5])),
    content=(
      #|expect(received).to_contain_all(expected)
      #|Expected: containing all of [1, 4, 5]
      #|Received: [1, 2, 3]
      #|Missing:  [4, 5]
    ),
  )
  inspect(
    failure(() => expect([1, 1, 2]).to_equal_ignoring_order([1, 2, 3])),
    content=(
      #|expect(received).to_equal_ignoring_order(expected)
      #|Expected: [1, 2, 3] in any order
      #|Received: [1, 1, 2]
      #|Missing:  [3]
      #|Extra:    [1]
    ),
  )
  inspect(
    failure(() => {
      expect([2, 3, 4]).to_all_satisfy(
        x => x % 2 == 0,
        description="an even number",
      )
    }),
    content=(
      #|expect(received).to_all_satisfy(predicate)
      #|Expected:  every element to satisfy an even number
      #|Received:  [2, 3, 4]
      #|Failed at: index 1: 3
    ),
  )
}

///|
test "to_contain_key" {
  let m = { "a": 1 }
  expect(m).to_contain_key("a")
  expect(m).not().to_contain_key("b")
  inspect(
    failure(() => expect(m).to_contain_key("b")),
    content=(
      #|expect(received).to_contain_key(key)
      #|Expected: containing key "b"
      #|Received: { "a": 1 }
    ),
  )
}

///|
test "length matchers" {
  expect(([] : Array[Int])).to_be_empty()
  expect("").to_be_empty()
  expect([1, 2, 3]).to_have_length(3)
  expect("hello").to_have_length(5)
  expect([1, 2]).not().to_be_empty()
  inspect(
    failure(() => expect([1, 2]).to_be_empty()),
    content=(
      #|expect(received).to_be_empty()
      #|Expected: empty
      #|Received: [1, 2]
      #|Length:   2
    ),
  )
  inspect(
    failure(() => expect("hello").to_be_empty()),
    content=(
      #|expect(received).to_be_empty()
      #|Expected: empty
      #|Received: "hello"
      #|Length:   5
    ),
  )
  inspect(
    failure(() => expect([1, 2]).to_have_length(5)),
    content=(
      #|expect(received).to_have_length(expected)
      #|Expected: length 5
      #|Received: [1, 2]
      #|Length:   2
    ),
  )
  inspect(
    failure(() => expect("").not().to_be_empty()),
    content=(
      #|expect(received).not.to_be_empty()
      #|Expected: not empty
      #|Received: ""
      #|Length:   0
    ),
  )
}

///|
test "HasLength works for other core collections" {
  expect(FixedArray::make(3, 0)).to_have_length(3)
  expect(b"abc").to_have_length(3)
  expect({ "a": 1, "b": 2 }).to_have_length(2)
  expect(Set::from_array([1, 2, 2])).to_have_length(2)
  expect(Set::from_array(([] : Array[Int]))).to_be_empty()
  expect(({} : Map[String, Int])).to_be_empty()
}

///|
priv struct Bag {
  items : Array[Int]
} derive(Debug)

///|
impl HasLength for Bag with fn length(self) {
  self.items.length()
}

///|
test "HasLength works for custom types" {
  expect({ items: [1, 2], }).to_have_length(2)
  expect({ items: [], }).to_be_empty()
  inspect(
    failure(() => expect({ items: [1], }).to_be_empty()),
    content=(
      #|expect(received).to_be_empty()
      #|Expected: empty
      #|Received: { items: [1] }
      #|Length:   1
    ),
  )
}

///|
test "to_equal diff on long values" {
  let expected = Array::makei(40, i => i)
  let actual = Array::makei(40, i => if i == 25 { 99 } else { i })
  inspect(
    failure(() => expect(actual).to_equal(expected)),
    content=(
      #|expect(received).to_equal(expected)
      #|Diff (- expected, + received):
      #|  @@ -24,7 +24,7 @@
      #|     22,
      #|     23,
      #|     24,
      #|  -  25,
      #|  +  99,
      #|     26,
      #|     27,
      #|     28,
    ),
  )
}

///|
test "pretty prints Debug text with one item per line" {
  inspect(
    pretty("42").join("\n"),
    content=(
      #|42
    ),
  )
  inspect(
    pretty("[]").join("\n"),
    content=(
      #|[]
    ),
  )
  inspect(
    pretty("Some(42)").join("\n"),
    content=(
      #|Some(42)
    ),
  )
  inspect(
    pretty("{ x: 1, y: [1, 2], name: \"a, [b]\" }").join("\n"),
    content=(
      #|{
      #|  x: 1,
      #|  y: [
      #|    1,
      #|    2,
      #|  ],
      #|  name: "a, [b]",
      #|}
    ),
  )
  inspect(
    pretty("Some({ x: 1, y: 2 })").join("\n"),
    content=(
      #|Some(
      #|  {
      #|    x: 1,
      #|    y: 2,
      #|  },
      #|)
    ),
  )
  inspect(
    pretty("{ \"a\": 1, \"b\": [] }").join("\n"),
    content=(
      #|{
      #|  "a": 1,
      #|  "b": [],
      #|}
    ),
  )
  inspect(
    pretty("\"one\\ntwo\\nthree\"").join("\n"),
    content=(
      #|"one\n
      #|two\n
      #|three"
    ),
  )
  inspect(
    pretty("[\n  0,\n  1,\n]").join("\n"),
    content=(
      #|[
      #|  0,
      #|  1,
      #|]
    ),
  )
}

///|
priv struct User {
  name : String
  tags : Array[String]
  address : Address
} derive(Eq, Debug)

///|
priv struct Address {
  city : String
  zip : String
} derive(Eq, Debug)

///|
test "to_equal shows a git-style diff of nested values" {
  let expected = {
    name: "Ada",
    tags: ["admin", "dev"],
    address: { city: "London", zip: "N1", },
  }
  let actual = {
    name: "Ada",
    tags: ["dev"],
    address: { city: "Paris", zip: "N1", },
  }
  inspect(
    failure(() => expect(actual).to_equal(expected)),
    content=(
      #|expect(received).to_equal(expected)
      #|Diff (- expected, + received):
      #|  @@ -1,11 +1,10 @@
      #|   {
      #|     name: "Ada",
      #|     tags: [
      #|  -    "admin",
      #|       "dev",
      #|     ],
      #|     address: {
      #|  -    city: "London",
      #|  +    city: "Paris",
      #|       zip: "N1",
      #|     },
      #|   }
    ),
  )
}

///|
test "to_equal diffs multi-line strings line by line" {
  inspect(
    failure(() => expect("alpha\nbeta\ngamma").to_equal("alpha\nBETA\ngamma")),
    content=(
      #|expect(received).to_equal(expected)
      #|Expected: "alpha\nBETA\ngamma"
      #|Received: "alpha\nbeta\ngamma"
      #|Diff (- expected, + received):
      #|  @@ -1,3 +1,3 @@
      #|   "alpha\n
      #|  -BETA\n
      #|  +beta\n
      #|   gamma"
    ),
  )
}

///|
test "to_equal diff has one hunk per distant change" {
  let expected = Array::makei(40, i => i)
  let actual = Array::makei(40, i => if i == 5 || i == 30 { -1 } else { i })
  inspect(
    failure(() => expect(actual).to_equal(expected)),
    content=(
      #|expect(received).to_equal(expected)
      #|Diff (- expected, + received):
      #|  @@ -4,7 +4,7 @@
      #|     2,
      #|     3,
      #|     4,
      #|  -  5,
      #|  +  -1,
      #|     6,
      #|     7,
      #|     8,
      #|  @@ -29,7 +29,7 @@
      #|     27,
      #|     28,
      #|     29,
      #|  -  30,
      #|  +  -1,
      #|     31,
      #|     32,
      #|     33,
    ),
  )
}

///|
/// The README example of a manual `Debug` impl.
priv struct Money {
  cents : Int
} derive(Eq)

///|
impl @debug.Debug for Money with fn to_repr(self) {
  let dollars = self.cents / 100
  let cents = self.cents % 100
  let padding = if cents < 10 { "0" } else { "" }
  Repr::literal("$\{dollars}.\{padding}\{cents}")
}

///|
priv struct Account {
  owner : String
  password : String
  balance : Money
} derive(Eq)

///|
impl @debug.Debug for Account with fn to_repr(self) {
  Repr::record({
    "owner": Repr(self.owner),
    "password": Repr::omitted(),
    "balance": Repr(self.balance),
  })
}

///|
test "custom Debug impls shape failure messages" {
  let expected = {
    owner: "Ada",
    password: "secret",
    balance: { cents: 1050, },
  }
  let actual = { owner: "Ada", password: "secret", balance: { cents: 1005, }, }
  inspect(
    failure(() => expect(actual).to_equal(expected)),
    content=(
      #|expect(received).to_equal(expected)
      #|Expected: { owner: "Ada", password: ..., balance: $10.50 }
      #|Received: { owner: "Ada", password: ..., balance: $10.05 }
      #|Diff (- expected, + received):
      #|  @@ -1,5 +1,5 @@
      #|   {
      #|     owner: "Ada",
      #|     password: ...,
      #|  -  balance: $10.50,
      #|  +  balance: $10.05,
      #|   }
    ),
  )
}
