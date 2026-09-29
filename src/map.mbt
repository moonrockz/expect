// Matchers for maps.

///|
/// Assert a Map contains the given value under any key.
#callsite(autofill(loc))
pub fn[K : @debug.Debug, V : Eq + @debug.Debug] Expectation::to_contain_value(
  self : Expectation[Map[K, V]],
  value : V,
  loc~ : SourceLoc,
) -> Unit raise Error {
  self.assert_that(
    self.actual.values().any(v => v == value),
    "to_contain_value",
    args="value",
    expected=() => "containing value \{show(value)}",
    received=() => show(self.actual),
    loc~,
  )
}

///|
/// Assert a Map contains `key` with the given value.
#callsite(autofill(loc))
pub fn[K : Hash + Eq + @debug.Debug, V : Eq + @debug.Debug] Expectation::to_contain_entry(
  self : Expectation[Map[K, V]],
  key : K,
  value : V,
  loc~ : SourceLoc,
) -> Unit raise Error {
  let actual_value = self.actual.get(key)
  self.assert_that(
    actual_value is Some(v) && v == value,
    "to_contain_entry",
    args="key, value",
    expected=() => "containing \{show(key)}: \{show(value)}",
    received=() => show(self.actual),
    details=() => {
      if self.negated {
        return []
      }
      match actual_value {
        Some(v) => [("Value", show(v))]
        None => [("Value", "no key \{show(key)}")]
      }
    },
    loc~,
  )
}

///|
/// Assert a Map contains every entry of `expected`. Other entries are
/// allowed.
#callsite(autofill(loc))
pub fn[K : Hash + Eq + @debug.Debug, V : Eq + @debug.Debug] Expectation::to_contain_entries(
  self : Expectation[Map[K, V]],
  expected : Map[K, V],
  loc~ : SourceLoc,
) -> Unit raise Error {
  let missing : Map[K, V] = Map([])
  let changed = []
  for key, value in expected {
    match self.actual.get(key) {
      None => missing[key] = value
      Some(actual_value) if actual_value != value =>
        changed.push(
          "\{show(key)}: expected \{show(value)}, received \{show(actual_value)}",
        )
      Some(_) => ()
    }
  }
  self.assert_that(
    missing.is_empty() && changed.is_empty(),
    "to_contain_entries",
    args="expected",
    expected=() => "containing \{show(expected)}",
    received=() => show(self.actual),
    details=() => {
      let details = []
      if !self.negated && !missing.is_empty() {
        details.push(("Missing", show(missing)))
      }
      if !self.negated && !changed.is_empty() {
        details.push(("Changed", changed.join("\n")))
      }
      details
    },
    loc~,
  )
}
