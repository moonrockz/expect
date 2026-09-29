///|
/// Wraps a value for fluent assertion chaining.
pub struct Expectation[T] {
  actual : T
  negated : Bool
  label : String
}

///|
/// Create an expectation on a value.
///
/// When `label` is not empty, failure messages start with `"<label>: "`.
pub fn[T] expect(actual : T, label? : String = "") -> Expectation[T] {
  { actual, negated: false, label, }
}

///|
/// Create an expectation on a function, for use with `to_raise`.
///
/// Use an arrow function so that MoonBit infers the error type:
/// `expect_call(() => parse("bad")).to_raise()`.
pub fn expect_call(
  f : () -> Unit raise Error,
  label? : String = "",
) -> Expectation[() -> Unit raise Error] {
  { actual: f, negated: false, label, }
}

///|
/// Negate the next matcher.
pub fn[T] Expectation::not(self : Expectation[T]) -> Expectation[T] {
  { ..self, negated: !self.negated, }
}

// Failure messages
//
// Every failure has the same layout:
//
//   <loc> FAILED: <label>: expect(received).not.to_equal(expected)
//   Expected: not 5
//   Received: 5
//
// `<loc>` is the location of the matcher call. Values that span more than one
// line start on their own line, indented, and very long values are shortened.

///|
/// Raise a failure unless `pass` agrees with the negation state.
/// The details are built only on failure.
fn[T] Expectation::verify(
  self : Expectation[T],
  pass : Bool,
  matcher : String,
  args : String,
  details : () -> Array[(String, String)],
  loc : SourceLoc,
) -> Unit raise Error {
  if pass == self.negated {
    self.report(matcher, args, details(), loc)
  }
}

///|
fn[T, U] Expectation::report(
  self : Expectation[T],
  matcher : String,
  args : String,
  details : Array[(String, String)],
  loc : SourceLoc,
) -> U raise Error {
  let label = if self.label.is_empty() { "" } else { "\{self.label}: " }
  let not_ = if self.negated { ".not" } else { "" }
  let headline = "\{label}expect(received)\{not_}.\{matcher}(\{args})"
  fail("\{headline}\n\{render_details(details)}", loc~)
}

///|
/// The `Expected` line. Negation adds `not`.
fn[T] Expectation::expected_line(
  self : Expectation[T],
  value : String,
) -> (String, String) {
  ("Expected", if self.negated { "not \{value}" } else { value })
}

///|
/// Unwrap helpers change the value under test, so negation has no meaning.
fn[T] Expectation::check_not_negated(
  self : Expectation[T],
  matcher : String,
  loc : SourceLoc,
) -> Unit raise Error {
  if self.negated {
    self.report(
      matcher,
      "",
      [("Error", "\{matcher} cannot be used after not()")],
      loc,
    )
  }
}

///|
fn[T : @debug.Debug] show(value : T) -> String {
  @debug.to_string(value)
}

///|
/// Show a Double with a decimal point, so that `1.0` does not print as `1`.
fn show_double(value : Double) -> String {
  let text = value.to_string()
  if value.is_nan() ||
    value.is_inf() ||
    text.contains(".") ||
    text.contains("e") {
    text
  } else {
    "\{text}.0"
  }
}

///|
/// Values with more lines than this are shortened.
let max_value_lines = 30

///|
/// Lines kept from the start and the end of a shortened value.
let kept_head_lines = 15

///|
let kept_tail_lines = 5

///|
/// The name of the diff detail. It always starts on its own line, so its
/// long name does not push the other values to the right.
let diff_name = "Diff (- expected, + received)"

