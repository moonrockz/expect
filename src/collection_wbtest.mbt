///|
test "to_contain_exactly" {
  expect([1, 2, 3]).to_contain_exactly([1, 2, 3])
  expect([1, 2, 3]).not().to_contain_exactly([3, 2, 1])
  inspect(
    failure(() => expect([1, 2, 3]).to_contain_exactly([1, 5, 3])),
    content=(
      #|expect(received).to_contain_exactly(expected)
      #|Expected:         exactly [1, 5, 3], in order
      #|Received:         [1, 2, 3]
      #|First difference: index 1: expected 5, received 2
    ),
  )
  inspect(
    failure(() => expect([1, 2]).to_contain_exactly([1, 2, 3])),
    content=(
      #|expect(received).to_contain_exactly(expected)
      #|Expected:         exactly [1, 2, 3], in order
      #|Received:         [1, 2]
      #|First difference: index 2: expected 3, received nothing
    ),
  )
  inspect(
    failure(() => expect([1, 2, 3, 4]).to_contain_exactly([1, 2])),
    content=(
      #|expect(received).to_contain_exactly(expected)
      #|Expected:         exactly [1, 2], in order
      #|Received:         [1, 2, 3, 4]
      #|First difference: index 2: expected nothing, received 3
    ),
  )
}

///|
test "to_contain_only" {
  expect([1, 2, 2, 3]).to_contain_only([3, 1, 2])
  expect([1, 2]).not().to_contain_only([1, 2, 3])
  inspect(
    failure(() => expect([1, 2, 4, 4]).to_contain_only([1, 2, 3])),
    content=(
      #|expect(received).to_contain_only(expected)
      #|Expected: only elements of [1, 2, 3], each at least once
      #|Received: [1, 2, 4, 4]
      #|Missing:  [3]
      #|Extra:    [4]
    ),
  )
}

///|
test "to_contain_in_order" {
  expect([1, 2, 3, 4]).to_contain_in_order([1, 3, 4])
  expect([1, 2, 3]).not().to_contain_in_order([3, 1])
  inspect(
    failure(() => expect([1, 2, 3, 4]).to_contain_in_order([2, 1, 4])),
    content=(
      #|expect(received).to_contain_in_order(expected)
      #|Expected: containing [2, 1, 4] in this order
      #|Received: [1, 2, 3, 4]
      #|Missing:  1, after index 1
    ),
  )
  inspect(
    failure(() => expect([1, 2]).to_contain_in_order([5])),
    content=(
      #|expect(received).to_contain_in_order(expected)
      #|Expected: containing [5] in this order
      #|Received: [1, 2]
      #|Missing:  5
    ),
  )
}

///|
test "to_start_with_elements and to_end_with_elements" {
  expect([1, 2, 3]).to_start_with_elements([1, 2])
  expect([1, 2, 3]).to_end_with_elements([2, 3])
  expect([1, 2, 3]).not().to_start_with_elements([2])
  inspect(
    failure(() => expect([1, 2, 3]).to_start_with_elements([2, 3])),
    content=(
      #|expect(received).to_start_with_elements(expected)
      #|Expected: starting with [2, 3]
      #|Received: [1, 2, 3]
    ),
  )
  inspect(
    failure(() => expect([1, 2, 3]).to_end_with_elements([1])),
    content=(
      #|expect(received).to_end_with_elements(expected)
      #|Expected: ending with [1]
      #|Received: [1, 2, 3]
    ),
  )
}

///|
test "to_any_satisfy and to_none_satisfy" {
  expect([1, 2, 3]).to_any_satisfy(x => x > 2)
  expect([1, 2, 3]).to_none_satisfy(x => x > 3)
  expect([1, 2, 3]).not().to_none_satisfy(x => x > 2)
  inspect(
    failure(() => {
      expect([1, 3]).to_any_satisfy(
        x => x % 2 == 0,
        description="an even number",
      )
    }),
    content=(
      #|expect(received).to_any_satisfy(predicate)
      #|Expected: some element to satisfy an even number
      #|Received: [1, 3]
    ),
  )
  inspect(
    failure(() => {
      expect([1, 2, 3, 4]).to_none_satisfy(
        x => x % 2 == 0,
        description="an even number",
      )
    }),
    content=(
      #|expect(received).to_none_satisfy(predicate)
      #|Expected: no element to satisfy an even number
      #|Received: [1, 2, 3, 4]
      #|Satisfied at:
      #|  index 1: 2
      #|  index 3: 4
    ),
  )
}

