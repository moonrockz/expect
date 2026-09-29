///|
/// Run `f` with the color variables set as given, then restore them.
fn with_env(
  vars : Array[(String, String?)],
  f : () -> Unit raise Error,
) -> Unit raise Error {
  let names = ["EXPECT_COLOR", "NO_COLOR", "TERM"]
  let saved = names.map(name => (name, @env.get_env_var(name)))
  let apply = (settings : Array[(String, String?)]) => {
    for setting in settings {
      match setting.1 {
        Some(value) => @env.set_env_var(setting.0, value)
        None => @env.unset_env_var(setting.0)
      }
    }
  }
  apply(names.map(name => (name, None)))
  apply(vars)
  defer apply(saved)
  f()
}

///|
/// The raw failure message of `f`, with color, without the location.
fn raw_failure(f : () -> Unit raise Error) -> String raise Error {
  f() catch {
    Failure(message) => {
      let marker = " FAILED: "
      return match message.find(marker) {
        Some(index) =>
          message.view(start_offset=index + marker.length()).to_owned()
        None => message
      }
    }
    error => fail("expected a Failure, got \{error}")
  }
  fail("expected a failure")
}

///|
test "color is on by default and the environment turns it off" {
  with_env([], () => inspect(color_from_env(), content="true"))
  with_env([("NO_COLOR", Some("1"))], () => {
    inspect(color_from_env(), content="false")
  })
  with_env([("NO_COLOR", Some(""))], () => {
    inspect(color_from_env(), content="true")
  })
  with_env([("TERM", Some("dumb"))], () => {
    inspect(color_from_env(), content="false")
  })
  with_env([("TERM", Some("xterm-256color"))], () => {
    inspect(color_from_env(), content="true")
  })
  with_env([("EXPECT_COLOR", Some("0"))], () => {
    inspect(color_from_env(), content="false")
  })
  with_env([("EXPECT_COLOR", Some("1")), ("NO_COLOR", Some("1"))], () => {
    inspect(color_from_env(), content="true")
  })
}

///|
test "failure messages are painted when color is on" {
  let details = [
    ("Expected", "5"),
    ("Received", "3"),
    (diff_name, "@@ -1,2 +1,2 @@\n-  y: 3,\n+  y: 2,\n?     ^"),
  ]
  inspect(
    render_details(details, color=true).escape(),
    content=(
      #|"Expected: \u{1b}[31m5\u{1b}[0m\nReceived: \u{1b}[32m3\u{1b}[0m\nDiff (- expected, + received):\n  \u{1b}[36m@@ -1,2 +1,2 @@\u{1b}[0m\n  \u{1b}[31m-  y: 3,\u{1b}[0m\n  \u{1b}[32m+  y: 2,\u{1b}[0m\n  \u{1b}[33m?     ^\u{1b}[0m"
    ),
  )
  inspect(render_details(details).contains("\u{1b}"), content="false")
  inspect(
    strip_ansi(render_details(details, color=true)) == render_details(details),
    content="true",
  )
}

///|
test "color is off until moon test can report it" {
  with_env([("EXPECT_COLOR", Some("1"))], () => {
    inspect(color_enabled(), content="false")
    let message = raw_failure(() => expect(3).to_equal(5))
    inspect(message.contains("\u{1b}["), content="false")
  })
}

///|
test "failure_message and expect_failure return plain text" {
  with_env([("EXPECT_COLOR", Some("1"))], () => {
    inspect(
      failure_message(() => expect(3).to_equal(5)),
      content=(
        #|expect(received).to_equal(expected)
        #|Expected: 5
        #|Received: 3
      ),
    )
    expect_failure(() => expect(3).to_equal(5)).to_contain("Received: 3")
    expect_failure(() => {
      expect_all(s => {
        s.expect(1).to_equal(2)
        s.expect(3).to_equal(4)
      })
    }).to_start_with("2 of 2 assertions failed")
  })
  inspect(
    failure(() => failure_message(() => ()) |> ignore),
    content="failure_message: the block did not fail",
  )
  inspect(
    failure(() => expect_failure(() => ()).to_equal("")),
    content="expect_failure: the block did not fail",
  )
}