///|
fn render_details(details : Array[(String, String)]) -> String {
  let width = details.fold(init=0, (width, detail) => {
    let length = detail.0.length()
    if detail.0 != diff_name && length > width {
      length
    } else {
      width
    }
  })
  let builder = StringBuilder()
  for i, detail in details {
    let (name, value) = detail
    if i > 0 {
      builder.write_string("\n")
    }
    let lines = value.split("\n").map(line => line.to_owned()).collect()
    // Diff hunks already leave out unchanged lines.
    let lines = if name == diff_name { lines } else { shorten(lines) }
    if lines.length() == 1 && name != diff_name {
      builder.write_string("\{name}:")
      builder.write_string(" ".repeat(width - name.length() + 1))
      builder.write_string(lines[0])
    } else {
      builder.write_string("\{name}:")
      for line in lines {
        builder.write_string("\n  \{line}")
      }
    }
  }
  builder.to_string()
}

///|
fn shorten(lines : Array[String]) -> Array[String] {
  if lines.length() <= max_value_lines {
    return lines
  }
  let omitted = lines.length() - kept_head_lines - kept_tail_lines
  [
    ..lines[:kept_head_lines],
    "... \{omitted} more lines ...",
    ..lines[lines.length() - kept_tail_lines:],
  ]
}

///|
/// The message of an error. For a `Failure` raised by `fail`, this removes
/// the `<loc> FAILED: ` prefix.
fn describe_error(error : Error) -> String {
  match error {
    Failure(message) => {
      let marker = " FAILED: "
      match message.find(marker) {
        Some(index) =>
          message.view(start_offset=index + marker.length()).to_owned()
        None => message
      }
    }
    _ => error.to_string()
  }
}

///|
/// Assert the actual value equals the expected value.
#callsite(autofill(loc))
pub fn[T : Eq + @debug.Debug] Expectation::to_equal(
  self : Expectation[T],
  expected : T,
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.verify(
    self.actual == expected,
    "to_equal",
    "expected",
    () => {
      let expected_text = show(expected)
      let actual_text = show(self.actual)
      let details = [
        self.expected_line(expected_text),
        ("Received", actual_text),
      ]
      // For long values the diff is enough on its own.
      if !self.negated && line_diff(expected_text, actual_text) is Some(diff) {
        if expected_text.contains("\n") || actual_text.contains("\n") {
          details.clear()
        }
        details.push((diff_name, diff))
      }
      details
    },
    loc,
  )
}

///|
/// Assert the actual value does not equal the given value.
#callsite(autofill(loc))
pub fn[T : Eq + @debug.Debug] Expectation::to_not_equal(
  self : Expectation[T],
  other : T,
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.verify(
    self.actual != other,
    "to_not_equal",
    "expected",
    () => {
      [
        (
          "Expected",
          if self.negated {
            show(other)
          } else {
            "not \{show(other)}"
          },
        ),
        ("Received", show(self.actual)),
      ]
    },
    loc,
  )
}

///|
/// Assert the actual value satisfies a predicate.
#callsite(autofill(loc))
pub fn[T : @debug.Debug] Expectation::to_satisfy(
  self : Expectation[T],
  predicate : (T) -> Bool,
  description? : String = "predicate",
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.verify(
    predicate(self.actual),
    "to_satisfy",
    "predicate",
    () => [self.expected_line(description), ("Received", show(self.actual))],
    loc,
  )
}

///|
/// Assert the actual boolean value is true.
#callsite(autofill(loc))
pub fn Expectation::to_be_true(
  self : Expectation[Bool],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.verify(
    self.actual,
    "to_be_true",
    "",
    () => [self.expected_line("true"), ("Received", show(self.actual))],
    loc,
  )
}

///|
/// Assert the actual boolean value is false.
#callsite(autofill(loc))
pub fn Expectation::to_be_false(
  self : Expectation[Bool],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.verify(
    !self.actual,
    "to_be_false",
    "",
    () => [self.expected_line("false"), ("Received", show(self.actual))],
    loc,
  )
}

///|
/// Assert the actual value is greater than the given value.
#callsite(autofill(loc))
pub fn[T : Compare + @debug.Debug] Expectation::to_be_greater_than(
  self : Expectation[T],
  other : T,
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.verify(
    self.actual > other,
    "to_be_greater_than",
    "expected",
    () => {
      [self.expected_line("> \{show(other)}"), ("Received", show(self.actual))]
    },
    loc,
  )
}

