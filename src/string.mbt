// Matchers for strings.

///|
/// Assert a String equals `expected` when case is ignored.
#callsite(autofill(loc))
pub fn Expectation::to_equal_ignoring_case(
  self : Expectation[String],
  expected : String,
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.assert_that(
    self.actual.to_lower() == expected.to_lower(),
    "to_equal_ignoring_case",
    args="expected",
    expected=() => "\{show(expected)}, ignoring case",
    received=() => show(self.actual),
    loc~,
  )
}

///|
/// The text without whitespace characters.
fn remove_whitespace(text : String) -> String {
  String::from_iter(text.iter().filter(c => !c.is_whitespace()))
}

///|
/// Assert a String equals `expected` when all whitespace is removed from
/// both. Whitespace is every character for which `Char::is_whitespace` is
/// true, such as spaces, tabs and newlines.
#callsite(autofill(loc))
pub fn Expectation::to_equal_ignoring_whitespace(
  self : Expectation[String],
  expected : String,
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.assert_that(
    remove_whitespace(self.actual) == remove_whitespace(expected),
    "to_equal_ignoring_whitespace",
    args="expected",
    expected=() => "\{show(expected)}, ignoring whitespace",
    received=() => show(self.actual),
    loc~,
  )
}

///|
/// Assert a String is empty or holds only whitespace.
#callsite(autofill(loc))
pub fn Expectation::to_be_blank(
  self : Expectation[String],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.assert_that(
    self.actual.iter().all(c => c.is_whitespace()),
    "to_be_blank",
    expected=() => "empty or only whitespace",
    received=() => show(self.actual),
    loc~,
  )
}

///|
/// Assert a String contains `text` exactly `count` times. Occurrences do
/// not overlap: `"aaaa"` contains `"aa"` twice.
#callsite(autofill(loc))
pub fn Expectation::to_contain_times(
  self : Expectation[String],
  text : String,
  count : Int,
  loc~ : SourceLoc,
) -> Unit raise Error {
  if text.is_empty() {
    self.report(
      "to_contain_times",
      "text, count",
      [("Error", "the text to count must not be empty")],
      loc,
    )
  }
  let mut actual_count = 0
  let mut rest = self.actual[:]
  while rest.find(text) is Some(index) {
    actual_count += 1
    rest = rest.view(start_offset=index + text.length())
  }
  self.assert_that(
    actual_count == count,
    "to_contain_times",
    args="text, count",
    expected=() => "containing \{show(text)} \{count} times",
    received=() => show(self.actual),
    details=() => [("Count", actual_count.to_string())],
    loc~,
  )
}

///|
/// Assert a String contains the given parts in this order, with other text
/// allowed between them.
#callsite(autofill(loc))
pub fn Expectation::to_contain_substrings_in_order(
  self : Expectation[String],
  parts : Array[String],
  loc~ : SourceLoc,
) -> Unit raise Error {
  // The first part that is not found, and the part before it.
  let mut missing : (String, String?)? = None
  let mut rest = self.actual[:]
  let mut previous : String? = None
  for part in parts {
    match rest.find(part) {
      Some(index) => {
        rest = rest.view(start_offset=index + part.length())
        previous = Some(part)
      }
      None => {
        missing = Some((part, previous))
        break
      }
    }
  }
  self.assert_that(
    missing is None,
    "to_contain_substrings_in_order",
    args="parts",
    expected=() => "containing \{show(parts)} in this order",
    received=() => show(self.actual),
    details=() => {
      match missing {
        Some((part, Some(before))) if !self.negated =>
          [("Missing", "\{show(part)}, after \{show(before)}")]
        Some((part, None)) if !self.negated => [("Missing", show(part))]
        _ => []
      }
    },
    loc~,
  )
}

///|
/// Assert the whole String matches a regular expression. Unlike `to_match`,
/// the match must start at the start of the string and end at its end.
///
/// The pattern uses the syntax of `@string.Regex`. An invalid pattern fails
/// the assertion.
#callsite(autofill(loc))
pub fn Expectation::to_match_fully(
  self : Expectation[String],
  pattern : String,
  loc~ : SourceLoc,
) -> Unit raise Error {
  let regex = @string.Regex("^(\{pattern})$") catch {
    error =>
      self.report(
        "to_match_fully",
        "pattern",
        [
          ("Error", "invalid regex pattern \{show(pattern)}"),
          ("Cause", error.to_string()),
        ],
        loc,
      )
  }
  self.assert_that(
    regex.execute(self.actual) is Some(_),
    "to_match_fully",
    args="pattern",
    expected=() => "matching \{show(pattern)} in full",
    received=() => show(self.actual),
    loc~,
  )
}
