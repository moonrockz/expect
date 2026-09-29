///|
priv struct Cash {
  amount : Int
} derive(Debug)

///|
priv struct Wallet {
  id : Int
  owner : String
  balance : Cash
  tags : Array[String]
} derive(Debug)

///|
fn account(id : Int, amount : Int, tags : Array[String]) -> Wallet {
  { id, owner: "Ada", balance: { amount, }, tags, }
}

///|
test "to_be_equivalent_to compares field by field without Eq" {
  expect(account(1, 1050, ["a"])).to_be_equivalent_to(account(1, 1050, ["a"]))
  expect(account(1, 1050, ["a"]))
  .not()
  .to_be_equivalent_to(account(2, 1050, ["a"]))
  inspect(
    failure(() => {
      expect(account(1, 1005, ["a", "c"])).to_be_equivalent_to(
        account(1, 1050, ["a", "b"]),
      )
    }),
    content=(
      #|expect(received).to_be_equivalent_to(expected)
      #|Expected: equivalent to { id: 1, owner: "Ada", balance: { amount: 1050 }, tags: ["a", "b"] }
      #|Received: { id: 1, owner: "Ada", balance: { amount: 1005 }, tags: ["a", "c"] }
      #|Differences:
      #|  balance.amount: expected 1050, received 1005
      #|  tags[1]: expected "b", received "c"
    ),
  )
}

///|
test "excluding skips paths" {
  expect(account(1, 1050, ["a"])).to_be_equivalent_to(account(2, 1050, ["a"]), excluding=[
    "id",
  ])
  expect([account(1, 1, []), account(2, 2, [])]).to_be_equivalent_to(
    [account(8, 1, []), account(9, 2, [])],
    excluding=["[*].id"],
  )
  inspect(
    failure(() => {
      expect(account(1, 5, ["a"])).to_be_equivalent_to(account(2, 7, ["a"]), excluding=[
        "id",
      ])
    }),
    content=(
      #|expect(received).to_be_equivalent_to(expected)
      #|Expected:    equivalent to { id: 2, owner: "Ada", balance: { amount: 7 }, tags: ["a"] }, excluding id
      #|Received:    { id: 1, owner: "Ada", balance: { amount: 5 }, tags: ["a"] }
      #|Differences: balance.amount: expected 7, received 5
    ),
  )
}

///|
test "differences in length, keys and constructors" {
  inspect(
    failure(() => expect([1, 2, 3]).to_be_equivalent_to([1, 2])),
    content=(
      #|expect(received).to_be_equivalent_to(expected)
      #|Expected:    equivalent to [1, 2]
      #|Received:    [1, 2, 3]
      #|Differences: value: expected length 2, received length 3
    ),
  )
  inspect(
    failure(() => {
      expect({ "a": 1, "c": 3 }).to_be_equivalent_to({ "a": 1, "b": 2 })
    }),
    content=(
      #|expect(received).to_be_equivalent_to(expected)
      #|Expected: equivalent to { "a": 1, "b": 2 }
      #|Received: { "a": 1, "c": 3 }
      #|Differences:
      #|  ["b"]: missing
      #|  ["c"]: unexpected, 3
    ),
  )
  inspect(
    failure(() => expect(Some(Some(1))).to_be_equivalent_to(Some(None))),
    content=(
      #|expect(received).to_be_equivalent_to(expected)
      #|Expected:    equivalent to Some(None)
      #|Received:    Some(Some(1))
      #|Differences: value: expected None, received Some(1)
    ),
  )
}

///|
test "ignoring_order compares arrays as multisets at every depth" {
  let expected = {
    id: 1,
    owner: "Ada",
    balance: { amount: 1, },
    tags: ["x", "y"],
  }
  let actual = {
    id: 1,
    owner: "Ada",
    balance: { amount: 1, },
    tags: ["y", "x"],
  }
  expect(actual).to_be_equivalent_to(expected, ignoring_order=true)
  expect(actual).not().to_be_equivalent_to(expected)
  expect([[2, 1], [3]]).to_be_equivalent_to([[3], [1, 2]], ignoring_order=true)
  inspect(
    failure(() => {
      expect([1, 2, 2]).to_be_equivalent_to([2, 1, 3], ignoring_order=true)
    }),
    content=(
      #|expect(received).to_be_equivalent_to(expected)
      #|Expected: equivalent to [2, 1, 3], ignoring order
      #|Received: [1, 2, 2]
      #|Differences:
      #|  value: missing element 3
      #|  value: unexpected element 2
    ),
  )
}

///|
test "tolerance compares numbers" {
  expect((1.0, [2.0])).to_be_equivalent_to((1.05, [1.95]), tolerance=0.1)
  inspect(
    failure(() => {
      expect({ amount: 100, }).to_be_equivalent_to(
        { amount: 103, },
        tolerance=2.0,
      )
    }),
    content=(
      #|expect(received).to_be_equivalent_to(expected)
      #|Expected:    equivalent to { amount: 103 }, tolerance 2.0
      #|Received:    { amount: 100 }
      #|Differences: amount: expected 103, received 100
    ),
  )
}

///|
test "enum constructors with labelled arguments" {
  expect([Circle(radius=1), Line(1, 2)]).to_be_equivalent_to([
    Circle(radius=1),
    Line(1, 2),
  ])
  inspect(
    failure(() => expect(Line(1, 2)).to_be_equivalent_to(Line(1, 3))),
    content=(
      #|expect(received).to_be_equivalent_to(expected)
      #|Expected:    equivalent to Line(1, 3)
      #|Received:    Line(1, 2)
      #|Differences: 1: expected 3, received 2
    ),
  )
  inspect(
    failure(() => expect(Circle(radius=1)).to_be_equivalent_to(Circle(radius=2))),
    content=(
      #|expect(received).to_be_equivalent_to(expected)
      #|Expected:    equivalent to Circle(radius=2)
      #|Received:    Circle(radius=1)
      #|Differences: radius: expected 2, received 1
    ),
  )
}

///|
priv enum Figure {
  Circle(radius~ : Int)
  Line(Int, Int)
} derive(Debug)
