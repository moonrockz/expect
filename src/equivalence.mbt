// Structural equivalence
//
// `to_be_equivalent_to` compares two values field by field. MoonBit has no
// reflection, and `@debug.Repr` cannot be inspected outside core, so the
// values are compared through their `Debug` text: the text is parsed into a
// tree of records, maps, sequences, constructors and leaves.
//
// When core can inspect `Repr` (moonbitlang/core#4334), build the tree from
// `Repr` instead. The public API does not change.

///|
/// A value, parsed from `Debug` text.
priv enum Node {
  /// A number, string, char, bool, or other text that has no parts.
  Leaf(String)
  /// A record: `{ x: 1 }`. The fields keep their order.
  Record(Array[(String, Node)])
  /// A map: `{ "a": 1 }`. Keys are `Debug` text.
  MapNode(Array[(String, Node)])
  /// An array or a tuple, with its opening bracket.
  Seq(Char, Array[Node])
  /// A constructor with arguments: `Some(1)`, `Circle(radius=1)`. Labeled
  /// arguments have a label.
  Ctor(String, Array[(String?, Node)])
}

///|
/// The `Debug` text of a node on one line.
fn Node::text(self : Node) -> String {
  let entries = (entries : Array[(String, Node)]) => {
    if entries.is_empty() {
      "{}"
    } else {
      "{ " + entries.map(e => "\{e.0}: \{e.1.text()}").join(", ") + " }"
    }
  }
  match self {
    Leaf(text) => text
    Record(fields) => entries(fields)
    MapNode(pairs) => entries(pairs)
    Seq(open, items) => {
      let close = if open == '[' { "]" } else { ")" }
      open.to_string() + items.map(item => item.text()).join(", ") + close
    }
    Ctor(name, args) => {
      let shown = args.map(arg => {
        match arg {
          (Some(label), node) => "\{label}=\{node.text()}"
          (None, node) => node.text()
        }
      })
      "\{name}(\{shown.join(", ")})"
    }
  }
}

///|
/// Split `label=value` at the first `=` outside a literal. Return `None`
/// when the text has no label.
fn split_label(text : String) -> (String, String)? {
  guard text.find("=") is Some(index) else { return None }
  let label = text.view(end_offset=index).to_owned()
  guard is_field_name(label) else { return None }
  Some((label, text.view(start_offset=index + 1).to_owned()))
}

///|
/// Build a node from one parsed item.
fn node_of(item : Array[Doc]) -> Node {
  match item {
    [Group('{', entries, '}')] => {
      let pairs = []
      let mut is_map = false
      for entry in entries {
        guard entry is [Text(first), .. rest] &&
          split_key(first) is Some((key, value_start)) else {
          return Leaf(compact_item(item))
        }
        if !is_field_name(key) {
          is_map = true
        }
        let value_docs : Array[Doc] = if value_start.is_empty() {
          [..rest]
        } else {
          [Text(value_start), ..rest]
        }
        pairs.push((key, node_of(value_docs)))
      }
      if is_map {
        MapNode(pairs)
      } else {
        Record(pairs)
      }
    }
    [Group('[', items, ']')] => Seq('[', items.map(node_of))
    [Group('(', items, ')')] => Seq('(', items.map(node_of))
    [Text(name), Group('(', args, ')')] if !name.has_prefix("<") => {
      let parsed = args.map(arg => {
        match arg {
          [Text(first), .. rest] if split_label(first) is Some((label, value)) => {
            let value_docs : Array[Doc] = if value.is_empty() {
              [..rest]
            } else {
              [Text(value), ..rest]
            }
            (Some(label), node_of(value_docs))
          }
          _ => (None, node_of(arg))
        }
      })
      Ctor(name, parsed)
    }
    _ => Leaf(compact_item(item))
  }
}

///|
/// The parts of an item on one line.
fn compact_item(item : Array[Doc]) -> String {
  let builder = StringBuilder()
  for doc in item {
    write_compact(builder, doc)
  }
  builder.to_string()
}

///|
/// Parse `Debug` text into a node.
fn parse_node(text : String) -> Node {
  let (items, _) = parse_items(text.to_array(), 0, None)
  match items {
    [item] => node_of(item)
    _ => Leaf(text)
  }
}

///|
/// The options of an equivalence check.
priv struct Equivalence {
  excluding : Array[String]
  ignoring_order : Bool
  tolerance : Double?
}

///|
/// Whether `path` matches `pattern`. `[*]` in the pattern matches any index.
fn path_matches(pattern : String, path : String) -> Bool {
  if !pattern.contains("[*]") {
    return pattern == path
  }
  let p = pattern.to_array()
  let s = path.to_array()
  let mut i = 0
  let mut j = 0
  while i < p.length() {
    if i + 2 < p.length() && p[i] == '[' && p[i + 1] == '*' && p[i + 2] == ']' {
      guard j < s.length() && s[j] == '[' else { return false }
      while j < s.length() && s[j] != ']' {
        j += 1
      }
      guard j < s.length() else { return false }
      i += 3
      j += 1
    } else {
      guard j < s.length() && p[i] == s[j] else { return false }
      i += 1
      j += 1
    }
  }
  j == s.length()
}

///|
/// The path of a field: `a.b`, or `b` at the root.
fn child_path(path : String, name : String) -> String {
  if path.is_empty() {
    name
  } else {
    "\{path}.\{name}"
  }
}

