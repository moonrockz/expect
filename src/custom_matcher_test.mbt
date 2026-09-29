// Custom matchers, written as a user of the package would write them.

///|
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

///|
/// The failure message of `f`, without the `<loc> FAILED: ` prefix.
fn failure_message(f : () -> Unit raise Error) -> String raise Error {
  f() catch {
    Failure(message) =>
      match message.find(" FAILED: ") {
        Some(index) => return message.view(start_offset=index + 9).to_owned()
        None => return message
      }
    error => fail("expected a Failure, got \{error}")
  }
  fail("expected a failure")
}

///|
test "custom matcher passes" {
  @expect.expect(4).to_be_even()
  @expect.expect(3).not().to_be_even()
}

///|
test "custom matcher uses the standard failure format" {
  inspect(
    failure_message(() => @expect.expect(3).to_be_even()),
    content=(
      #|expect(received).to_be_even()
      #|Expected: an even number
      #|Received: 3
    ),
  )
}

///|
test "custom matcher supports not() and labels" {
  inspect(
    failure_message(() => @expect.expect(4, label="count").not().to_be_even()),
    content=(
      #|count: expect(received).not.to_be_even()
      #|Expected: not an even number
      #|Received: 4
    ),
  )
}

///|
#callsite(autofill(loc))
fn @expect.Expectation::to_have_total(
  self : @expect.Expectation[Array[Int]],
  total : Int,
  loc~ : SourceLoc,
) -> Unit raise Error {
  let actual_total = self.actual.fold(init=0, (sum, x) => sum + x)
  self.assert_that(
    actual_total == total,
    "to_have_total",
    args="total",
    expected=() => "a total of \{total}",
    received=() => @debug.to_string(self.actual),
    details=() => [("Total", actual_total.to_string())],
    loc~,
  )
}

///|
test "custom matcher adds detail lines" {
  inspect(
    failure_message(() => @expect.expect([1, 2]).to_have_total(4)),
    content=(
      #|expect(received).to_have_total(total)
      #|Expected: a total of 4
      #|Received: [1, 2]
      #|Total:    3
    ),
  )
}

///|
/// The line of the call to this helper and the line in the failure message
/// of `f`.
#callsite(autofill(loc))
fn failure_line(
  f : () -> Unit raise Error,
  loc~ : SourceLoc,
) -> (String, String) raise Error {
  let line = (text : String) => {
    text.split(":").drop(1).next().unwrap().to_owned()
  }
  f() catch {
    Failure(message) => return (line(loc.to_string()), line(message))
    error => fail("expected a Failure, got \{error}")
  }
  fail("expected a failure")
}

///|
test "custom matcher failure points at the matcher call" {
  let (call, failed) = failure_line(() => @expect.expect(3).to_be_even())
  inspect(call == failed, content="true")
}

///|
/// A reusable matcher, as a shared package would export it.
fn even() -> @expect.Matcher[Int] {
  {
    describe: () => "even",
    check: x => if x % 2 == 0 { None } else { Some("was odd") },
  }
}

///|
test "matcher values from another package" {
  @expect.expect(4).to(even())
  @expect.expect([1, 3, 4]).to_contain_element_matching(even())
  @expect.expect(3).to(@expect.is_not(even()))
  @expect.expect(6).to(@expect.all_of([even(), @expect.equal_to(6)]))
  inspect(
    failure_message(() => {
      @expect.expect(3).to(@expect.any_of([even(), @expect.equal_to(4)]))
    }),
    content=(
      #|expect(received).to(matcher)
      #|Expected: any of (even, equal to 4)
      #|Received: 3
      #|Mismatch:
      #|  even: was odd
      #|  equal to 4: was 3
    ),
  )
}

///|
test "custom matchers collect failures in a scope" {
  let message = failure_message(() => {
    @expect.expect_all(s => {
      s.expect(3).to_be_even()
      s.expect(5).to_be_even()
      s.expect(4).to_be_even()
    })
  })
  inspect(message.has_prefix("2 of 3 assertions failed"), content="true")
}
