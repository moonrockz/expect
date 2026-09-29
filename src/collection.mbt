// Collection matchers for arrays.

///|
/// Show the elements at `indices`, one per line: `index 1: 2`.
fn[T : @debug.Debug] show_indexed(
  items : Array[T],
  indices : Array[Int],
) -> String {
  indices.map(i => "index \{i}: \{show(items[i])}").join("\n")
}

///|
/// The indices of the elements that satisfy `predicate`.
fn[T] indices_where(items : Array[T], predicate : (T) -> Bool) -> Array[Int] {
  let indices = []
  for i, item in items {
    if predicate(item) {
      indices.push(i)
    }
  }
  indices
}

///|
/// Assert an Array has exactly the given elements, in the same order.
#callsite(autofill(loc))
pub fn[T : Eq + @debug.Debug] Expectation::to_contain_exactly(
  self : Expectation[Array[T]],
  expected : Array[T],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.assert_that(
    self.actual == expected,
    "to_contain_exactly",
    args="expected",
    expected=() => "exactly \{show(expected)}, in order",
    received=() => show(self.actual),
    details=() => {
      if self.negated {
        return []
      }
      let length = if self.actual.length() > expected.length() {
        self.actual.length()
      } else {
        expected.length()
      }
      for i in 0..<length {
        let want = expected.get(i)
        let got = self.actual.get(i)
        if want != got {
          let describe = (item : T?) => {
            match item {
              Some(value) => show(value)
              None => "nothing"
            }
          }
          return [
            (
              "First difference",
              "index \{i}: expected \{describe(want)}, received \{describe(got)}",
            ),
          ]
        }
      }
      []
    },
    loc~,
  )
}

///|
/// Assert every element of an Array is one of `expected`, and every element
/// of `expected` appears at least once. Order and duplicates do not matter.
#callsite(autofill(loc))
pub fn[T : Eq + @debug.Debug] Expectation::to_contain_only(
  self : Expectation[Array[T]],
  expected : Array[T],
  loc~ : SourceLoc,
) -> Unit raise Error {
  let missing = expected.filter(e => !self.actual.contains(e))
  let extra = distinct(self.actual.filter(e => !expected.contains(e)))
  self.assert_that(
    missing.is_empty() && extra.is_empty(),
    "to_contain_only",
    args="expected",
    expected=() => "only elements of \{show(expected)}, each at least once",
    received=() => show(self.actual),
    details=() => {
      if self.negated {
        []
      } else {
        [("Missing", show(missing)), ("Extra", show(extra))]
      }
    },
    loc~,
  )
}

///|
/// The elements of `items` without repeats, in order of first appearance.
fn[T : Eq] distinct(items : Array[T]) -> Array[T] {
  let result = []
  for item in items {
    if !result.contains(item) {
      result.push(item)
    }
  }
  result
}

///|
/// Assert an Array contains the given elements in this order, with other
/// elements allowed between them.
#callsite(autofill(loc))
pub fn[T : Eq + @debug.Debug] Expectation::to_contain_in_order(
  self : Expectation[Array[T]],
  expected : Array[T],
  loc~ : SourceLoc,
) -> Unit raise Error {
  // The first element of `expected` that is not found, and the index of the
  // element before it.
  let mut missing : (T, Int?)? = None
  let mut next = 0
  let mut previous : Int? = None
  for want in expected {
    let mut found = false
    while next < self.actual.length() {
      next += 1
      if self.actual[next - 1] == want {
        found = true
        previous = Some(next - 1)
        break
      }
    }
    if !found {
      missing = Some((want, previous))
      break
    }
  }
  self.assert_that(
    missing is None,
    "to_contain_in_order",
    args="expected",
    expected=() => "containing \{show(expected)} in this order",
    received=() => show(self.actual),
    details=() => {
      match missing {
        Some((want, Some(index))) if !self.negated =>
          [("Missing", "\{show(want)}, after index \{index}")]
        Some((want, None)) if !self.negated => [("Missing", show(want))]
        _ => []
      }
    },
    loc~,
  )
}

///|
/// Assert an Array starts with the given elements.
#callsite(autofill(loc))
pub fn[T : Eq + @debug.Debug] Expectation::to_start_with_elements(
  self : Expectation[Array[T]],
  prefix : Array[T],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.assert_that(
    self.actual.length() >= prefix.length() &&
    self.actual[:prefix.length()] == prefix[:],
    "to_start_with_elements",
    args="expected",
    expected=() => "starting with \{show(prefix)}",
    received=() => show(self.actual),
    loc~,
  )
}

///|
/// Assert an Array ends with the given elements.
#callsite(autofill(loc))
pub fn[T : Eq + @debug.Debug] Expectation::to_end_with_elements(
  self : Expectation[Array[T]],
  suffix : Array[T],
  loc~ : SourceLoc,
) -> Unit raise Error {
  let start = self.actual.length() - suffix.length()
  self.assert_that(
    start >= 0 && self.actual[start:] == suffix[:],
    "to_end_with_elements",
    args="expected",
    expected=() => "ending with \{show(suffix)}",
    received=() => show(self.actual),
    loc~,
  )
}

///|
/// Assert at least one element of an Array satisfies a predicate.
#callsite(autofill(loc))
pub fn[T : @debug.Debug] Expectation::to_any_satisfy(
  self : Expectation[Array[T]],
  predicate : (T) -> Bool,
  description? : String = "predicate",
  loc~ : SourceLoc,
) -> Unit raise Error {
  let satisfied = indices_where(self.actual, predicate)
  self.assert_that(
    !satisfied.is_empty(),
    "to_any_satisfy",
    args="predicate",
    expected=() => "some element to satisfy \{description}",
    received=() => show(self.actual),
    details=() => {
      if self.negated {
        [("Satisfied at", show_indexed(self.actual, satisfied))]
      } else {
        []
      }
    },
    loc~,
  )
}