///|
/// Assert the actual value is greater than or equal to the given value.
#callsite(autofill(loc))
pub fn[T : Compare + @debug.Debug] Expectation::to_be_greater_than_or_equal(
  self : Expectation[T],
  other : T,
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.verify(
    self.actual >= other,
    "to_be_greater_than_or_equal",
    "expected",
    () => {
      [self.expected_line(">= \{show(other)}"), ("Received", show(self.actual))]
    },
    loc,
  )
}

///|
/// Assert the actual value is less than the given value.
#callsite(autofill(loc))
pub fn[T : Compare + @debug.Debug] Expectation::to_be_less_than(
  self : Expectation[T],
  other : T,
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.verify(
    self.actual < other,
    "to_be_less_than",
    "expected",
    () => {
      [self.expected_line("< \{show(other)}"), ("Received", show(self.actual))]
    },
    loc,
  )
}

///|
/// Assert the actual value is less than or equal to the given value.
#callsite(autofill(loc))
pub fn[T : Compare + @debug.Debug] Expectation::to_be_less_than_or_equal(
  self : Expectation[T],
  other : T,
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.verify(
    self.actual <= other,
    "to_be_less_than_or_equal",
    "expected",
    () => {
      [self.expected_line("<= \{show(other)}"), ("Received", show(self.actual))]
    },
    loc,
  )
}

///|
/// Assert the actual value is between `low` and `high`, inclusive.
#callsite(autofill(loc))
pub fn[T : Compare + @debug.Debug] Expectation::to_be_between(
  self : Expectation[T],
  low : T,
  high : T,
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.verify(
    low <= self.actual && self.actual <= high,
    "to_be_between",
    "low, high",
    () => {
      [
        self.expected_line("between \{show(low)} and \{show(high)} (inclusive)"),
        ("Received", show(self.actual)),
      ]
    },
    loc,
  )
}

///|
/// Assert the actual Double is within `tolerance` of the expected value.
/// NaN is never close to any value.
#callsite(autofill(loc))
pub fn Expectation::to_be_close_to(
  self : Expectation[Double],
  expected : Double,
  tolerance? : Double = 1.0e-9,
  loc~ : SourceLoc,
) -> Unit raise Error {
  let difference = (self.actual - expected).abs()
  self.verify(
    difference <= tolerance,
    "to_be_close_to",
    "expected, tolerance",
    () => {
      [
        self.expected_line(
          "within \{show_double(tolerance)} of \{show_double(expected)}",
        ),
        ("Received", show_double(self.actual)),
        ("Difference", show_double(difference)),
      ]
    },
    loc,
  )
}

///|
/// Assert the actual Option value is Some.
#callsite(autofill(loc))
pub fn[T] Expectation::to_be_some(
  self : Expectation[T?],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.verify(
    self.actual is Some(_),
    "to_be_some",
    "",
    () => {
      [
        self.expected_line("Some(_)"),
        ("Received", if self.actual is Some(_) { "Some(_)" } else { "None" }),
      ]
    },
    loc,
  )
}

///|
/// Assert the actual Option value is None.
#callsite(autofill(loc))
pub fn[T : @debug.Debug] Expectation::to_be_none(
  self : Expectation[T?],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.verify(
    self.actual is None,
    "to_be_none",
    "",
    () => [self.expected_line("None"), ("Received", show(self.actual))],
    loc,
  )
}

///|
/// Assert the actual Option value is Some, and return an expectation on the
/// inner value. Cannot be used after `not()`.
#callsite(autofill(loc))
pub fn[T] Expectation::unwrap_some(
  self : Expectation[T?],
  loc~ : SourceLoc,
) -> Expectation[T] raise Error {
  self.check_not_negated("unwrap_some", loc)
  match self.actual {
    Some(value) => { actual: value, negated: false, label: self.label, }
    None =>
      self.report(
        "unwrap_some",
        "",
        [("Expected", "Some(_)"), ("Received", "None")],
        loc,
      )
  }
}

