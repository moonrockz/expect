// More collection types
//
// Collection matchers work on `Array`. A trait cannot name the element type
// of other collections, so `expect_elements` collects any `Iter` into an
// array. `HasLength` has no element type, so it is implemented for every
// core collection that has a length.

///|
/// Create an expectation on the elements of any collection, as an Array:
/// `expect_elements(deque.iter()).to_contain_element(3)`. All Array
/// matchers and navigation methods then work.
pub fn[T] expect_elements(
  items : Iter[T],
  label? : String = "",
) -> Expectation[Array[T]] {
  expect(items.collect(), label~)
}

///|
pub impl[T] HasLength for ArrayView[T] with fn length(self) {
  self.length()
}

///|
pub impl HasLength for StringView with fn length(self) {
  self.length()
}

///|
pub impl HasLength for BytesView with fn length(self) {
  self.length()
}

///|
pub impl[T] HasLength for @deque.Deque[T] with fn length(self) {
  self.length()
}

///|
pub impl[K, V] HasLength for @hashmap.HashMap[K, V] with fn length(self) {
  self.length()
}

///|
pub impl[T] HasLength for @hashset.HashSet[T] with fn length(self) {
  self.length()
}

///|
pub impl[K, V] HasLength for @sorted_map.SortedMap[K, V] with fn length(self) {
  self.length()
}

///|
pub impl[T] HasLength for @sorted_set.SortedSet[T] with fn length(self) {
  self.length()
}

///|
pub impl[T] HasLength for @queue.Queue[T] with fn length(self) {
  self.length()
}

///|
pub impl[T] HasLength for @priority_queue.PriorityQueue[T] with fn length(self) {
  self.length()
}

///|
pub impl[T] HasLength for @list.List[T] with fn length(self) {
  self.length()
}

///|
pub impl[K, V] HasLength for @immut_hashmap.HashMap[K, V] with fn length(self) {
  self.length()
}

///|
pub impl[T] HasLength for @immut_hashset.HashSet[T] with fn length(self) {
  self.length()
}

///|
pub impl[T] HasLength for @immut_priority_queue.PriorityQueue[T] with fn length(
  self,
) {
  self.length()
}

///|
pub impl[K, V] HasLength for @immut_sorted_map.SortedMap[K, V] with fn length(
  self,
) {
  self.length()
}

///|
pub impl[T] HasLength for @immut_sorted_set.SortedSet[T] with fn length(self) {
  self.length()
}

///|
pub impl[T] HasLength for @vector.Vector[T] with fn length(self) {
  self.length()
}

///|
pub impl[K, V] HasLength for @vector_map.VectorMap[K, V] with fn length(self) {
  self.length()
}
