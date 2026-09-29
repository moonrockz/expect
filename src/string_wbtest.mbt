///|
test "to_equal_ignoring_case" {
  expect("Hello").to_equal_ignoring_case("hELLO")
  expect("Hello").not().to_equal_ignoring_case("help")
  inspect(
    failure(() => expect("Hello").to_equal_ignoring_case("world")),
    content=(
      #|expect(received).to_equal_ignoring_case(expected)
      #|Expected: "world", ignoring case
      #|Received: "Hello"
    ),
  )
}

///|
test "to_equal_ignoring_whitespace" {
  expect(" a b\n\tc ").to_equal_ignoring_whitespace("abc")
  expect("a b").not().to_equal_ignoring_whitespace("a c")
  inspect(
    failure(() => expect("a b").to_equal_ignoring_whitespace("a c")),
    content=(
      #|expect(received).to_equal_ignoring_whitespace(expected)
      #|Expected: "a c", ignoring whitespace
      #|Received: "a b"
    ),
  )
}

///|
test "to_be_blank" {
  expect("").to_be_blank()
  expect(" \t\n").to_be_blank()
  expect(" a ").not().to_be_blank()
  inspect(
    failure(() => expect(" a ").to_be_blank()),
    content=(
      #|expect(received).to_be_blank()
      #|Expected: empty or only whitespace
      #|Received: " a "
    ),
  )
}

///|
test "to_contain_times" {
  expect("a-b-c").to_contain_times("-", 2)
  expect("aaaa").to_contain_times("aa", 2)
  expect("abc").to_contain_times("x", 0)
  inspect(
    failure(() => expect("a-b-c").to_contain_times("-", 3)),
    content=(
      #|expect(received).to_contain_times(text, count)
      #|Expected: containing "-" 3 times
      #|Received: "a-b-c"
      #|Count:    2
    ),
  )
  inspect(
    failure(() => expect("abc").to_contain_times("", 1)),
    content=(
      #|expect(received).to_contain_times(text, count)
      #|Error: the text to count must not be empty
    ),
  )
}

///|
test "to_contain_substrings_in_order" {
  expect("one two three").to_contain_substrings_in_order(["one", "three"])
  expect("one two three").not().to_contain_substrings_in_order(["three", "one"])
  inspect(
    failure(() => {
      expect("one two three").to_contain_substrings_in_order(["two", "one"])
    }),
    content=(
      #|expect(received).to_contain_substrings_in_order(parts)
      #|Expected: containing ["two", "one"] in this order
      #|Received: "one two three"
      #|Missing:  "one", after "two"
    ),
  )
}

///|
test "to_match_fully" {
  expect("2024-01-02").to_match_fully("[[:digit:]]+-[[:digit:]]+-[[:digit:]]+")
  expect("order 42").not().to_match_fully("[[:digit:]]+")
  expect("ab").to_match_fully("a|ab")
  inspect(
    failure(() => expect("order 42").to_match_fully("[[:digit:]]+")),
    content=(
      #|expect(received).to_match_fully(pattern)
      #|Expected: matching "[[:digit:]]+" in full
      #|Received: "order 42"
    ),
  )
}

///|
test "to_equal on short strings points at the first difference" {
  inspect(
    failure(() => expect("hello wurld").to_equal("hello world")),
    content=(
      #|expect(received).to_equal(expected)
      #|Expected: "hello world"
      #|Received: "hello wurld"
      #|                  ^ first difference at index 7
    ),
  )
  inspect(
    failure(() => expect("a\"b").to_equal("a\"c")),
    content=(
      #|expect(received).to_equal(expected)
      #|Expected: "a\"c"
      #|Received: "a\"b"
      #|              ^ first difference at index 2
    ),
  )
  inspect(
    failure(() => expect("abc").to_equal("abcd")),
    content=(
      #|expect(received).to_equal(expected)
      #|Expected: "abcd"
      #|Received: "abc"
      #|              ^ first difference at index 3
    ),
  )
}

///|
test "to_equal on long strings shows the text around the first difference" {
  let expected = "x".repeat(50) + "hello world" + "y".repeat(50)
  let actual = "x".repeat(50) + "hello wurld" + "y".repeat(50)
  inspect(
    failure(() => expect(actual).to_equal(expected)),
    content=(
      #|expect(received).to_equal(expected)
      #|Expected: ..."xxxxxxxxxxxxxhello worldyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"...
      #|Received: ..."xxxxxxxxxxxxxhello wurldyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"...
      #|                                  ^ first difference at index 57
    ),
  )
}
