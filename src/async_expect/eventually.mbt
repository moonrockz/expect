// Assertions for async code. This package depends on `moonbitlang/async`,
// so it is separate from `moonrockz/expect`: import it only when you need
// it. `moonbitlang/async` supports the native, js and wasm targets.

///|
/// Run `block` until it passes, or until `timeout` milliseconds have passed.
/// Between attempts, wait `interval` milliseconds. Use it for conditions
/// that become true later, such as the state after a background task:
///
/// ```moonbit nocheck
/// @async_expect.eventually(async fn() {
///   @expect.expect(queue.length()).to_equal(3)
/// })
/// ```
///
/// When the time runs out, the failure shows the number of attempts and the
/// last failure of `block`. A block that does not finish in time is stopped.
#callsite(autofill(loc))
pub async fn eventually(
  block : async () -> Unit,
  timeout? : Int = 1000,
  interval? : Int = 50,
  loc~ : SourceLoc,
) -> Unit {
  let mut last : Error? = None
  let mut attempts = 0
  let passed = @async.with_timeout_opt(timeout, async fn() {
    while true {
      attempts += 1
      let failed : Error? = try block() catch {
        error => Some(error)
      } noraise {
        _ => None
      }
      match failed {
        None => break
        Some(error) => last = Some(error)
      }
      @async.sleep(interval)
    }
  })
  if passed is Some(_) {
    return
  }
  let attempt_text = if attempts == 1 { "attempt" } else { "attempts" }
  let headline = "eventually(block) did not pass within \{timeout} ms (\{attempts} \{attempt_text})"
  let cause = match last {
    Some(Failure(message)) =>
      match message.find(" FAILED: ") {
        Some(index) =>
          message.view(end_offset=index).to_owned() +
          ": " +
          message.view(start_offset=index + 9).to_owned()
        None => message
      }
    Some(error) => "error: \{error}"
    None => "none: the first attempt did not finish in time"
  }
  let indented = cause.split("\n").map(line => "  \{line}").join("\n")
  fail("\{headline}\nLast failure:\n\{indented}", loc~)
}
