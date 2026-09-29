// Matchers for functions, created with `expect_call`.

///|
/// Call the function under test. Return the error it raises, if any.
fn[T] Expectation::call(self : Expectation[() -> T raise Error]) -> Error? {
  try (self.actual)() catch {
    error => Some(error)
  } noraise {
    _ => None
  }
}

///|
/// Describe what a call raised, for the `Received` line.
fn describe_raised(raised : Error?) -> String {
  match raised {
    Some(error) => "error \{show(describe_error(error))}"
    None => "no error"
  }
}

///|
/// Assert the function returns without an error, and return an expectation
/// on the returned value. Cannot be used after `not()`.
#callsite(autofill(loc))
pub fn[T] Expectation::to_return(
  self : Expectation[() -> T raise Error],
  loc~ : SourceLoc,
) -> Expectation[T] raise Error {
  self.check_not_negated("to_return", loc)
  let value = (self.actual)() catch {
    error =>
      self.report(
        "to_return",
        "",
        [("Expected", "no error"), ("Received", describe_raised(Some(error)))],
        loc,
      )
  }
  self.with_value(value)
}

///|
/// Assert the function raises an error, and return an expectation on the
/// error. Use `message()` to check the error text. Cannot be used after
/// `not()`.
#callsite(autofill(loc))
pub fn[T] Expectation::to_raise_error(
  self : Expectation[() -> T raise Error],
  loc~ : SourceLoc,
) -> Expectation[Error] raise Error {
  self.check_not_negated("to_raise_error", loc)
  match self.call() {
    Some(error) => self.with_value(error)
    None =>
      self.report(
        "to_raise_error",
        "",
        [("Expected", "an error"), ("Received", "no error")],
        loc,
      )
  }
}

///|
/// Return an expectation on the message of an error. For a `Failure` raised
/// by `fail`, the message does not include the source location.
pub fn Expectation::message(self : Expectation[Error]) -> Expectation[String] {
  self.navigate(describe_error(self.actual), "message")
}

///|
/// Assert the function raises an error that satisfies `predicate`. Use an
/// `is` pattern to check the error type:
/// `expect_call(() => parse("x")).to_raise_matching(e => e is ParseError::Invalid(_))`.
///
/// Negated, the assertion fails only when the function raises an error that
/// satisfies the predicate.
#callsite(autofill(loc))
pub fn[T] Expectation::to_raise_matching(
  self : Expectation[() -> T raise Error],
  predicate : (Error) -> Bool,
  description? : String = "predicate",
  loc~ : SourceLoc,
) -> Unit raise Error {
  let raised = self.call()
  self.assert_that(
    raised is Some(error) && predicate(error),
    "to_raise_matching",
    args="predicate",
    expected=() => "an error matching \{description}",
    received=() => describe_raised(raised),
    loc~,
  )
}
