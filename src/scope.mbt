// Soft assertions
//
// `expect_all` runs a block of assertions and reports every failure
// together, instead of stopping at the first one. Expectations created with
// `Scope::expect` record their failures in the scope. A failure that leaves
// no value to go on with, such as `unwrap_some` on `None`, stops the block.

///|
/// Raised to stop a soft-assertion block after a failure has been recorded.
priv suberror ScopeStopped

///|
/// The failures that a scope and its nested scopes record.
priv struct ScopeState {
  /// Each failure as its location and message.
  failures : Array[(String, String)]
  /// Notes about blocks that stopped early.
  notes : Array[String]
  /// The number of assertions that ran.
  mut assertions : Int
}

///|
/// A soft-assertion scope. Create expectations with `expect` and
/// `expect_call`: their failures are collected, and `expect_all` reports
/// them together.
pub struct Scope {
  priv state : ScopeState
  priv nested : Bool
}

///|
fn Scope::record(self : Scope, loc : String, message : String) -> Unit {
  self.state.failures.push((loc, message))
}

///|
/// Create an expectation whose failures this scope collects.
pub fn[T] Scope::expect(
  self : Scope,
  actual : T,
  label? : String = "",
) -> Expectation[T] {
  { actual, negated: false, label, reason: "", scope: Some(self), }
}

///|
/// Create an expectation on a function whose failures this scope collects.
pub fn[T] Scope::expect_call(
  self : Scope,
  f : () -> T raise Error,
  label? : String = "",
) -> Expectation[() -> T raise Error] {
  { actual: f, negated: false, label, reason: "", scope: Some(self), }
}

///|
/// Run `block` in a nested scope. Its failures join this scope. When the
/// nested block stops early, this block goes on.
pub fn Scope::expect_all(
  self : Scope,
  block : (Scope) -> Unit raise Error,
) -> Unit {
  run_scope({ state: self.state, nested: true, }, block)
}

///|
/// Run `block` in `scope`, and record an error that stops it.
fn run_scope(scope : Scope, block : (Scope) -> Unit raise Error) -> Unit {
  block(scope) catch {
    ScopeStopped => stopped(scope)
    Failure(message) => {
      // A failure outside the scope, such as a plain `expect`, stops the
      // block too. Split `<loc> FAILED: <message>`.
      let marker = " FAILED: "
      match message.find(marker) {
        Some(index) =>
          scope.record(
            message.view(end_offset=index).to_owned(),
            message.view(start_offset=index + marker.length()).to_owned(),
          )
        None => scope.record("", message)
      }
      scope.state.assertions += 1
      stopped(scope)
    }
    error => {
      scope.record("", "error: \{error}")
      stopped(scope)
    }
  }
}

///|
/// Note that the block of `scope` stopped at its last failure.
fn stopped(scope : Scope) -> Unit {
  let number = scope.state.failures.length()
  let note = if scope.nested {
    "(\{number}) stopped the inner block, so later assertions in it did not run."
  } else {
    "(\{number}) stopped the block, so later assertions did not run."
  }
  scope.state.notes.push(note)
}

///|
/// Run a block of soft assertions. Create expectations with `s.expect` and
/// `s.expect_call`: their failures are collected, and when the block ends,
/// one failure lists all of them.
///
/// A failure that leaves no value to go on with, such as `unwrap_some` on
/// `None`, stops the block. So does any other error, such as a failure of a
/// plain `@expect.expect` in the block.
#callsite(autofill(loc))
pub fn expect_all(
  block : (Scope) -> Unit raise Error,
  loc~ : SourceLoc,
) -> Unit raise Error {
  let scope = {
    state: { failures: [], notes: [], assertions: 0, },
    nested: false,
  }
  run_scope(scope, block)
  let failures = scope.state.failures
  if failures.is_empty() {
    return
  }
  let builder = StringBuilder()
  builder.write_string(
    paint(
      "\{failures.length()} of \{scope.state.assertions} assertions failed",
      Bold,
      color_enabled(),
    ),
  )
  for i, failure in failures {
    let (at, message) = failure
    let lines = message.split("\n").map(line => line.to_owned()).collect()
    let prefix = if at.is_empty() { "" } else { "\{at}: " }
    builder.write_string("\n\n(\{i + 1}) \{prefix}\{lines[0]}")
    for line in lines[1:] {
      builder.write_string("\n    \{line}")
    }
  }
  for note in scope.state.notes {
    builder.write_string("\n\n\{note}")
  }
  fail(builder.to_string(), loc~)
}
