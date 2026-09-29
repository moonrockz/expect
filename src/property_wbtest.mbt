///|
test "for_all passes when the property holds" {
  for_all((x : Int) => expect(x * 2 % 2).to_equal(0))
  for_all((xs : Array[Int]) => {
    expect(xs.length()).to_be_greater_than_or_equal(0)
  })
}

///|
test "for_all shows the smallest counterexample and the matcher failure" {
  let message = failure(() => {
    for_all((x : Int) => expect(x).to_be_less_than(50), seed=42)
  })
  let lines = message.split("\n").map(line => line.to_owned()).collect()
  inspect(
    lines[0].has_prefix("for_all(property) failed after "),
    content="true",
  )
  inspect(lines[1], content="Counterexample: 50")
  inspect(lines[2].has_prefix("Shrinks:"), content="true")
  inspect(lines[3], content="Failure:")
  inspect(lines[4].has_prefix("  src/property_wbtest.mbt:"), content="true")
  inspect(
    lines[4].has_suffix(": expect(received).to_be_less_than(expected)"),
    content="true",
  )
  inspect(
    lines[5:].iter().join("\n"),
    content=(
      #|  Expected: < 50
      #|  Received: 50
    ),
  )
}