///|
/// Assert the actual Result value is Ok.
#callsite(autofill(loc))
pub fn[T : @debug.Debug, E : @debug.Debug] Expectation::to_be_ok(
  self : Expectation[Result[T, E]],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.verify(
    self.actual is Ok(_),
    "to_be_ok",
    "",
    () => [self.expected_line("Ok(_)"), ("Received", show(self.actual))],
    loc,
  )
}

///|
/// Assert the actual Result value is Err.
#callsite(autofill(loc))
pub fn[T : @debug.Debug, E : @debug.Debug] Expectation::to_be_err(
  self : Expectation[Result[T, E]],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.verify(
    self.actual is Err(_),
    "to_be_err",
    "",
    () => [self.expected_line("Err(_)"), ("Received", show(self.actual))],
    loc,
  )
}

///|
/// Assert the actual Result value is Ok, and return an expectation on the
/// inner value. Cannot be used after `not()`.
#callsite(autofill(loc))
pub fn[T, E : @debug.Debug] Expectation::unwrap_ok(
  self : Expectation[Result[T, E]],
  loc~ : SourceLoc,
) -> Expectation[T] raise Error {
  self.check_not_negated("unwrap_ok", loc)
  match self.actual {
    Ok(value) => { actual: value, negated: false, label: self.label, }
    Err(error) =>
      self.report(
        "unwrap_ok",
        "",
        [("Expected", "Ok(_)"), ("Received", "Err(\{show(error)})")],
        loc,
      )
  }
}

///|
/// Assert the actual Result value is Err, and return an expectation on the
/// error. Cannot be used after `not()`.
#callsite(autofill(loc))
pub fn[T : @debug.Debug, E] Expectation::unwrap_err(
  self : Expectation[Result[T, E]],
  loc~ : SourceLoc,
) -> Expectation[E] raise Error {
  self.check_not_negated("unwrap_err", loc)
  match self.actual {
    Err(error) => { actual: error, negated: false, label: self.label, }
    Ok(value) =>
      self.report(
        "unwrap_err",
        "",
        [("Expected", "Err(_)"), ("Received", "Ok(\{show(value)})")],
        loc,
      )
  }
}

///|
/// Assert the function raises an error. Create the expectation with
/// `expect_call`.
///
/// When `containing` is given, the error's `to_string()` must also contain it.
/// Negated, the assertion fails only when the function raises an error that
/// matches.
#callsite(autofill(loc))
pub fn Expectation::to_raise(
  self : Expectation[() -> Unit raise Error],
  containing? : String,
  loc~ : SourceLoc,
) -> Unit raise Error {
  let raised : Error? = try (self.actual)() catch {
    error => Some(error)
  } noraise {
    _ => None
  }
  let pass = match (raised, containing) {
    (Some(error), Some(text)) => error.to_string().contains(text)
    (Some(_), None) => true
    (None, _) => false
  }
  self.verify(
    pass,
    "to_raise",
    if containing is Some(_) {
      "containing"
    } else {
      ""
    },
    () => {
      [
        self.expected_line(
          match containing {
            Some(text) => "an error containing \{show(text)}"
            None => "an error"
          },
        ),
        (
          "Received",
          match raised {
            Some(error) => "error \{show(describe_error(error))}"
            None => "no error"
          },
        ),
      ]
    },
    loc,
  )
}

///|
/// Assert a String contains the given substring.
#callsite(autofill(loc))
pub fn Expectation::to_contain(
  self : Expectation[String],
  substring : String,
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.verify(
    self.actual.contains(substring),
    "to_contain",
    "expected",
    () => {
      [
        self.expected_line("containing \{show(substring)}"),
        ("Received", show(self.actual)),
      ]
    },
    loc,
  )
}

///|
/// Assert a String starts with the given prefix.
#callsite(autofill(loc))
pub fn Expectation::to_start_with(
  self : Expectation[String],
  prefix : String,
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.verify(
    self.actual.has_prefix(prefix),
    "to_start_with",
    "expected",
    () => {
      [
        self.expected_line("starting with \{show(prefix)}"),
        ("Received", show(self.actual)),
      ]
    },
    loc,
  )
}

