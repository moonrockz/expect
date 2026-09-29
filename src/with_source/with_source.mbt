// Show the source text of the value under test
//
// `expect` from this package works like `@expect.expect`, but a failure
// shows the expression you wrote instead of `received`:
//
//   expect(user.age + 1).to_equal(expected)
//
// MoonBit has no macros, so the text comes from the source file: the
// compiler gives the location of the argument, and this package reads the
// file when an assertion fails. It depends on `moonbitlang/x/fs`, so it is
// separate from `moonrockz/expect`: import it only when you want it.
//
// When the file cannot be read, for example because the tests run from
// another directory, the headline shows `received` as before.

///|
/// The lines of each source file read so far. `None` when the file cannot
/// be read.
let files : Map[String, Array[String]?] = Map([])

///|
/// The lines of the file at `path`, relative to the module root.
fn file_lines(path : String) -> Array[String]? {
  if files.get(path) is Some(lines) {
    return lines
  }
  let lines = try @fs.read_file_to_string(path) catch {
    _ => None
  } noraise {
    text => Some(text.split("\n").map(line => line.to_owned()).collect())
  }
  files[path] = lines
  lines
}

///|
/// Parse `path:line:column-line:column@package`. Columns start at 1, and the
/// end column is exclusive.
fn parse_location(text : String) -> (String, Int, Int, Int, Int)? {
  let without_package = match text.rev_find("@") {
    Some(index) => text.view(end_offset=index).to_owned()
    None => text
  }
  let parts = without_package.split(":").map(part => part.to_owned()).collect()
  guard parts.length() >= 4 else { return None }
  let n = parts.length()
  let middle = parts[n - 2].split("-").map(part => part.to_owned()).collect()
  guard middle is [start_column, end_line] else { return None }
  let number = (text : String) => @string.parse_int(text) catch { _ => -1 }
  let path = parts[:n - 3].iter().join(":")
  let start_line = number(parts[n - 3])
  let start = number(start_column)
  let last_line = number(end_line)
  let end = number(parts[n - 1])
  guard start_line > 0 && start > 0 && last_line >= start_line && end > 0 else {
    return None
  }
  Some((path, start_line, start, last_line, end))
}

///|
/// The source text at a location, on one line. Return `""` when it cannot
/// be read.
fn source_text(location : String) -> String {
  guard parse_location(location)
    is Some((path, start_line, start, last_line, end)) &&
    file_lines(path) is Some(lines) &&
    last_line <= lines.length() else {
    return ""
  }
  let parts = []
  for line_number in start_line..<=last_line {
    let chars = lines[line_number - 1].to_array()
    let from = if line_number == start_line { start - 1 } else { 0 }
    let to = if line_number == last_line { end - 1 } else { chars.length() }
    guard from >= 0 && from <= to && to <= chars.length() else { return "" }
    parts.push(
      String::from_array(chars[from:to]).trim(chars=" \t\r").to_owned(),
    )
  }
  parts.filter(part => !part.is_empty()).join(" ")
}

///|
/// The source text of the first argument of a call, read lazily.
fn first_argument(args_loc : ArgsLoc) -> () -> String {
  let ArgsLoc(locations) = args_loc
  match locations.get(0) {
    Some(Some(location)) => {
      let text = location.to_string()
      () => source_text(text)
    }
    _ => () => ""
  }
}

///|
/// Create an expectation on a value, like `@expect.expect`. A failure shows
/// the expression you wrote: `expect(user.age).to_equal(expected)`.
#callsite(autofill(args_loc))
pub fn[T] expect(
  actual : T,
  label? : String = "",
  args_loc~ : ArgsLoc,
) -> @expect.Expectation[T] {
  @expect.expect(actual, label~, source=first_argument(args_loc))
}

///|
/// Create an expectation on a function, like `@expect.expect_call`. A
/// failure shows the function you wrote.
#callsite(autofill(args_loc))
pub fn[T] expect_call(
  f : () -> T raise Error,
  label? : String = "",
  args_loc~ : ArgsLoc,
) -> @expect.Expectation[() -> T raise Error] {
  @expect.expect_call(f, label~, source=first_argument(args_loc))
}
