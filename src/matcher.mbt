// Matcher values
//
// A `Matcher[T]` is a matcher as a value: you can store it, combine it and
// pass it to other matchers. Run one with `expect(value).to(matcher)`.
//
// MoonBit traits cannot take type parameters, so a matcher is a struct of
// closures, as `Iter[T]` is.

///|
/// A check on values of type `T`, with a description for failure messages.
///
/// - `describe` returns what the matcher wants, such as `equal to 3`. It is
///   called only when a failure message is built.
/// - `check` returns `None` when the value matches, or `Some(reason)` when it
///   does not, such as `Some("was 2")`.
///
/// Build your own matcher with a struct literal:
/// `let even : Matcher[Int] = { describe: () => "even", check: x => if x % 2 == 0 { None } else { Some("was odd") } }`.
pub(all) struct Matcher[T] {
  describe : () -> String
  check : (T) -> String?
}

///|
/// A matcher for values equal to `expected`.
pub fn[T : Eq + @debug.Debug] equal_to(expected : T) -> Matcher[T] {
  {
    describe: () => "equal to \{show(expected)}",
    check: value => {
      if value == expected {
        None
      } else {
        Some("was \{show(value)}")
      }
    },
  }
}

///|
/// A matcher for values that satisfy `predicate`.
pub fn[T : @debug.Debug] satisfying(
  predicate : (T) -> Bool,
  description? : String = "predicate",
) -> Matcher[T] {
  {
    describe: () => description,
    check: value => {
      if predicate(value) {
        None
      } else {
        Some("was \{show(value)}")
      }
    },
  }
}

///|
/// The descriptions of `matchers`, in parentheses: `(> 1, < 5)`.
fn[T] describe_all(matchers : Array[Matcher[T]]) -> String {
  "(" + matchers.map(m => (m.describe)()).join(", ") + ")"
}

///|
/// The reasons why `value` does not match each of `matchers`, one per line:
/// `< 5: was 7`.
fn[T] mismatches(matchers : Array[Matcher[T]], value : T) -> Array[String] {
  matchers.filter_map(m => {
    (m.check)(value).map(reason => "\{(m.describe)()}: \{reason}")
  })
}

///|
/// A matcher for values that match every one of `matchers`. A mismatch names
/// each part that does not match.
pub fn[T] all_of(matchers : Array[Matcher[T]]) -> Matcher[T] {
  {
    describe: () => "all of \{describe_all(matchers)}",
    check: value => {
      let failed = mismatches(matchers, value)
      if failed.is_empty() {
        None
      } else {
        Some(failed.join("\n"))
      }
    },
  }
}

///|
/// A matcher for values that match at least one of `matchers`.
pub fn[T] any_of(matchers : Array[Matcher[T]]) -> Matcher[T] {
  {
    describe: () => "any of \{describe_all(matchers)}",
    check: value => {
      let failed = mismatches(matchers, value)
      if failed.length() < matchers.length() {
        None
      } else {
        Some(failed.join("\n"))
      }
    },
  }
}

///|
/// A matcher for values that do not match `matcher`.
pub fn[T : @debug.Debug] is_not(matcher : Matcher[T]) -> Matcher[T] {
  {
    describe: () => "not \{(matcher.describe)()}",
    check: value => {
      match (matcher.check)(value) {
        Some(_) => None
        None => Some("was \{show(value)}")
      }
    },
  }
}

///|
/// A matcher that applies `f` to the value and checks the result with
/// `matcher`: `field("name", u => u.name, equal_to("Ada"))`.
pub fn[T, U] field(
  name : String,
  f : (T) -> U,
  matcher : Matcher[U],
) -> Matcher[T] {
  {
    describe: () => "\{name} \{(matcher.describe)()}",
    check: value => (matcher.check)(f(value)),
  }
}

///|
/// A matcher that runs method matchers on the value:
/// `matching("an adult", it => it.to_be_greater_than_or_equal(18))`.
///
/// Every method matcher works this way, and so do custom matchers. The
/// mismatch comes from the failure of the first method matcher that fails.
pub fn[T] matching(
  description : String,
  block : (Expectation[T]) -> Unit raise Error,
) -> Matcher[T] {
  {
    describe: () => description,
    check: value => {
      block(expect(value)) catch {
        error => return Some(mismatch_reason(error))
      }
      None
    },
  }
}

///|
/// A short reason from the failure of a method matcher: `was 17 (expected
/// >= 18)`. Other errors give their message.
fn mismatch_reason(error : Error) -> String {
  let lines = describe_error(error).split("\n").map(l => l.to_owned()).collect()
  let value_of = (name : String) => {
    lines
    .search_by(line => line.has_prefix("\{name}:"))
    .map(i => {
      lines[i].view(start_offset=name.length() + 1).trim(chars=" ").to_owned()
    })
  }
  match (value_of("Received"), value_of("Expected")) {
    (Some(received), Some(expected)) if !received.is_empty() &&
      !expected.is_empty() => "was \{received} (expected \{expected})"
    _ => lines.join("\n")
  }
}

///|
/// Assert the actual value matches `matcher`.
#callsite(autofill(loc))
pub fn[T : @debug.Debug] Expectation::to(
  self : Expectation[T],
  matcher : Matcher[T],
  loc~ : SourceLoc,
) -> Unit raise Error {
  let mismatch = (matcher.check)(self.actual)
  self.assert_that(
    mismatch is None,
    "to",
    args="matcher",
    expected=() => (matcher.describe)(),
    received=() => show(self.actual),
    details=() => {
      match mismatch {
        Some(reason) if !self.negated => [("Mismatch", reason)]
        _ => []
      }
    },
    loc~,
  )
}

///|
/// Assert at least one element of an Array matches `matcher`. A failure
/// shows why each element does not match.
#callsite(autofill(loc))
pub fn[T : @debug.Debug] Expectation::to_contain_element_matching(
  self : Expectation[Array[T]],
  matcher : Matcher[T],
  loc~ : SourceLoc,
) -> Unit raise Error {
  let reasons = self.actual.map(element => (matcher.check)(element))
  self.assert_that(
    reasons.iter().any(reason => reason is None),
    "to_contain_element_matching",
    args="matcher",
    expected=() => "containing an element: \{(matcher.describe)()}",
    received=() => show(self.actual),
    details=() => {
      if self.negated || reasons.is_empty() {
        return []
      }
      let lines = []
      for i, reason in reasons {
        if reason is Some(text) {
          lines.push("index \{i}: " + text.replace_all(old="\n", new="; "))
        }
      }
      [("Mismatches", lines.join("\n"))]
    },
    loc~,
  )
}
