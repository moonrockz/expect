///|
test "expect_elements works on any collection" {
  expect_elements(@deque.Deque([1, 2]).iter()).to_contain_exactly([1, 2])
  expect_elements(@list.List([3, 1, 2]).iter()).to_contain_only([1, 2, 3])
  expect_elements(@immut_sorted_set.SortedSet([3, 1]).iter())
  .first()
  .to_equal(1)
  inspect(
    failure(() => {
      expect_elements([1, 2][:].iter(), label="view").to_contain_element(5)
    }),
    content=(
      #|view: expect(received).to_contain_element(expected)
      #|Expected: containing 5
      #|Received: [1, 2]
    ),
  )
}

///|
test "HasLength works for core collections" {
  let array = [1, 2, 3]
  expect(array[1:]).to_have_length(2)
  expect("hello"[1:3]).to_have_length(2)
  expect(b"abc"[:]).to_have_length(3)
  expect(@deque.Deque([1])).to_have_length(1)
  expect(@hashmap.HashMap([("a", 1)])).to_have_length(1)
  expect(@hashset.HashSet([1])).to_have_length(1)
  expect((@sorted_map.SortedMap([]) : @sorted_map.SortedMap[Int, Int])).to_be_empty()
  expect((@sorted_set.SortedSet([]) : @sorted_set.SortedSet[Int])).to_be_empty()
  expect((@queue.Queue([]) : @queue.Queue[Int])).to_be_empty()
  expect(
    (@priority_queue.PriorityQueue([]) : @priority_queue.PriorityQueue[Int]),
  ).to_be_empty()
  expect(@list.List([1, 2])).to_have_length(2)
  expect(@immut_hashmap.HashMap([("a", 1)])).to_have_length(1)
  expect(@immut_hashset.HashSet([1, 2])).to_have_length(2)
  expect(
    (
      @immut_priority_queue.PriorityQueue([]) :
      @immut_priority_queue.PriorityQueue[Int]),
  ).to_be_empty()
  expect(@immut_sorted_map.SortedMap([(1, "a")])).to_have_length(1)
  expect(@immut_sorted_set.SortedSet([1, 2, 3])).to_have_length(3)
  expect((@vector.Vector([]) : @vector.Vector[Int])).to_be_empty()
  expect((@vector_map.VectorMap([]) : @vector_map.VectorMap[Int, Int])).to_be_empty()
  inspect(
    failure(() => expect(@list.List([1, 2])).to_be_empty()),
    content=(
      #|expect(received).to_be_empty()
      #|Expected: empty
      #|Received: <List: [1, 2]>
      #|Length:   2
    ),
  )
}