///|
/// Assert a String ends with the given suffix.
#callsite(autofill(loc))
pub fn Expectation::to_end_with(
  self : Expectation[String],
  suffix : String,
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.verify(
    self.actual.has_suffix(suffix),
    "to_end_with",
    "expected",
    () => {
      [
        self.expected_line("ending with \{show(suffix)}"),
        ("Received", show(self.actual)),
      ]
    },
    loc,
  )
}

///|
/// Assert a String matches a regular expression. The match is a search: it
/// can start anywhere in the string. Use `^` and `$` to match the whole
/// string.
///
/// The pattern uses the syntax of `@string.Regex`. `\d`, `\s` and `\w` are
/// not supported; use POSIX classes such as `[[:digit:]]`. An invalid pattern
/// fails the assertion.
#callsite(autofill(loc))
pub fn Expectation::to_match(
  self : Expectation[String],
  pattern : String,
  loc~ : SourceLoc,
) -> Unit raise Error {
  let regex = @string.Regex(pattern) catch {
    error =>
      self.report(
        "to_match",
        "pattern",
        [
          ("Error", "invalid regex pattern \{show(pattern)}"),
          ("Cause", error.to_string()),
        ],
        loc,
      )
  }
  self.verify(
    regex.execute(self.actual) is Some(_),
    "to_match",
    "pattern",
    () => {
      [
        self.expected_line("matching \{show(pattern)}"),
        ("Received", show(self.actual)),
      ]
    },
    loc,
  )
}

///|
/// Assert an Array contains the given element.
#callsite(autofill(loc))
pub fn[T : Eq + @debug.Debug] Expectation::to_contain_element(
  self : Expectation[Array[T]],
  element : T,
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.verify(
    self.actual.contains(element),
    "to_contain_element",
    "expected",
    () => {
      [
        self.expected_line("containing \{show(element)}"),
        ("Received", show(self.actual)),
      ]
    },
    loc,
  )
}

///|
/// Assert an Array contains every one of the given elements.
/// Negated, it asserts that at least one element is missing.
#callsite(autofill(loc))
pub fn[T : Eq + @debug.Debug] Expectation::to_contain_all(
  self : Expectation[Array[T]],
  elements : Array[T],
  loc~ : SourceLoc,
) -> Unit raise Error {
  let missing = elements.filter(e => !self.actual.contains(e))
  self.verify(
    missing.is_empty(),
    "to_contain_all",
    "expected",
    () => {
      let details = [
        self.expected_line("containing all of \{show(elements)}"),
        ("Received", show(self.actual)),
      ]
      if !self.negated {
        details.push(("Missing", show(missing)))
      }
      details
    },
    loc,
  )
}

///|
/// Assert an Array has the same elements as `expected`, in any order.
/// Duplicates count: `[1, 1, 2]` does not match `[1, 2, 2]`.
#callsite(autofill(loc))
pub fn[T : Eq + @debug.Debug] Expectation::to_equal_ignoring_order(
  self : Expectation[Array[T]],
  expected : Array[T],
  loc~ : SourceLoc,
) -> Unit raise Error {
  let (missing, extra) = unmatched_elements(self.actual, expected)
  self.verify(
    missing.is_empty() && extra.is_empty(),
    "to_equal_ignoring_order",
    "expected",
    () => {
      let details = [
        self.expected_line("\{show(expected)} in any order"),
        ("Received", show(self.actual)),
      ]
      if !self.negated {
        details.push(("Missing", show(missing)))
        details.push(("Extra", show(extra)))
      }
      details
    },
    loc,
  )
}

///|
/// Pair each element of `actual` with an equal, unused element of
/// `expected`. Return the elements of `expected` with no pair (missing) and
/// the elements of `actual` with no pair (extra).
fn[T : Eq] unmatched_elements(
  actual : Array[T],
  expected : Array[T],
) -> (Array[T], Array[T]) {
  let used = FixedArray::make(expected.length(), false)
  let extra = []
  for item in actual {
    let mut found = false
    for i, candidate in expected {
      if !used[i] && candidate == item {
        used[i] = true
        found = true
        break
      }
    }
    if !found {
      extra.push(item)
    }
  }
  let missing = []
  for i, candidate in expected {
    if !used[i] {
      missing.push(candidate)
    }
  }
  (missing, extra)
}

