// Line diffs for failure messages
//
// `Debug` output is compact: `{ x: 1, y: 2 }`. A line diff of compact text
// shows only that the whole line changed. So we first pretty-print the text
// with one field or element per line, as Rust's `{:#?}` does:
//
//   {
//     x: 1,
//     y: 2,
//   }
//
// Then we diff the lines with `@diff` and render git-style hunks.

///|
/// `Debug` text, parsed into plain text and bracket groups.
priv enum Doc {
  Text(String)
  /// An opening bracket, the items between top-level commas, and the
  /// closing bracket.
  Group(Char, Array[Array[Doc]], Char)
}

///|
fn closing_bracket(c : Char) -> Char? {
  match c {
    '(' => Some(')')
    '[' => Some(']')
    '{' => Some('}')
    _ => None
  }
}

///|
/// Parse `chars` from `start` up to `close`, or to the end when `close` is
/// `None`. Return the items and the position after `close`.
fn parse_items(
  chars : Array[Char],
  start : Int,
  close : Char?,
) -> (Array[Array[Doc]], Int) {
  let items : Array[Array[Doc]] = [[]]
  let text = StringBuilder()
  let flush = () => {
    let content = text.to_string()
    if !content.is_empty() {
      items[items.length() - 1].push(Text(content))
      text.reset()
    }
  }
  let mut pos = start
  while pos < chars.length() {
    let c = chars[pos]
    if c == '"' || c == '\'' {
      // Copy a string or char literal as it is, with its escapes.
      text.write_char(c)
      pos += 1
      while pos < chars.length() {
        let d = chars[pos]
        text.write_char(d)
        pos += 1
        if d == '\\' && pos < chars.length() {
          text.write_char(chars[pos])
          pos += 1
        } else if d == c {
          break
        }
      }
    } else if closing_bracket(c) is Some(end) {
      flush()
      let (inner, next) = parse_items(chars, pos + 1, Some(end))
      items[items.length() - 1].push(Group(c, inner, end))
      pos = next
    } else if close is Some(end) && c == end {
      flush()
      return (clean_items(items), pos + 1)
    } else if c == ',' {
      flush()
      items.push([])
      pos += 1
    } else {
      text.write_char(c)
      pos += 1
    }
  }
  flush()
  (clean_items(items), pos)
}

///|
/// Remove the layout whitespace of the original text, and the empty item
/// that a trailing comma leaves.
fn clean_items(items : Array[Array[Doc]]) -> Array[Array[Doc]] {
  let cleaned = []
  for item in items {
    let docs = []
    for i, doc in item {
      match doc {
        Text(content) => {
          let mut view = content[:]
          if i == 0 {
            view = view.trim_start(chars=" \n")
          }
          if i == item.length() - 1 {
            view = view.trim_end(chars=" \n")
          }
          if !view.is_empty() {
            docs.push(Text(view.to_owned()))
          }
        }
        group => docs.push(group)
      }
    }
    cleaned.push(docs)
  }
  while cleaned.last() is Some(last) && last.is_empty() {
    cleaned.pop() |> ignore
  }
  cleaned
}

///|
/// A group spans more than one line when it is a non-empty array or record,
/// holds more than one item, or holds a group that spans more than one line.
/// So `["dev"]` and `["admin", "dev"]` have the same layout and diff line by
/// line, but `Some(42)` stays on one line.
fn expands(open : Char, items : Array[Array[Doc]]) -> Bool {
  (open != '(' && !items.is_empty()) ||
  items.length() > 1 ||
  items
  .iter()
  .any(item => {
    item
    .iter()
    .any(doc => doc is Group(inner_open, inner, _) && expands(inner_open, inner))
  })
}

///|
fn write_docs(builder : StringBuilder, docs : Array[Doc], indent : Int) -> Unit {
  for doc in docs {
    match doc {
      Text(content) => builder.write_string(content)
      Group(open, items, close) if !expands(open, items) => {
        // One item or none: keep it on one line, as `Debug` does.
        builder.write_char(open)
        if items is [item] {
          let pad = if open == '{' { " " } else { "" }
          builder.write_string(pad)
          write_docs(builder, item, indent)
          builder.write_string(pad)
        }
        builder.write_char(close)
      }
      Group(open, items, close) => {
        builder.write_char(open)
        for item in items {
          builder.write_string("\n")
          builder.write_string("  ".repeat(indent + 1))
          write_docs(builder, item, indent + 1)
          builder.write_string(",")
        }
        builder.write_string("\n")
        builder.write_string("  ".repeat(indent))
        builder.write_char(close)
      }
    }
  }
}

///|
/// Pretty-print `Debug` text with one field or element per line.
///
/// A string literal that holds newlines is split at each `\n` escape, so
/// that multi-line strings diff line by line.
fn pretty(text : String) -> Array[String] {
  if split_string_literal(text) is Some(lines) {
    return lines
  }
  let (items, _) = parse_items(text.to_array(), 0, None)
  let builder = StringBuilder()
  for i, item in items {
    if i > 0 {
      builder.write_string(", ")
    }
    write_docs(builder, item, 0)
  }
  builder.to_string().split("\n").map(line => line.to_owned()).collect()
}

