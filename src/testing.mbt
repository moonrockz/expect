// Helpers to test failure messages, for authors of custom matchers.

///|
/// The failure message of `f`, without color and without the source
/// location. Use it to test the failure messages of custom matchers:
/// `inspect(failure_message(() => expect(3).to_be_even()), content=...)`.
///
/// Fails when `f` does not fail.
#callsite(autofill(loc))
pub fn failure_message(
  f : () -> Unit raise Error,
  loc~ : SourceLoc,
) -> String raise Error {
  f() catch {
    error => return describe_error(error)
  }
  fail("failure_message: the block did not fail", loc~)
}

///|
/// An expectation on the failure message of `f`, without color and without
/// the source location:
/// `expect_failure(() => expect(3).to_be_even()).to_contain("an even number")`.
///
/// Fails when `f` does not fail.
#callsite(autofill(loc))
pub fn expect_failure(
  f : () -> Unit raise Error,
  label? : String = "",
  loc~ : SourceLoc,
) -> Expectation[String] raise Error {
  let message = try f() catch {
    error => describe_error(error)
  } noraise {
    _ => fail("expect_failure: the block did not fail", loc~)
  }
  expect(message, label~)
}
