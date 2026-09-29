// Property-based tests
//
// Matchers already work inside `@quickcheck.check`, because a property may
// raise. But `check` shows the failure as an escaped string on one line.
// `for_all` runs the same check and shows the failure in the normal layout.

///|
/// Check that `property` holds for generated values of type `A`. Write the
/// property with matchers:
/// `for_all((x : Int) => expect(x.abs()).to_be_greater_than_or_equal(0))`.
///
/// On failure, the message shows the smallest counterexample that
/// `@quickcheck` finds and the matcher failure for it. `count`, `max_size`,
/// `max_shrinks` and `seed` are passed to `@quickcheck.check`.
#callsite(autofill(loc))
pub fn[A : @quickcheck.Arbitrary + @quickcheck.Shrink + @debug.Debug] for_all(
  property : (A) -> Unit raise Error,
  count? : UInt,
  max_size? : UInt,
  max_shrinks? : UInt,
  seed? : UInt64,
  loc~ : SourceLoc,
) -> Unit raise Error {
  // The last failing input and its error. Shrinking only accepts failing
  // inputs, so the last one is the counterexample that `check` reports.
  let mut last : (A, Error)? = None
  let result = try
    @quickcheck.check(
      value => {
        let failed : Error? = try property(value) catch {
          error => Some(error)
        } noraise {
          _ => None
        }
        if failed is Some(error) {
          last = Some((value, error))
          raise error
        }
        true
      },
      count?,
      max_size?,
      max_shrinks?,
      seed?,
    )
  catch {
    error => Some(error)
  } noraise {
    _ => None
  }
  guard result is Some(error) else { return }
  guard last is Some((value, cause)) else {
    // The check failed for another reason, such as too many discards.
    fail(describe_error(error), loc~)
  }
  let summary = describe_error(error)
  let lines = summary.split("\n").map(line => line.to_owned()).collect()
  let details = [("Counterexample", show(value))]
  if lines.search_by(line => line.has_prefix("shrinks: ")) is Some(i) {
    details.push(("Shrinks", lines[i].view(start_offset=9).to_owned()))
  }
  let failure = match cause {
    Failure(message) =>
      match message.find(" FAILED: ") {
        Some(index) =>
          message.view(end_offset=index).to_owned() +
          ": " +
          message.view(start_offset=index + 9).to_owned()
        None => message
      }
    other => "error: \{other}"
  }
  details.push(("Failure", failure))
  let headline = match lines {
    [first, ..] =>
      first
      .replace(old="QuickCheck property raised", new="for_all(property) failed")
      .replace(old="QuickCheck property", new="for_all(property)")
    [] => "for_all(property) failed"
  }
  fail("\{headline}\n\{render_details(details)}", loc~)
}
