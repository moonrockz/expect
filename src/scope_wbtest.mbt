///|
/// The failure message of `f` with the source locations replaced by `<loc>`,
/// because they change when this file changes.
fn scoped_failure(f : () -> Unit raise Error) -> String raise Error {
  let message = failure(f)
  let lines = message.split("\n").map(line => line.to_owned()).collect()
  lines
  .map(line => {
    match (line.find(" src/"), line.find("@moonrockz/expect: ")) {
      (Some(start), Some(end)) =>
        line.view(end_offset=start).to_owned() +
        " <loc>: " +
        line.view(start_offset=end + "@moonrockz/expect: ".length()).to_owned()
      _ => line
    }
  })
  .join("\n")
}

///|
test "expect_all passes when every assertion passes" {
  expect_all(s => {
    s.expect(1).to_equal(1)
    s.expect("Ada").to_start_with("A")
  })
}

///|
test "expect_all reports every failure" {
  inspect(
    scoped_failure(() => {
      expect_all(s => {
        s.expect("Bob", label="name").to_equal("Ada")
        s.expect(17).to_be_greater_than(18)
        s.expect(3).to_equal(3)
        s.expect([1, 2]).not().to_contain_element(2)
      })
    }),
    content=(
      #|3 of 4 assertions failed
      #|
      #|(1) <loc>: name: expect(received).to_equal(expected)
      #|    Expected: "Ada"
      #|    Received: "Bob"
      #|
      #|(2) <loc>: expect(received).to_be_greater_than(expected)
      #|    Expected: > 18
      #|    Received: 17
      #|
      #|(3) <loc>: expect(received).not.to_contain_element(expected)
      #|    Expected: not containing 2
      #|    Received: [1, 2]
    ),
  )
}

///|
test "each failure keeps the location of its matcher" {
  // The combined failure points at `expect_all` in this file.
  let raw = try expect_all(s => s.expect(1).to_equal(2)) catch {
    Failure(message) => message
    _ => ""
  } noraise {
    _ => ""
  }
  inspect(raw.has_prefix("src/scope_wbtest.mbt:"), content="true")
  let message = failure(() => expect_all(s => s.expect(1).to_equal(2)))
  inspect(message.contains("(1) src/scope_wbtest.mbt:"), content="true")
}

///|
test "navigation, all and because keep collecting" {
  inspect(
    scoped_failure(() => {
      expect_all(s => {
        s.expect(Some(1)).unwrap_some().to_equal(2)
        s.expect([1, 2]).first().to_equal(5)
        s
        .expect(4)
        .all(it => {
          it.to_be_less_than(3)
          it.to_be_positive()
        })
        s.expect(7).because("seven is odd").to_satisfy(x => x % 2 == 0)
      })
    }),
    content=(
      #|4 of 5 assertions failed
      #|
      #|(1) <loc>: expect(received).to_equal(expected)
      #|    Expected: 2
      #|    Received: 1
      #|
      #|(2) <loc>: [0]: expect(received).to_equal(expected)
      #|    Expected: 5
      #|    Received: 1
      #|
      #|(3) <loc>: expect(received).to_be_less_than(expected)
      #|    Expected: < 3
      #|    Received: 4
      #|
      #|(4) <loc>: expect(received).to_satisfy(predicate)
      #|    Expected: predicate
      #|    Received: 7
      #|    Because:  seven is odd
    ),
  )
}

///|
test "failed navigation stops the block" {
  inspect(
    scoped_failure(() => {
      expect_all(s => {
        s.expect(1).to_equal(2)
        s.expect((None : Int?)).unwrap_some().to_equal(1)
        s.expect(3).to_equal(4)
      })
    }),
    content=(
      #|2 of 2 assertions failed
      #|
      #|(1) <loc>: expect(received).to_equal(expected)
      #|    Expected: 2
      #|    Received: 1
      #|
      #|(2) <loc>: expect(received).unwrap_some()
      #|    Expected: Some(_)
      #|    Received: None
      #|
      #|(2) stopped the block, so later assertions did not run.
    ),
  )
}

///|
test "a hard failure in the block is recorded and stops the block" {
  inspect(
    scoped_failure(() => {
      expect_all(s => {
        s.expect(1).to_equal(2)
        expect(3).to_equal(4)
        s.expect(5).to_equal(6)
      })
    }),
    content=(
      #|2 of 2 assertions failed
      #|
      #|(1) <loc>: expect(received).to_equal(expected)
      #|    Expected: 2
      #|    Received: 1
      #|
      #|(2) <loc>: expect(received).to_equal(expected)
      #|    Expected: 4
      #|    Received: 3
      #|
      #|(2) stopped the block, so later assertions did not run.
    ),
  )
}

///|
test "nested scopes report to the outer scope" {
  inspect(
    scoped_failure(() => {
      expect_all(s => {
        s.expect_all(inner => {
          inner.expect(1).to_equal(2)
          inner.expect((None : Int?)).unwrap_some().to_equal(1)
          inner.expect(9).to_equal(9)
        })
        s.expect(3).to_equal(4)
      })
    }),
    content=(
      #|3 of 3 assertions failed
      #|
      #|(1) <loc>: expect(received).to_equal(expected)
      #|    Expected: 2
      #|    Received: 1
      #|
      #|(2) <loc>: expect(received).unwrap_some()
      #|    Expected: Some(_)
      #|    Received: None
      #|
      #|(3) <loc>: expect(received).to_equal(expected)
      #|    Expected: 4
      #|    Received: 3
      #|
      #|(2) stopped the inner block, so later assertions in it did not run.
    ),
  )
}

///|
test "expect_call and matching work in a scope" {
  inspect(
    scoped_failure(() => {
      expect_all(s => {
        s.expect_call(() => fails("boom")).not().to_raise()
        s.expect(5).to(matching("small", it => it.to_be_less_than(3)))
      })
    }),
    content=(
      #|2 of 2 assertions failed
      #|
      #|(1) <loc>: expect(received).not.to_raise()
      #|    Expected: not an error
      #|    Received: error "boom"
      #|
      #|(2) <loc>: expect(received).to(matcher)
      #|    Expected: small
      #|    Received: 5
      #|    Mismatch: was 5 (expected < 3)
    ),
  )
}
