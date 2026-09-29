// Matchers for `Json`.

///|
/// One step of a path into a Json value.
priv enum PathStep {
  Key(String)
  Index(Int)
}

///|
/// Parse a path such as `items[0].name`. Keys are separated by `.`, and
/// array indices are in brackets.
fn parse_path(path : String) -> Array[PathStep]? {
  let steps = []
  let key = StringBuilder()
  let chars = path.to_array()
  let flush = () => {
    let text = key.to_string()
    key.reset()
    text
  }
  let mut i = 0
  while i < chars.length() {
    match chars[i] {
      '.' => {
        let text = flush()
        // A dot must follow a key or an index.
        if text.is_empty() && !(steps.last() is Some(Index(_))) {
          return None
        }
        if !text.is_empty() {
          steps.push(Key(text))
        }
        i += 1
      }
      '[' => {
        let text = flush()
        if !text.is_empty() {
          steps.push(Key(text))
        }
        let digits = StringBuilder()
        i += 1
        while i < chars.length() && chars[i] != ']' {
          guard chars[i].is_ascii_digit() else { return None }
          digits.write_char(chars[i])
          i += 1
        }
        guard i < chars.length() && !digits.to_string().is_empty() else {
          return None
        }
        steps.push(
          Index(
            @string.parse_int(digits.to_string()) catch {
              _ => return None
            },
          ),
        )
        i += 1
      }
      c => {
        key.write_char(c)
        i += 1
      }
    }
  }
  let text = flush()
  if !text.is_empty() {
    steps.push(Key(text))
  } else if steps.is_empty() || path.has_suffix(".") {
    return None
  }
  Some(steps)
}

///|
/// The path of the first `count` steps, such as `items[0]`.
fn path_text(steps : Array[PathStep], count : Int) -> String {
  let builder = StringBuilder()
  for i, step in steps[:count] {
    match step {
      Key(key) => {
        if i > 0 {
          builder.write_char('.')
        }
        builder.write_string(key)
      }
      Index(index) => builder.write_string("[\{index}]")
    }
  }
  builder.to_string()
}

///|
/// The kind of a Json value, with an article: `an array`.
fn json_kind(value : Json) -> String {
  match value {
    Null => "null"
    True | False => "a boolean"
    Number(_, ..) => "a number"
    String(_) => "a string"
    Array(_) => "an array"
    Object(_) => "an object"
  }
}

///|
/// Return an expectation on the value at `path`, such as `items[0].name`.
/// Keys are separated by `.`, and array indices are in brackets. Fails when
/// the path does not exist. Cannot be used after `not()`.
#callsite(autofill(loc))
pub fn Expectation::at(
  self : Expectation[Json],
  path : String,
  loc~ : SourceLoc,
) -> Expectation[Json] raise Error {
  self.check_not_negated("at", loc)
  guard parse_path(path) is Some(steps) else {
    self.report("at", "path", [("Error", "invalid path \{show(path)}")], loc)
  }
  let mut current = self
  for i, step in steps {
    let here = if i == 0 { "the value" } else { path_text(steps, i) }
    let found = match (step, current.actual) {
      (Key(key), Object(map)) =>
        match map.get(key) {
          Some(value) => Ok(current.navigate(value, key))
          None => Err("\{here} has no key \{show(key)}")
        }
      (Index(index), Array(items)) =>
        match items.get(index) {
          Some(value) => Ok(current.navigate(value, "[\{index}]"))
          None => Err("\{here} is an array of length \{items.length()}")
        }
      (Key(_), value) => Err("\{here} is \{json_kind(value)}, not an object")
      (Index(_), value) => Err("\{here} is \{json_kind(value)}, not an array")
    }
    match found {
      Ok(next) => current = next
      Err(message) =>
        self.report(
          "at",
          "path",
          [
            ("Expected", "a value at \{show(path)}"),
            ("Received", self.actual.stringify()),
            ("Found", message),
          ],
          loc,
        )
    }
  }
  current
}

///|
/// Compare `actual` with `expected` as a subset. Add the missing paths and
/// the differences to the arrays.
fn json_subset(
  actual : Json,
  expected : Json,
  path : String,
  missing : Array[String],
  different : Array[String],
) -> Unit {
  let name = if path.is_empty() { "the value" } else { path }
  let child = (key : String) => {
    if path.is_empty() {
      key
    } else {
      "\{path}.\{key}"
    }
  }
  match (actual, expected) {
    (Object(actual_map), Object(expected_map)) =>
      for key, value in expected_map {
        match actual_map.get(key) {
          Some(actual_value) =>
            json_subset(actual_value, value, child(key), missing, different)
          None => missing.push(child(key))
        }
      }
    (Array(actual_items), Array(expected_items)) =>
      if actual_items.length() != expected_items.length() {
        different.push(
          "\{name}: expected an array of length \{expected_items.length()}, received length \{actual_items.length()}",
        )
      } else {
        for i, value in expected_items {
          json_subset(
            actual_items[i],
            value,
            "\{path}[\{i}]",
            missing,
            different,
          )
        }
      }
    (Number(a, ..), Number(b, ..)) =>
      if a != b {
        different.push(
          "\{name}: expected \{expected.stringify()}, received \{actual.stringify()}",
        )
      }
    _ =>
      if actual != expected {
        different.push(
          "\{name}: expected \{expected.stringify()}, received \{actual.stringify()}",
        )
      }
  }
}

///|
/// Assert a Json value contains `expected`: every key of an object in
/// `expected` must exist with a value that contains the expected value, at
/// every depth. Other keys are allowed. Arrays must have the same length,
/// and each element must contain the expected element. Numbers compare by
/// value.
#callsite(autofill(loc))
pub fn Expectation::to_contain_json(
  self : Expectation[Json],
  expected : Json,
  loc~ : SourceLoc,
) -> Unit raise Error {
  let missing = []
  let different = []
  json_subset(self.actual, expected, "", missing, different)
  self.assert_that(
    missing.is_empty() && different.is_empty(),
    "to_contain_json",
    args="expected",
    expected=() => "containing \{expected.stringify()}",
    received=() => self.actual.stringify(),
    details=() => {
      let details = []
      if !self.negated && !missing.is_empty() {
        details.push(("Missing", missing.join("\n")))
      }
      if !self.negated && !different.is_empty() {
        details.push(("Different", different.join("\n")))
      }
      details
    },
    loc~,
  )
}
