// Matchers for any value, and for `Char`.

///|
/// Assert the actual value equals one of `values`.
#callsite(autofill(loc))
pub fn[T : Eq + @debug.Debug] Expectation::to_be_one_of(
  self : Expectation[T],
  values : Array[T],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.assert_that(
    values.contains(self.actual),
    "to_be_one_of",
    args="values",
    expected=() => "one of \{show(values)}",
    received=() => show(self.actual),
    loc~,
  )
}

///|
/// Assert the actual value is in `set`.
#callsite(autofill(loc))
pub fn[T : Hash + Eq + @debug.Debug] Expectation::to_be_in(
  self : Expectation[T],
  set : Set[T],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.assert_that(
    set.contains(self.actual),
    "to_be_in",
    args="set",
    expected=() => "in \{show(set)}",
    received=() => show(self.actual),
    loc~,
  )
}

///|
/// Show a Char with its code point: `'x' (U+0078)`.
fn show_char(c : Char) -> String {
  let hex = c.to_int().to_string(radix=16).to_upper()
  let padded = "0".repeat(4 - hex.length()) + hex
  "\{show(c)} (U+\{padded})"
}

///|
fn Expectation::check_char(
  self : Expectation[Char],
  pass : Bool,
  matcher : String,
  description : String,
  loc : SourceLoc,
) -> Unit raise Error {
  self.assert_that(
    pass,
    matcher,
    expected=() => description,
    received=() => show_char(self.actual),
    loc~,
  )
}

///|
/// Assert a Char is an ASCII digit, `0` to `9`.
#callsite(autofill(loc))
pub fn Expectation::to_be_digit(
  self : Expectation[Char],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.check_char(
    self.actual.is_ascii_digit(),
    "to_be_digit",
    "an ASCII digit",
    loc,
  )
}

///|
/// Assert a Char is an ASCII letter, `a` to `z` or `A` to `Z`.
#callsite(autofill(loc))
pub fn Expectation::to_be_letter(
  self : Expectation[Char],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.check_char(
    self.actual.is_ascii_alphabetic(),
    "to_be_letter",
    "an ASCII letter",
    loc,
  )
}

///|
/// Assert a Char is whitespace, as `Char::is_whitespace` defines it. This
/// includes Unicode whitespace, not only ASCII.
#callsite(autofill(loc))
pub fn Expectation::to_be_whitespace(
  self : Expectation[Char],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.check_char(
    self.actual.is_whitespace(),
    "to_be_whitespace",
    "whitespace",
    loc,
  )
}

///|
/// Assert a Char is an ASCII upper-case letter, `A` to `Z`.
#callsite(autofill(loc))
pub fn Expectation::to_be_upper_case(
  self : Expectation[Char],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.check_char(
    self.actual.is_ascii_uppercase(),
    "to_be_upper_case",
    "an ASCII upper-case letter",
    loc,
  )
}

///|
/// Assert a Char is an ASCII lower-case letter, `a` to `z`.
#callsite(autofill(loc))
pub fn Expectation::to_be_lower_case(
  self : Expectation[Char],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.check_char(
    self.actual.is_ascii_lowercase(),
    "to_be_lower_case",
    "an ASCII lower-case letter",
    loc,
  )
}