///|
/// Assert every element of an Array satisfies a predicate.
/// Negated, it asserts that at least one element does not.
#callsite(autofill(loc))
pub fn[T : @debug.Debug] Expectation::to_all_satisfy(
  self : Expectation[Array[T]],
  predicate : (T) -> Bool,
  description? : String = "predicate",
  loc~ : SourceLoc,
) -> Unit raise Error {
  let failed_index = self.actual.search_by(e => !predicate(e))
  self.verify(
    failed_index is None,
    "to_all_satisfy",
    "predicate",
    () => {
      let details = [
        self.expected_line("every element to satisfy \{description}"),
        ("Received", show(self.actual)),
      ]
      if failed_index is Some(index) {
        details.push(
          ("Failed at", "index \{index}: \{show(self.actual[index])}"),
        )
      }
      details
    },
    loc,
  )
}

///|
/// Assert a Map contains the given key.
#callsite(autofill(loc))
pub fn[K : Hash + Eq + @debug.Debug, V : @debug.Debug] Expectation::to_contain_key(
  self : Expectation[Map[K, V]],
  key : K,
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.verify(
    self.actual.contains(key),
    "to_contain_key",
    "key",
    () => {
      [
        self.expected_line("containing key \{show(key)}"),
        ("Received", show(self.actual)),
      ]
    },
    loc,
  )
}

///|
/// A value with a length, such as a `String` or an `Array`.
/// Implement this trait to use `to_be_empty` and `to_have_length` on your own
/// types.
pub(open) trait HasLength {
  fn length(Self) -> Int
}

///|
pub impl HasLength for String with fn length(self) {
  self.length()
}

///|
pub impl[T] HasLength for Array[T] with fn length(self) {
  self.length()
}

///|
pub impl[T] HasLength for FixedArray[T] with fn length(self) {
  self.length()
}

///|
pub impl HasLength for Bytes with fn length(self) {
  self.length()
}

///|
pub impl[K, V] HasLength for Map[K, V] with fn length(self) {
  self.length()
}

///|
pub impl[T] HasLength for Set[T] with fn length(self) {
  self.length()
}

///|
/// Assert the actual value is empty.
#callsite(autofill(loc))
pub fn[C : HasLength + @debug.Debug] Expectation::to_be_empty(
  self : Expectation[C],
  loc~ : SourceLoc,
) -> Unit raise Error {
  let actual_len = HasLength::length(self.actual)
  self.verify(
    actual_len == 0,
    "to_be_empty",
    "",
    () => {
      [
        self.expected_line("empty"),
        ("Received", show(self.actual)),
        ("Length", actual_len.to_string()),
      ]
    },
    loc,
  )
}

///|
/// Assert the actual value has the given length.
#callsite(autofill(loc))
pub fn[C : HasLength + @debug.Debug] Expectation::to_have_length(
  self : Expectation[C],
  expected : Int,
  loc~ : SourceLoc,
) -> Unit raise Error {
  let actual_len = HasLength::length(self.actual)
  self.verify(
    actual_len == expected,
    "to_have_length",
    "expected",
    () => {
      [
        self.expected_line("length \{expected}"),
        ("Received", show(self.actual)),
        ("Length", actual_len.to_string()),
      ]
    },
    loc,
  )
}

///|
/// Assert a String is empty.
#deprecated("Use `to_be_empty` instead")
#callsite(autofill(loc))
pub fn Expectation::to_be_empty_string(
  self : Expectation[String],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.to_be_empty(loc~)
}

///|
/// Assert a String has the given length.
#deprecated("Use `to_have_length` instead")
#callsite(autofill(loc))
pub fn Expectation::to_have_length_string(
  self : Expectation[String],
  expected : Int,
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.to_have_length(expected, loc~)
}
