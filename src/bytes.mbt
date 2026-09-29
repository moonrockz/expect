// Bytes in failure messages
//
// `Debug` shows `Bytes` as `<Bytes: [0x68, 0x65, ...]>`. Failure messages
// show a hex dump instead, as `hexdump -C` does, with 16 bytes per line.

///|
/// The value of a hex digit.
fn hex_digit(c : Char) -> Int? {
  match c {
    '0'..='9' => Some(c.to_int() - '0'.to_int())
    'a'..='f' => Some(c.to_int() - 'a'.to_int() + 10)
    'A'..='F' => Some(c.to_int() - 'A'.to_int() + 10)
    _ => None
  }
}

///|
/// The bytes in `Debug` text of `Bytes` or `BytesView`. Return `None` for
/// other text.
fn bytes_values(text : String) -> Array[Int]? {
  // Long values break over several lines.
  let text = if text.contains("\n") {
    String::from_iter(text.iter().filter(c => c != '\n' && c != ' ')).replace_all(
      old=":[",
      new=": [",
    )
  } else {
    text
  }
  let prefix = if text.has_prefix("<Bytes: [") {
    "<Bytes: ["
  } else if text.has_prefix("<BytesView: [") {
    "<BytesView: ["
  } else {
    return None
  }
  guard text.has_suffix("]>") else { return None }
  let body = text.view(
    start_offset=prefix.length(),
    end_offset=text.length() - 2,
  )
  if body.is_empty() {
    return Some([])
  }
  let values = []
  for part in body.split(",") {
    let part = part.trim_start(chars=" ")
    if part.is_empty() {
      continue
    }
    guard part is [.. "0x", high, low] &&
      hex_digit(high) is Some(h) &&
      hex_digit(low) is Some(l) else {
      return None
    }
    values.push(h * 16 + l)
  }
  Some(values)
}

///|
/// A byte as two lower-case hex digits.
fn hex_byte(value : Int) -> String {
  let digits = "0123456789abcdef"
  "\{digits[value / 16:value / 16 + 1]}\{digits[value % 16:value % 16 + 1]}"
}

///|
/// An offset as at least two lower-case hex digits.
fn hex_offset(offset : Int) -> String {
  let text = offset.to_string(radix=16)
  if text.length() < 2 {
    "0" + text
  } else {
    text
  }
}

///|
/// A hex dump of `bytes`, 16 bytes per line, with offsets and ASCII text.
fn hex_dump(bytes : Array[Int]) -> String {
  let lines = []
  for start = 0; start < bytes.length(); start = start + 16 {
    let line = StringBuilder()
    let offset = start.to_string(radix=16)
    line.write_string("0".repeat(8 - offset.length()) + offset)
    line.write_string("  ")
    let text = StringBuilder()
    for i in 0..<16 {
      match bytes.get(start + i) {
        Some(value) => {
          line.write_string(hex_byte(value) + " ")
          text.write_char(
            if value >= 0x20 && value < 0x7f {
              Int::unsafe_to_char(value)
            } else {
              '.'
            },
          )
        }
        None => line.write_string("   ")
      }
      if i == 7 {
        line.write_string(" ")
      }
    }
    line.write_string(" |\{text}|")
    lines.push(line.to_string())
  }
  lines.join("\n")
}

///|
/// The first differing offset of two `Bytes` values in `Debug` text. Return
/// `None` when the text is not two `Bytes` values, or when they are the
/// same.
fn bytes_mismatch(expected : String, actual : String) -> String? {
  guard bytes_values(expected) is Some(expected_bytes) &&
    bytes_values(actual) is Some(actual_bytes) else {
    return None
  }
  let longest = if expected_bytes.length() > actual_bytes.length() {
    expected_bytes.length()
  } else {
    actual_bytes.length()
  }
  for i in 0..<longest {
    let want = expected_bytes.get(i)
    let got = actual_bytes.get(i)
    if want != got {
      let describe = (value : Int?) => {
        match value {
          Some(v) => "0x\{hex_byte(v)}"
          None => "nothing"
        }
      }
      return Some(
        "offset \{i} (0x\{hex_offset(i)}): expected \{describe(want)}, received \{describe(got)}",
      )
    }
  }
  None
}
