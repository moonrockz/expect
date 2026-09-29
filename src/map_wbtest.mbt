///|
test "to_contain_value" {
  expect({ "a": 1 }).to_contain_value(1)
  let m = { "a": 1, "b": 2 }
  expect(m).to_contain_value(2)
  expect(m).not().to_contain_value(3)
  inspect(
    failure(() => expect(m).to_contain_value(3)),
    content=(
      #|expect(received).to_contain_value(value)
      #|Expected: containing value 3
      #|Received: { "a": 1, "b": 2 }
    ),
  )
}

///|
test "to_contain_entry" {
  expect({ "a": 1, "b": 2 }).to_contain_entry("a", 1)
  let m = { "a": 1, "b": 2 }
  expect(m).to_contain_entry("a", 1)
  expect(m).not().to_contain_entry("a", 2)
  inspect(
    failure(() => expect(m).to_contain_entry("b", 3)),
    content=(
      #|expect(received).to_contain_entry(key, value)
      #|Expected: containing "b": 3
      #|Received: { "a": 1, "b": 2 }
      #|Value:    2
    ),
  )
  inspect(
    failure(() => expect(m).to_contain_entry("c", 3)),
    content=(
      #|expect(received).to_contain_entry(key, value)
      #|Expected: containing "c": 3
      #|Received: { "a": 1, "b": 2 }
      #|Value:    no key "c"
    ),
  )
}

///|
test "to_contain_entries" {
  expect({ "a": 1, "b": 2 }).to_contain_entries({ "b": 2 })
  let m = { "a": 1, "b": 2, "c": 3 }
  expect(m).to_contain_entries({ "c": 3, "a": 1 })
  expect(m).not().to_contain_entries({ "a": 2 })
  inspect(
    failure(() => expect(m).to_contain_entries({ "a": 1, "b": 5, "d": 4 })),
    content=(
      #|expect(received).to_contain_entries(expected)
      #|Expected: containing { "a": 1, "b": 5, "d": 4 }
      #|Received: { "a": 1, "b": 2, "c": 3 }
      #|Missing:  { "d": 4 }
      #|Changed:  "b": expected 5, received 2
    ),
  )
}

///|
test "to_equal on maps shows the difference by key" {
  let expected = { "a": 1, "b": 2, "c": 3 }
  // Maps with the same entries are equal in any order.
  expect({ "c": 3, "a": 1, "b": 2 }).to_equal(expected)
  inspect(
    failure(() => expect({ "d": 4, "b": 5, "a": 1 }).to_equal(expected)),
    content=(
      #|expect(received).to_equal(expected)
      #|Expected: { "a": 1, "b": 2, "c": 3 }
      #|Received: { "d": 4, "b": 5, "a": 1 }
      #|Missing:  { "c": 3 }
      #|Extra:    { "d": 4 }
      #|Changed:  "b": expected 2, received 5
    ),
  )
}

///|
test "map diff lists each changed key on its own line" {
  let expected = { 1: [1, 2], 2: [3], 3: [] }
  inspect(
    failure(() => expect({ 1: [1], 2: [4], 3: [] }).to_equal(expected)),
    content=(
      #|expect(received).to_equal(expected)
      #|Expected: { 1: [1, 2], 2: [3], 3: [] }
      #|Received: { 1: [1], 2: [4], 3: [] }
      #|Changed:
      #|  1: expected [1, 2], received [1]
      #|  2: expected [3], received [4]
    ),
  )
}

///|
test "records keep the line diff" {
  inspect(
    failure(() => expect({ x: 1, y: 2, }).to_equal({ x: 1, y: 3, })),
    content=(
      #|expect(received).to_equal(expected)
      #|Expected: { x: 1, y: 3 }
      #|Received: { x: 1, y: 2 }
      #|Diff (- expected, + received):
      #|  @@ -1,4 +1,4 @@
      #|   {
      #|     x: 1,
      #|  -  y: 3,
      #|  +  y: 2,
      #|  ?     ^
      #|   }
    ),
  )
}
