///|
priv struct Member {
  name : String
  age : Int
  city : String
} derive(Debug)

///|
let members : Array[Member] = [
  { name: "Ada", age: 36, city: "London", },
  { name: "Bob", age: 17, city: "Paris", },
]

///|
test "to runs a matcher" {
  expect(3).to(equal_to(3))
  expect(3).not().to(equal_to(4))
  inspect(
    failure(() => expect(3).to(equal_to(4))),
    content=(
      #|expect(received).to(matcher)
      #|Expected: equal to 4
      #|Received: 3
      #|Mismatch: was 3
    ),
  )
  inspect(
    failure(() => expect(3).not().to(equal_to(3))),
    content=(
      #|expect(received).not.to(matcher)
      #|Expected: not equal to 3
      #|Received: 3
    ),
  )
}

///|
test "satisfying" {
  expect(4).to(satisfying(x => x % 2 == 0, description="even"))
  inspect(
    failure(() => expect(3).to(satisfying(x => x % 2 == 0, description="even"))),
    content=(
      #|expect(received).to(matcher)
      #|Expected: even
      #|Received: 3
      #|Mismatch: was 3
    ),
  )
}

///|
test "all_of names every part that does not match" {
  expect(4).to(all_of([equal_to(4), is_not(equal_to(5))]))
  let in_range = all_of([
    satisfying(x => x > 1, description="> 1"),
    satisfying(x => x < 5, description="< 5"),
    satisfying(x => x % 2 == 0, description="even"),
  ])
  expect(4).to(in_range)
  inspect(
    failure(() => expect(7).to(in_range)),
    content=(
      #|expect(received).to(matcher)
      #|Expected: all of (> 1, < 5, even)
      #|Received: 7
      #|Mismatch:
      #|  < 5: was 7
      #|  even: was 7
    ),
  )
}

///|
test "any_of" {
  expect(8).to(any_of([equal_to(1), equal_to(8)]))
  let small_or_even = any_of([
    satisfying(x => x < 3, description="< 3"),
    satisfying(x => x % 2 == 0, description="even"),
  ])
  expect(1).to(small_or_even)
  expect(8).to(small_or_even)
  inspect(
    failure(() => expect(7).to(small_or_even)),
    content=(
      #|expect(received).to(matcher)
      #|Expected: any of (< 3, even)
      #|Received: 7
      #|Mismatch:
      #|  < 3: was 7
      #|  even: was 7
    ),
  )
}

///|
test "is_not" {
  expect(3).to(is_not(equal_to(4)))
  inspect(
    failure(() => expect(3).to(is_not(equal_to(3)))),
    content=(
      #|expect(received).to(matcher)
      #|Expected: not equal to 3
      #|Received: 3
      #|Mismatch: was 3
    ),
  )
}

///|
test "field checks one property" {
  expect((1, "a")).to(field("first", p => p.0, equal_to(1)))
  expect(members[0]).to(field("name", m => m.name, equal_to("Ada")))
  inspect(
    failure(() => expect(members[1]).to(field("age", m => m.age, equal_to(18)))),
    content=(
      #|expect(received).to(matcher)
      #|Expected: age equal to 18
      #|Received: { name: "Bob", age: 17, city: "Paris" }
      #|Mismatch: was 17
    ),
  )
}

///|
test "matching reuses method matchers" {
  expect(3).to(matching("positive", it => it.to_be_positive()))
  expect(-3).to(is_not(matching("positive", it => it.to_be_positive())))
  inspect(
    failure(() => {
      expect(members[1]).to(
        field(
          "age",
          m => m.age,
          matching("an adult", it => it.to_be_greater_than_or_equal(18)),
        ),
      )
    }),
    content=(
      #|expect(received).to(matcher)
      #|Expected: age an adult
      #|Received: { name: "Bob", age: 17, city: "Paris" }
      #|Mismatch: was 17 (expected >= 18)
    ),
  )
}

///|
test "to_contain_element_matching" {
  expect([1, 2, 3]).to_contain_element_matching(equal_to(2))
  expect(members).to_contain_element_matching(
    field("city", m => m.city, equal_to("Paris")),
  )
  expect(members)
  .not()
  .to_contain_element_matching(field("city", m => m.city, equal_to("Rome")))
  inspect(
    failure(() => {
      expect(members).to_contain_element_matching(
        all_of([
          field("city", m => m.city, equal_to("London")),
          field("age", m => m.age, satisfying(a => a < 18, description="< 18")),
        ]),
      )
    }),
    content=(
      #|expect(received).to_contain_element_matching(matcher)
      #|Expected: containing an element: all of (city equal to "London", age < 18)
      #|Received:
      #|  [
      #|    { name: "Ada", age: 36, city: "London" },
      #|    { name: "Bob", age: 17, city: "Paris" },
      #|  ]
      #|Mismatches:
      #|  index 0: age < 18: was 36
      #|  index 1: city equal to "London": was "Paris"
    ),
  )
}

///|
test "users can build their own matchers" {
  let even : Matcher[Int] = {
    describe: () => "even",
    check: x => if x % 2 == 0 { None } else { Some("was odd") },
  }
  expect([1, 2, 3]).to_contain_element_matching(even)
  inspect(
    failure(() => expect(3).to(even)),
    content=(
      #|expect(received).to(matcher)
      #|Expected: even
      #|Received: 3
      #|Mismatch: was odd
    ),
  )
}
