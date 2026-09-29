// Matchers for numbers.

///|
/// A number type with a zero. Implement this trait to use `to_be_positive`,
/// `to_be_negative` and `to_be_zero` on your own number type.
pub(open) trait Number: Compare {
  fn zero() -> Self
}

///|
pub impl Number for Int with fn zero() {
  0
}

///|
pub impl Number for Int16 with fn zero() {
  0
}

///|
pub impl Number for Int64 with fn zero() {
  0
}

///|
pub impl Number for UInt with fn zero() {
  0
}

///|
pub impl Number for UInt16 with fn zero() {
  0
}

///|
pub impl Number for UInt64 with fn zero() {
  0
}

///|
pub impl Number for Double with fn zero() {
  0.0
}

///|
pub impl Number for Float with fn zero() {
  0.0
}

///|
/// Assert the actual number is greater than zero.
#callsite(autofill(loc))
pub fn[T : Number + @debug.Debug] Expectation::to_be_positive(
  self : Expectation[T],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.assert_that(
    self.actual > (Number::zero() : T),
    "to_be_positive",
    expected=() => "> \{show((Number::zero() : T))}",
    received=() => show(self.actual),
    loc~,
  )
}

///|
/// Assert the actual number is less than zero.
#callsite(autofill(loc))
pub fn[T : Number + @debug.Debug] Expectation::to_be_negative(
  self : Expectation[T],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.assert_that(
    self.actual < (Number::zero() : T),
    "to_be_negative",
    expected=() => "< \{show((Number::zero() : T))}",
    received=() => show(self.actual),
    loc~,
  )
}

///|
/// Assert the actual number is zero. For floating-point numbers, `-0.0` is
/// zero too.
#callsite(autofill(loc))
pub fn[T : Number + @debug.Debug] Expectation::to_be_zero(
  self : Expectation[T],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.assert_that(
    self.actual == (Number::zero() : T),
    "to_be_zero",
    expected=() => show((Number::zero() : T)),
    received=() => show(self.actual),
    loc~,
  )
}

///|
/// Assert the actual value is between `low` and `high`. Both bounds are
/// inclusive unless you set `low_inclusive` or `high_inclusive` to `false`.
#callsite(autofill(loc))
pub fn[T : Compare + @debug.Debug] Expectation::to_be_between(
  self : Expectation[T],
  low : T,
  high : T,
  low_inclusive? : Bool = true,
  high_inclusive? : Bool = true,
  loc~ : SourceLoc,
) -> Unit raise Error {
  let above_low = if low_inclusive {
    self.actual >= low
  } else {
    self.actual > low
  }
  let below_high = if high_inclusive {
    self.actual <= high
  } else {
    self.actual < high
  }
  self.assert_that(
    above_low && below_high,
    "to_be_between",
    args="low, high",
    expected=() => {
      let bounds = match (low_inclusive, high_inclusive) {
        (true, true) => "inclusive"
        (false, false) => "exclusive"
        _ => {
          let describe = (value, inclusive) => {
            "\{show(value)} \{if inclusive { "inclusive" } else { "exclusive" }}"
          }
          "\{describe(low, low_inclusive)}, \{describe(high, high_inclusive)}"
        }
      }
      "between \{show(low)} and \{show(high)} (\{bounds})"
    },
    received=() => show(self.actual),
    loc~,
  )
}

///|
/// A floating-point type: `Double` or `Float`.
pub trait FloatingPoint {
  /// The value as a `Double`.
  fn as_double(Self) -> Double
  /// The number of representable values between two values.
  fn ulp_distance(Self, Self) -> UInt64
  /// The value as text, with a decimal point.
  fn describe(Self) -> String
}

///|
pub impl FloatingPoint for Double with fn as_double(self) {
  self
}

///|
pub impl FloatingPoint for Double with fn ulp_distance(self, other) {
  // Map the bits to integers that have the same order as the values.
  let ordered = (x : Double) => {
    let bits = x.reinterpret_as_int64()
    if bits < 0L {
      -9223372036854775808L - bits
    } else {
      bits
    }
  }
  let a = ordered(self)
  let b = ordered(other)
  // The difference always fits in `UInt64`, so wrapping subtraction is exact.
  if a >= b {
    a.reinterpret_as_uint64() - b.reinterpret_as_uint64()
  } else {
    b.reinterpret_as_uint64() - a.reinterpret_as_uint64()
  }
}

///|
pub impl FloatingPoint for Double with fn describe(self) {
  show_double(self)
}