///|
/// If `text` is one string literal that holds `\n` escapes, split it after
/// each `\n`. Otherwise return `None`.
fn split_string_literal(text : String) -> Array[String]? {
  let chars = text.to_array()
  let last = chars.length() - 1
  if last < 1 || chars[0] != '"' || chars[last] != '"' {
    return None
  }
  let lines = []
  let line = StringBuilder()
  let mut i = 0
  while i <= last {
    let c = chars[i]
    if c == '\\' && i < last {
      line.write_char(c)
      line.write_char(chars[i + 1])
      if chars[i + 1] == 'n' {
        lines.push(line.to_string())
        line.reset()
      }
      i += 2
    } else if c == '"' && i > 0 && i < last {
      // An unescaped quote ends the literal early: this is not one string.
      return None
    } else {
      line.write_char(c)
      i += 1
    }
  }
  lines.push(line.to_string())
  if lines.length() > 1 {
    Some(lines)
  } else {
    None
  }
}

///|
/// A git-style diff from `expected` to `actual`, both `Debug` text. Return
/// `None` when both values fit on one line: the `Expected` and `Received`
/// lines already show the change.
fn line_diff(expected : String, actual : String) -> String? {
  let old = pretty(expected)
  let new = pretty(actual)
  if old.length() <= 1 && new.length() <= 1 {
    return None
  }
  let builder = StringBuilder()
  for hunk in @diff.Diff(old=old[:], new=new[:]).group() {
    builder.write_string(hunk.render(show=line => line))
  }
  Some(builder.to_string().trim_end(chars="\n").to_owned())
}

// Map differences
//
// Maps compare equal in any order, so a line diff of two maps can show
// changes that are only a different order. For maps, `to_equal` lists the
// missing, extra and changed keys instead.

///|
/// Write `doc` on one line, as `Debug` does.
fn write_compact(builder : StringBuilder, doc : Doc) -> Unit {
  match doc {
    Text(content) => builder.write_string(content)
    Group(open, items, close) => {
      builder.write_char(open)
      let pad = if open == '{' && !items.is_empty() { " " } else { "" }
      builder.write_string(pad)
      for i, item in items {
        if i > 0 {
          builder.write_string(", ")
        }
        for part in item {
          write_compact(builder, part)
        }
      }
      builder.write_string(pad)
      builder.write_char(close)
    }
  }
}

///|
/// Split `key: value` at the first `:` outside a string or char literal.
fn split_key(text : String) -> (String, String)? {
  let chars = text.to_array()
  let mut i = 0
  while i < chars.length() {
    let c = chars[i]
    if c == '"' || c == '\'' {
      i += 1
      while i < chars.length() && chars[i] != c {
        i += if chars[i] == '\\' { 2 } else { 1 }
      }
      i += 1
    } else if c == ':' {
      let key = String::from_array(chars[:i])
      let value = String::from_array(chars[i + 1:])
      return Some((key, value.trim_start(chars=" ").to_owned()))
    } else {
      i += 1
    }
  }
  None
}

///|
/// A record field name, such as `x` or `user_id`. Map keys in `Debug` text
/// are quoted, numbers or constructors, so they are never field names.
fn is_field_name(key : String) -> Bool {
  let chars = key.to_array()
  guard chars is [first, ..] && (first == '_' || (first >= 'a' && first <= 'z')) else {
    return false
  }
  chars
  .iter()
  .all(c => c == '_' || c.is_ascii_alphabetic() || c.is_ascii_digit())
}

///|
/// The entries of `{ key: value, ... }` text as key and value text, and
/// whether a key shows that the text is a map, not a record. Return `None`
/// for other text.
fn map_entries(text : String) -> (Array[(String, String)], Bool)? {
  let (items, _) = parse_items(text.to_array(), 0, None)
  guard items is [[Group('{', entries, '}')]] else { return None }
  let result = []
  let mut is_map = false
  for entry in entries {
    guard entry is [Text(first), .. rest] else { return None }
    guard split_key(first) is Some((key, value_start)) else { return None }
    if !is_field_name(key) {
      is_map = true
    }
    let value = StringBuilder()
    value.write_string(value_start)
    for doc in rest {
      write_compact(value, doc)
    }
    result.push((key, value.to_string()))
  }
  Some((result, is_map))
}

///|
/// The missing, extra and changed keys from `expected` to `actual`, both
/// `Debug` text of maps. Return `None` when the text is not two maps.
fn map_diff(expected : String, actual : String) -> Array[(String, String)]? {
  guard map_entries(expected) is Some((expected_entries, expected_is_map)) &&
    map_entries(actual) is Some((actual_entries, actual_is_map)) &&
    (expected_is_map || actual_is_map) else {
    return None
  }
  let find = (entries : Array[(String, String)], key : String) => {
    entries.search_by(entry => entry.0 == key).map(i => entries[i].1)
  }
  let as_map = (entries : Array[(String, String)]) => {
    "{ " + entries.map(entry => "\{entry.0}: \{entry.1}").join(", ") + " }"
  }
  let missing = expected_entries.filter(entry => {
    find(actual_entries, entry.0) is None
  })
  let extra = actual_entries.filter(entry => {
    find(expected_entries, entry.0) is None
  })
  let changed = []
  for entry in expected_entries {
    if find(actual_entries, entry.0) is Some(value) && value != entry.1 {
      changed.push("\{entry.0}: expected \{entry.1}, received \{value}")
    }
  }
  let details = []
  if !missing.is_empty() {
    details.push(("Missing", as_map(missing)))
  }
  if !extra.is_empty() {
    details.push(("Extra", as_map(extra)))
  }
  if !changed.is_empty() {
    details.push(("Changed", changed.join("\n")))
  }
  if details.is_empty() {
    None
  } else {
    Some(details)
  }
}
