// Color
//
// Failure messages will be in color by default. Color is turned off until
// `moon test` can report it (see `color_supported`). Matchers build plain
// text, and
// color is added only when a failure message is rendered. Code that reads
// failure messages strips the color first.
//
// - `NO_COLOR` (set and not empty) or `TERM=dumb` turns color off.
// - `EXPECT_COLOR=0` or `EXPECT_COLOR=1` forces color off or on, and wins
//   over the other variables.

///|
/// Whether `moon test` can report failure messages with color. Its test
/// driver writes control characters as `\u{1b}`, which is not valid JSON, so
/// a colored failure stops the whole test run (moonbitlang/moon#2257). Set
/// this to `true` when that is fixed.
let color_supported = false

///|
/// Whether failure messages are in color.
fn color_enabled() -> Bool {
  color_supported && color_from_env()
}

///|
/// Whether the environment asks for color.
fn color_from_env() -> Bool {
  match @env.get_env_var("EXPECT_COLOR") {
    Some("0") => return false
    Some("1") => return true
    _ => ()
  }
  if @env.get_env_var("NO_COLOR") is Some(value) && !value.is_empty() {
    return false
  }
  if @env.get_env_var("TERM") is Some("dumb") {
    return false
  }
  true
}

///|
priv enum Style {
  Bold
  Red
  Green
  Yellow
  Cyan
}

///|
/// `text` in `style` when `color` is on.
fn paint(text : String, style : Style, color : Bool) -> String {
  if !color || text.is_empty() {
    return text
  }
  let code = match style {
    Bold => "1"
    Red => "31"
    Green => "32"
    Yellow => "33"
    Cyan => "36"
  }
  "\u{1b}[\{code}m\{text}\u{1b}[0m"
}

///|
/// A line of a diff in color: removed lines in red, added lines in green,
/// change marks in yellow and hunk headers in cyan.
fn paint_diff_line(line : String, color : Bool) -> String {
  match line.get_char(0) {
    Some('-') => paint(line, Red, color)
    Some('+') => paint(line, Green, color)
    Some('?') => paint(line, Yellow, color)
    Some('@') => paint(line, Cyan, color)
    _ => line
  }
}

///|
/// `text` without ANSI escape sequences.
fn strip_ansi(text : String) -> String {
  if !text.contains("\u{1b}[") {
    return text
  }
  let builder = StringBuilder()
  let chars = text.to_array()
  let mut i = 0
  while i < chars.length() {
    if chars[i] == '\u{1b}' && i + 1 < chars.length() && chars[i + 1] == '[' {
      i += 2
      // Skip the parameters and the final letter.
      while i < chars.length() && !chars[i].is_ascii_alphabetic() {
        i += 1
      }
      i += 1
    } else {
      builder.write_char(chars[i])
      i += 1
    }
  }
  builder.to_string()
}
