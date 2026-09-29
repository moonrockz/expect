///|
priv suberror ParseError {
  Invalid(String)
  Empty
}

///|
fn parse_number(text : String) -> Int raise ParseError {
  if text.is_empty() {
    raise Empty
  }
  @string.parse_int(text) catch {
    _ => raise Invalid(text)
  }
}

///|
test "expect_call accepts functions that return a value" {
  expect_call(() => @string.parse_int("x")).to_raise()
  expect_call(() => parse_number("x")).to_raise()
  expect_call(() => parse_number("1")).not().to_raise()
  expect_call(() => parse_number("") |> ignore).to_raise()
}

///|
test "to_return" {
  expect_call(() => @string.parse_int("42")).to_return().to_equal(42)
  expect_call(() => parse_number("42")).to_return().to_equal(42)
  inspect(
    failure(() => {
      expect_call(() => parse_number("42"), label="parse")
      .to_return()
      .to_equal(1)
    }),
    content=(
      #|parse: expect(received).to_equal(expected)
      #|Expected: 1
      #|Received: 42
    ),
  )
  inspect(
    failure(() => expect_call(() => fails("boom")).to_return().to_equal(())),
    content=(
      #|expect(received).to_return()
      #|Expected: no error
      #|Received: error "boom"
    ),
  )
  inspect(
    failure(() => expect_call(() => 1).not().to_return().to_equal(1)),
    content=(
      #|expect(received).not.to_return()
      #|Error: to_return cannot be used after not()
    ),
  )
}

///|
test "to_raise_error" {
  expect_call(() => fails("x")).to_raise_error().message().to_equal("x")
  expect_call(() => parse_number("x"))
  .to_raise_error()
  .message()
  .to_contain("Invalid")
  inspect(
    failure(() => {
      expect_call(() => parse_number("1"))
      .to_raise_error()
      .message()
      .to_equal("")
    }),
    content=(
      #|expect(received).to_raise_error()
      #|Expected: an error
      #|Received: no error
    ),
  )
  inspect(
    failure(() => {
      expect_call(() => fails("disk full"), label="save")
      .to_raise_error()
      .message()
      .to_equal("timeout")
    }),
    content=(
      #|save.message: expect(received).to_equal(expected)
      #|Expected: "timeout"
      #|Received: "disk full"
    ),
  )
}

///|
test "to_raise_matching" {
  expect_call(() => parse_number("x")).to_raise_matching(e => e is Invalid(_))
  expect_call(() => parse_number(""))
  .not()
  .to_raise_matching(e => e is Invalid(_))
  expect_call(() => parse_number("1"))
  .not()
  .to_raise_matching(e => e is Invalid(_))
  inspect(
    failure(() => {
      expect_call(() => parse_number("")).to_raise_matching(
        e => e is Invalid(_),
        description="an Invalid error",
      )
    }),
    content=(
      #|expect(received).to_raise_matching(predicate)
      #|Expected: an error matching an Invalid error
      #|Received: error "moonrockz/expect.ParseError.Empty"
    ),
  )
  inspect(
    failure(() => {
      expect_call(() => parse_number("1")).to_raise_matching(e => e is Empty)
    }),
    content=(
      #|expect(received).to_raise_matching(predicate)
      #|Expected: an error matching predicate
      #|Received: no error
    ),
  )
}

///|
/// Raise a `Failure`. Unlike `fail`, the return type is `Unit`, so
/// `expect_call` can infer it.
fn fails(message : String) -> Unit raise Error {
  fail(message)
}
