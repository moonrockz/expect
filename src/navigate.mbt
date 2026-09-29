// Navigation
//
// Navigation methods return an expectation on a part of the value under
// test. The label becomes a path to that part, so a failure shows where the
// value came from: `user.address.city: expect(received).to_equal(expected)`.
//
// Navigation changes the value under test, so it cannot be used after
// `not()`.

///|
/// An expectation on `value`, a part of the value under test. `segment`
/// extends the label: `name` gives `label.name`, `[0]` gives `label[0]`.
fn[T, U] Expectation::navigate(
  self : Expectation[T],
  value : U,
  segment : String,
) -> Expectation[U] {
  let label = if self.label.is_empty() {
    segment
  } else if segment.has_prefix("[") {
    self.label + segment
  } else {
    "\{self.label}.\{segment}"
  }
  { actual: value, negated: false, label, reason: self.reason, }
}

///|
/// Apply `f` to the value under test and return an expectation on the
/// result. `name` extends the label, so failures show the path to the value.
/// Cannot be used after `not()`.
#callsite(autofill(loc))
pub fn[T, U] Expectation::get(
  self : Expectation[T],
  name : String,
  f : (T) -> U,
  loc~ : SourceLoc,
) -> Expectation[U] raise Error {
  self.check_not_negated("get", loc)
  self.navigate(f(self.actual), name)
}

///|
/// Assert an Array has an element at `index`, and return an expectation on
/// it. Cannot be used after `not()`.
#callsite(autofill(loc))
pub fn[T : @debug.Debug] Expectation::element(
  self : Expectation[Array[T]],
  index : Int,
  loc~ : SourceLoc,
) -> Expectation[T] raise Error {
  self.check_not_negated("element", loc)
  if index < 0 || index >= self.actual.length() {
    self.report(
      "element",
      "index",
      [
        ("Expected", "an element at index \{index}"),
        ("Received", show(self.actual)),
        ("Length", self.actual.length().to_string()),
      ],
      loc,
    )
  }
  self.navigate(self.actual[index], "[\{index}]")
}

///|
/// Assert an Array is not empty, and return an expectation on its first
/// element. Cannot be used after `not()`.
#callsite(autofill(loc))
pub fn[T : @debug.Debug] Expectation::first(
  self : Expectation[Array[T]],
  loc~ : SourceLoc,
) -> Expectation[T] raise Error {
  self.check_not_negated("first", loc)
  match self.actual {
    [first, ..] => self.navigate(first, "[0]")
    [] =>
      self.report(
        "first",
        "",
        [("Expected", "a first element"), ("Received", show(self.actual))],
        loc,
      )
  }
}

///|
/// Assert an Array is not empty, and return an expectation on its last
/// element. Cannot be used after `not()`.
#callsite(autofill(loc))
pub fn[T : @debug.Debug] Expectation::last(
  self : Expectation[Array[T]],
  loc~ : SourceLoc,
) -> Expectation[T] raise Error {
  self.check_not_negated("last", loc)
  match self.actual {
    [.., last] => self.navigate(last, "[\{self.actual.length() - 1}]")
    [] =>
      self.report(
        "last",
        "",
        [("Expected", "a last element"), ("Received", show(self.actual))],
        loc,
      )
  }
}

///|
/// Assert an Array has exactly one element, and return an expectation on it.
/// Cannot be used after `not()`.
#callsite(autofill(loc))
pub fn[T : @debug.Debug] Expectation::single(
  self : Expectation[Array[T]],
  loc~ : SourceLoc,
) -> Expectation[T] raise Error {
  self.check_not_negated("single", loc)
  match self.actual {
    [only] => self.navigate(only, "[0]")
    _ =>
      self.report(
        "single",
        "",
        [
          ("Expected", "exactly one element"),
          ("Received", show(self.actual)),
          ("Length", self.actual.length().to_string()),
        ],
        loc,
      )
  }
}

///|
/// Assert a Map contains `key`, and return an expectation on its value.
/// Cannot be used after `not()`.
#callsite(autofill(loc))
pub fn[K : Hash + Eq + @debug.Debug, V : @debug.Debug] Expectation::value_at(
  self : Expectation[Map[K, V]],
  key : K,
  loc~ : SourceLoc,
) -> Expectation[V] raise Error {
  self.check_not_negated("value_at", loc)
  match self.actual.get(key) {
    Some(value) => self.navigate(value, "[\{show(key)}]")
    None =>
      self.report(
        "value_at",
        "key",
        [
          ("Expected", "containing key \{show(key)}"),
          ("Received", show(self.actual)),
        ],
        loc,
      )
  }
}

///|
/// Return an expectation on the first part of a pair. Cannot be used after
/// `not()`.
#callsite(autofill(loc))
pub fn[A, B] Expectation::fst(
  self : Expectation[(A, B)],
  loc~ : SourceLoc,
) -> Expectation[A] raise Error {
  self.check_not_negated("fst", loc)
  self.navigate(self.actual.0, "0")
}

///|
/// Return an expectation on the second part of a pair. Cannot be used after
/// `not()`.
#callsite(autofill(loc))
pub fn[A, B] Expectation::snd(
  self : Expectation[(A, B)],
  loc~ : SourceLoc,
) -> Expectation[B] raise Error {
  self.check_not_negated("snd", loc)
  self.navigate(self.actual.1, "1")
}

///|
/// Run several matchers on the same value:
/// `expect(age).all(it => { it.to_be_greater_than(0); it.to_be_less_than(150) })`.
///
/// Matchers return `Unit` and do not chain, because MoonBit does not let a
/// statement ignore a returned value. Use `all` instead. Cannot be used after
/// `not()`.
#callsite(autofill(loc))
pub fn[T] Expectation::all(
  self : Expectation[T],
  block : (Expectation[T]) -> Unit raise Error,
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.check_not_negated("all", loc)
  block(self)
}