///|
pub impl FloatingPoint for Float with fn as_double(self) {
  self.to_double()
}

///|
pub impl FloatingPoint for Float with fn ulp_distance(self, other) {
  let ordered = (x : Float) => {
    let bits = x.reinterpret_as_int()
    if bits < 0 {
      (-2147483648 - bits).to_int64()
    } else {
      bits.to_int64()
    }
  }
  (ordered(self) - ordered(other)).abs().reinterpret_as_uint64()
}

///|
pub impl FloatingPoint for Float with fn describe(self) {
  let text = self.to_string()
  if self.is_nan() || self.is_inf() || text.contains(".") || text.contains("e") {
    text
  } else {
    "\{text}.0"
  }
}

///|
/// Assert the actual value is NaN.
#callsite(autofill(loc))
pub fn[F : FloatingPoint] Expectation::to_be_nan(
  self : Expectation[F],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.assert_that(
    self.actual.as_double().is_nan(),
    "to_be_nan",
    expected=() => "NaN",
    received=() => self.actual.describe(),
    loc~,
  )
}

///|
/// Assert the actual value is finite: not NaN and not infinite.
#callsite(autofill(loc))
pub fn[F : FloatingPoint] Expectation::to_be_finite(
  self : Expectation[F],
  loc~ : SourceLoc,
) -> Unit raise Error {
  let value = self.actual.as_double()
  self.assert_that(
    !value.is_nan() && !value.is_inf(),
    "to_be_finite",
    expected=() => "a finite number",
    received=() => self.actual.describe(),
    loc~,
  )
}

///|
/// Assert the actual value is close to `expected`. NaN is never close to any
/// value. Give at most one tolerance:
///
/// - `tolerance`: the largest absolute difference. This is the default, with
///   `1.0e-9`.
/// - `relative`: the largest difference as a fraction of the larger of the
///   two magnitudes, for example `0.01` for 1%.
/// - `ulps`: the largest number of representable values between the two
///   values (units in the last place).
#callsite(autofill(loc))
pub fn[F : FloatingPoint] Expectation::to_be_close_to(
  self : Expectation[F],
  expected : F,
  tolerance? : Double,
  relative? : Double,
  ulps? : Int,
  loc~ : SourceLoc,
) -> Unit raise Error {
  let given = [
    if tolerance is Some(_) {
      Some("tolerance")
    } else {
      None
    },
    if relative is Some(_) {
      Some("relative")
    } else {
      None
    },
    if ulps is Some(_) {
      Some("ulps")
    } else {
      None
    },
  ].filter_map(x => x)
  // The absolute tolerance is the default, so the headline names it when no
  // tolerance is given.
  let args = if given.is_empty() {
    "expected, tolerance"
  } else {
    ["expected", ..given].join(", ")
  }
  if given.length() > 1 {
    self.report(
      "to_be_close_to",
      args,
      [("Error", "give only one of tolerance, relative and ulps")],
      loc,
    )
  }
  let actual = self.actual.as_double()
  let target = expected.as_double()
  let difference = (actual - target).abs()
  let nan = actual.is_nan() || target.is_nan()
  let magnitude = if actual.abs() > target.abs() {
    actual.abs()
  } else {
    target.abs()
  }
  let relative_difference = if magnitude == 0.0 {
    0.0
  } else {
    difference / magnitude
  }
  let distance = self.actual.ulp_distance(expected)
  let (pass, description, details) = match (relative, ulps) {
    (Some(fraction), _) =>
      (
        !nan && relative_difference <= fraction,
        "within relative tolerance \{show_double(fraction)} of \{expected.describe()}",
        [
          ("Difference", show_double(difference)),
          ("Relative difference", show_double(relative_difference)),
        ],
      )
    (_, Some(count)) =>
      (
        !nan && count >= 0 && distance <= count.to_uint64(),
        "within \{count} ULPs of \{expected.describe()}",
        [
          ("Difference", show_double(difference)),
          ("ULP distance", distance.to_string()),
        ],
      )
    _ => {
      let limit = tolerance.unwrap_or(1.0e-9)
      (
        difference <= limit,
        "within \{show_double(limit)} of \{expected.describe()}",
        [("Difference", show_double(difference))],
      )
    }
  }
  self.assert_that(
    pass,
    "to_be_close_to",
    args~,
    expected=() => description,
    received=() => self.actual.describe(),
    details=() => details,
    loc~,
  )
}