///|
test "to_all_satisfy lists every failing element" {
  inspect(
    failure(() => expect([1, 2, 3]).to_all_satisfy(x => x == 2)),
    content=(
      #|expect(received).to_all_satisfy(predicate)
      #|Expected: every element to satisfy predicate
      #|Received: [1, 2, 3]
      #|Failed at:
      #|  index 0: 1
      #|  index 2: 3
    ),
  )
}

///|
test "to_have_count_satisfying" {
  expect([1, 2, 3, 4]).to_have_count_satisfying(2, x => x % 2 == 0)
  inspect(
    failure(() => {
      expect([1, 2, 3]).to_have_count_satisfying(
        2,
        x => x % 2 == 0,
        description="an even number",
      )
    }),
    content=(
      #|expect(received).to_have_count_satisfying(count, predicate)
      #|Expected: 2 elements to satisfy an even number
      #|Received: [1, 2, 3]
      #|Count:    1
    ),
  )
}

///|
test "to_contain_none_of" {
  expect([1, 2, 3]).to_contain_none_of([4, 5])
  expect([1, 2, 3]).not().to_contain_none_of([3, 5])
  inspect(
    failure(() => expect([1, 2, 3]).to_contain_none_of([3, 4, 1])),
    content=(
      #|expect(received).to_contain_none_of(values)
      #|Expected: containing none of [3, 4, 1]
      #|Received: [1, 2, 3]
      #|Found:    [3, 1]
    ),
  )
}

///|
test "to_satisfy_respectively" {
  expect([1]).to_satisfy_respectively([it => it.to_equal(1)])
  expect([1, "a".length()]).to_satisfy_respectively([
    it => it.to_equal(1),
    it => it.to_be_greater_than(0),
  ])
  inspect(
    failure(() => {
      expect([1, 2], label="items").to_satisfy_respectively([
        it => it.to_equal(1),
        it => it.to_equal(3),
      ])
    }),
    content=(
      #|items[1]: expect(received).to_equal(expected)
      #|Expected: 3
      #|Received: 2
    ),
  )
  inspect(
    failure(() => expect([1, 2]).to_satisfy_respectively([it => it.to_equal(1)])),
    content=(
      #|expect(received).to_satisfy_respectively(checks)
      #|Expected: 1 elements, one for each check
      #|Received: [1, 2]
      #|Length:   2
    ),
  )
}

///|
test "to_be_sorted and to_be_sorted_by" {
  expect([1, 2, 2, 3]).to_be_sorted()
  expect(([] : Array[Int])).to_be_sorted()
  expect(["ccc", "a", "bb"]).not().to_be_sorted_by(s => s.length())
  expect(["a", "bb", "ccc"]).to_be_sorted_by(s => s.length())
  inspect(
    failure(() => expect([1, 3, 2]).to_be_sorted()),
    content=(
      #|expect(received).to_be_sorted()
      #|Expected:     sorted in ascending order
      #|Received:     [1, 3, 2]
      #|Out of order: index 1: 3, index 2: 2
    ),
  )
  inspect(
    failure(() => expect(["bb", "a"]).to_be_sorted_by(s => s.length())),
    content=(
      #|expect(received).to_be_sorted_by(key)
      #|Expected:     sorted in ascending order of key
      #|Received:     ["bb", "a"]
      #|Out of order: index 0: "bb", index 1: "a"
    ),
  )
}

///|
test "to_have_no_duplicates" {
  expect([1, 2, 3]).to_have_no_duplicates()
  expect([1, 2, 1]).not().to_have_no_duplicates()
  inspect(
    failure(() => expect([1, 2, 1, 3, 2, 1]).to_have_no_duplicates()),
    content=(
      #|expect(received).to_have_no_duplicates()
      #|Expected:   no duplicate elements
      #|Received:   [1, 2, 1, 3, 2, 1]
      #|Duplicates: [1, 2]
    ),
  )
}