///|
/// Assert no element of an Array satisfies a predicate.
#callsite(autofill(loc))
pub fn[T : @debug.Debug] Expectation::to_none_satisfy(
  self : Expectation[Array[T]],
  predicate : (T) -> Bool,
  description? : String = "predicate",
  loc~ : SourceLoc,
) -> Unit raise Error {
  let satisfied = indices_where(self.actual, predicate)
  self.assert_that(
    satisfied.is_empty(),
    "to_none_satisfy",
    args="predicate",
    expected=() => "no element to satisfy \{description}",
    received=() => show(self.actual),
    details=() => {
      if self.negated {
        []
      } else {
        [("Satisfied at", show_indexed(self.actual, satisfied))]
      }
    },
    loc~,
  )
}

///|
/// Assert exactly `count` elements of an Array satisfy a predicate.
#callsite(autofill(loc))
pub fn[T : @debug.Debug] Expectation::to_have_count_satisfying(
  self : Expectation[Array[T]],
  count : Int,
  predicate : (T) -> Bool,
  description? : String = "predicate",
  loc~ : SourceLoc,
) -> Unit raise Error {
  let actual_count = indices_where(self.actual, predicate).length()
  self.assert_that(
    actual_count == count,
    "to_have_count_satisfying",
    args="count, predicate",
    expected=() => "\{count} elements to satisfy \{description}",
    received=() => show(self.actual),
    details=() => [("Count", actual_count.to_string())],
    loc~,
  )
}

///|
/// Assert an Array contains none of the given values.
#callsite(autofill(loc))
pub fn[T : Eq + @debug.Debug] Expectation::to_contain_none_of(
  self : Expectation[Array[T]],
  values : Array[T],
  loc~ : SourceLoc,
) -> Unit raise Error {
  let found = values.filter(v => self.actual.contains(v))
  self.assert_that(
    found.is_empty(),
    "to_contain_none_of",
    args="values",
    expected=() => "containing none of \{show(values)}",
    received=() => show(self.actual),
    details=() => if self.negated { [] } else { [("Found", show(found))] },
    loc~,
  )
}

///|
/// Run one check per element: `checks[i]` runs on the element at index `i`.
/// The Array must have one element for each check. A failed check reports
/// the index in its path, such as `items[1]`. Cannot be used after `not()`.
#callsite(autofill(loc))
pub fn[T : @debug.Debug] Expectation::to_satisfy_respectively(
  self : Expectation[Array[T]],
  checks : Array[(Expectation[T]) -> Unit raise Error],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.check_not_negated("to_satisfy_respectively", loc)
  if self.actual.length() != checks.length() {
    self.report(
      "to_satisfy_respectively",
      "checks",
      [
        ("Expected", "\{checks.length()} elements, one for each check"),
        ("Received", show(self.actual)),
        ("Length", self.actual.length().to_string()),
      ],
      loc,
    )
  }
  for i, check in checks {
    check(self.navigate(self.actual[i], "[\{i}]"))
  }
}

///|
/// The index of the first element that is greater than the element after it.
fn[T, K : Compare] first_out_of_order(items : Array[T], key : (T) -> K) -> Int? {
  for i in 0..<(items.length() - 1) {
    if key(items[i]) > key(items[i + 1]) {
      return Some(i)
    }
  }
  None
}

///|
/// Assert an Array is sorted in ascending order. Equal neighbors are allowed.
#callsite(autofill(loc))
pub fn[T : Compare + @debug.Debug] Expectation::to_be_sorted(
  self : Expectation[Array[T]],
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.check_sorted(
    "to_be_sorted",
    "",
    "sorted in ascending order",
    x => x,
    loc,
  )
}

///|
/// Assert an Array is sorted in ascending order of `key`. Equal keys are
/// allowed.
#callsite(autofill(loc))
pub fn[T : @debug.Debug, K : Compare] Expectation::to_be_sorted_by(
  self : Expectation[Array[T]],
  key : (T) -> K,
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.check_sorted(
    "to_be_sorted_by", "key", "sorted in ascending order of key", key, loc,
  )
}

///|
fn[T : @debug.Debug, K : Compare] Expectation::check_sorted(
  self : Expectation[Array[T]],
  matcher : String,
  args : String,
  description : String,
  key : (T) -> K,
  loc : SourceLoc,
) -> Unit raise Error {
  let out_of_order = first_out_of_order(self.actual, key)
  self.assert_that(
    out_of_order is None,
    matcher,
    args~,
    expected=() => description,
    received=() => show(self.actual),
    details=() => {
      match out_of_order {
        Some(i) =>
          [
            (
              "Out of order",
              "index \{i}: \{show(self.actual[i])}, index \{i + 1}: \{show(self.actual[i + 1])}",
            ),
          ]
        None => []
      }
    },
    loc~,
  )
}

///|
/// Assert no two elements of an Array are equal.
#callsite(autofill(loc))
pub fn[T : Eq + @debug.Debug] Expectation::to_have_no_duplicates(
  self : Expectation[Array[T]],
  loc~ : SourceLoc,
) -> Unit raise Error {
  let duplicates = []
  for i, item in self.actual {
    if self.actual[:i].contains(item) && !duplicates.contains(item) {
      duplicates.push(item)
    }
  }
  self.assert_that(
    duplicates.is_empty(),
    "to_have_no_duplicates",
    expected=() => "no duplicate elements",
    received=() => show(self.actual),
    details=() => {
      if self.negated {
        []
      } else {
        [("Duplicates", show(duplicates))]
      }
    },
    loc~,
  )
}
