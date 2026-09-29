///|
async test "eventually passes once the block passes" {
  let mut calls = 0
  @async_expect.eventually(
    () => {
      calls += 1
      @expect.expect(calls).to_be_greater_than_or_equal(3)
    },
    interval=1,
  )
  @expect.expect(calls).to_equal(3)
}

///|
async test "eventually reports the last failure when the time runs out" {
  let mut calls = 0
  let message = try
    @async_expect.eventually(
      () => {
        calls += 1
        @expect.expect(calls).to_equal(0)
      },
      timeout=30,
      interval=5,
    )
  catch {
    Failure(message) => message
    error => "unexpected: \{error}"
  } noraise {
    _ => "passed"
  }
  let lines = message.split("\n").map(line => line.to_owned()).collect()
  @expect.expect(lines[0]).to_contain(
    "FAILED: eventually(block) did not pass within 30 ms (",
  )
  @expect.expect(lines[1]).to_equal("Last failure:")
  @expect.expect(lines[2]).to_start_with(
    "  src/async_expect/eventually_test.mbt:",
  )
  @expect.expect(lines[2]).to_end_with(": expect(received).to_equal(expected)")
  @expect.expect(lines[3]).to_equal("  Expected: 0")
  @expect.expect(lines[4]).to_equal("  Received: \{calls}")
}

///|
async test "eventually stops a block that does not finish" {
  let message = try
    @async_expect.eventually(async fn() { @async.sleep(1000) }, timeout=20)
  catch {
    Failure(message) => message
    error => "unexpected: \{error}"
  } noraise {
    _ => "passed"
  }
  @expect.expect(message).to_contain("(1 attempt)")
  @expect.expect(message).to_end_with(
    "Last failure:\n  none: the first attempt did not finish in time",
  )
}