///|
/// Compare `actual` with `expected` at `path`. Add each difference to
/// `differences`, as `path: text`.
fn Equivalence::compare(
  self : Equivalence,
  expected : Node,
  actual : Node,
  path : String,
  differences : Array[String],
) -> Unit {
  if self.excluding.iter().any(pattern => path_matches(pattern, path)) {
    return
  }
  let name = if path.is_empty() { "value" } else { path }
  let differ = () => {
    differences.push(
      "\{name}: expected \{expected.text()}, received \{actual.text()}",
    )
  }
  match (expected, actual) {
    (Leaf(a), Leaf(b)) => if a != b && !self.close_numbers(a, b) { differ() }
    (Record(a), Record(b)) =>
      self.compare_entries(a, b, key => child_path(path, key), differences)
    (MapNode(a), MapNode(b)) =>
      self.compare_entries(a, b, key => "\{path}[\{key}]", differences)
    (Seq(open_a, a), Seq(open_b, b)) if open_a == open_b =>
      if self.ignoring_order && open_a == '[' {
        self.compare_unordered(a, b, name, differences)
      } else if a.length() != b.length() {
        differences.push(
          "\{name}: expected length \{a.length()}, received length \{b.length()}",
        )
      } else {
        for i in 0..<a.length() {
          let item_path = if open_a == '[' {
            "\{path}[\{i}]"
          } else {
            child_path(path, i.to_string())
          }
          self.compare(a[i], b[i], item_path, differences)
        }
      }
    (Ctor(name_a, a), Ctor(name_b, b)) if name_a == name_b &&
      a.length() == b.length() =>
      for i in 0..<a.length() {
        // A single argument, as in `Some(x)`, keeps the path of the value.
        let arg_path = match a[i].0 {
          Some(label) => child_path(path, label)
          None if a.length() == 1 => path
          None => child_path(path, i.to_string())
        }
        self.compare(a[i].1, b[i].1, arg_path, differences)
      }
    _ => differ()
  }
}

///|
/// Whether `a` and `b` are numbers within the tolerance.
fn Equivalence::close_numbers(
  self : Equivalence,
  a : String,
  b : String,
) -> Bool {
  guard self.tolerance is Some(tolerance) else { return false }
  let x = @string.parse_double(a) catch { _ => return false }
  let y = @string.parse_double(b) catch { _ => return false }
  (x - y).abs() <= tolerance
}

///|
/// Compare the fields of two records or the entries of two maps.
fn Equivalence::compare_entries(
  self : Equivalence,
  expected : Array[(String, Node)],
  actual : Array[(String, Node)],
  path_of : (String) -> String,
  differences : Array[String],
) -> Unit {
  let find = (entries : Array[(String, Node)], key : String) => {
    entries.search_by(e => e.0 == key).map(i => entries[i].1)
  }
  for entry in expected {
    let path = path_of(entry.0)
    if self.excluding.iter().any(pattern => path_matches(pattern, path)) {
      continue
    }
    match find(actual, entry.0) {
      Some(value) => self.compare(entry.1, value, path, differences)
      None => differences.push("\{path}: missing")
    }
  }
  for entry in actual {
    let path = path_of(entry.0)
    if find(expected, entry.0) is None &&
      !self.excluding.iter().any(pattern => path_matches(pattern, path)) {
      differences.push("\{path}: unexpected, \{entry.1.text()}")
    }
  }
}

///|
/// Compare two arrays as multisets: pair each expected element with an
/// equivalent actual element that is not paired yet.
fn Equivalence::compare_unordered(
  self : Equivalence,
  expected : Array[Node],
  actual : Array[Node],
  name : String,
  differences : Array[String],
) -> Unit {
  let used = FixedArray::make(actual.length(), false)
  let missing = []
  for item in expected {
    let mut found = false
    for i, candidate in actual {
      if !used[i] {
        let inner = []
        self.compare(item, candidate, "", inner)
        if inner.is_empty() {
          used[i] = true
          found = true
          break
        }
      }
    }
    if !found {
      missing.push(item)
    }
  }
  for item in missing {
    differences.push("\{name}: missing element \{item.text()}")
  }
  for i, item in actual {
    if !used[i] {
      differences.push("\{name}: unexpected element \{item.text()}")
    }
  }
}

///|
/// Assert the actual value is equivalent to `expected`: the two values are
/// compared field by field, through what their `Debug` output shows. The
/// type does not need `Eq`.
///
/// - `excluding` lists paths to skip, such as `id`, `balance.cents` or
///   `items[*].id`. `[*]` matches any index.
/// - `ignoring_order` compares arrays as multisets, at every depth.
/// - `tolerance` lets numbers differ by up to this amount.
///
/// Fields that `Debug` hides, for example with `Repr::omitted()`, always
/// compare as equivalent. Values that `Debug` shows as text, such as a
/// custom `Repr::literal`, compare as text.
#callsite(autofill(loc))
pub fn[T : @debug.Debug] Expectation::to_be_equivalent_to(
  self : Expectation[T],
  expected : T,
  excluding? : Array[String] = [],
  ignoring_order? : Bool = false,
  tolerance? : Double,
  loc~ : SourceLoc,
) -> Unit raise Error {
  let options = { excluding, ignoring_order, tolerance, }
  let differences = []
  options.compare(
    parse_node(@debug.to_string(expected)),
    parse_node(@debug.to_string(self.actual)),
    "",
    differences,
  )
  self.assert_that(
    differences.is_empty(),
    "to_be_equivalent_to",
    args="expected",
    expected=() => {
      let parts = ["equivalent to \{show(expected)}"]
      if !excluding.is_empty() {
        parts.push("excluding \{excluding.join(", ")}")
      }
      if ignoring_order {
        parts.push("ignoring order")
      }
      if tolerance is Some(t) {
        parts.push("tolerance \{show_double(t)}")
      }
      parts.join(", ")
    },
    received=() => show(self.actual),
    details=() => {
      if self.negated {
        []
      } else {
        [("Differences", differences.join("\n"))]
      }
    },
    loc~,
  )
}
