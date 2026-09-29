///|
priv struct Person {
  name : String
  address : Home
} derive(Debug)

///|
priv struct Home {
  city : String
} derive(Debug)

///|
let ada : Person = { name: "Ada", address: { city: "London", }, }

///|
test "get navigates to a property" {
  expect(ada).get("name", u => u.name).to_equal("Ada")
  inspect(
    failure(() => expect(ada).get("name", u => u.name).to_equal("Bob")),
    content=(
      #|name: expect(received).to_equal(expected)
      #|Expected: "Bob"
      #|Received: "Ada"
    ),
  )
}

///|
test "get extends the label and chains into a path" {
  inspect(
    failure(() => {
      expect(ada, label="user")
      .get("address", u => u.address)
      .get("city", a => a.city)
      .to_equal("Paris")
    }),
    content=(
      #|user.address.city: expect(received).to_equal(expected)
      #|Expected: "Paris"
      #|Received: "London"
    ),
  )
}

///|
test "get cannot be used after not" {
  inspect(
    failure(() => expect(ada).not().get("name", u => u.name).to_equal("Bob")),
    content=(
      #|expect(received).not.get()
      #|Error: get cannot be used after not()
    ),
  )
}

///|
test "element navigates to an index" {
  expect([10, 20, 30]).element(1).to_equal(20)
  inspect(
    failure(() => expect([10, 20, 30], label="items").element(2).to_equal(0)),
    content=(
      #|items[2]: expect(received).to_equal(expected)
      #|Expected: 0
      #|Received: 30
    ),
  )
  inspect(
    failure(() => expect([10, 20, 30]).element(5).to_equal(0)),
    content=(
      #|expect(received).element(index)
      #|Expected: an element at index 5
      #|Received: [10, 20, 30]
      #|Length:   3
    ),
  )
}

///|
test "first and last" {
  expect([1, 2, 3]).first().to_equal(1)
  expect([1, 2, 3]).last().to_equal(3)
  inspect(
    failure(() => expect([1, 2, 3]).last().to_equal(0)),
    content=(
      #|[2]: expect(received).to_equal(expected)
      #|Expected: 0
      #|Received: 3
    ),
  )
  inspect(
    failure(() => expect(([] : Array[Int])).first().to_equal(0)),
    content=(
      #|expect(received).first()
      #|Expected: a first element
      #|Received: []
    ),
  )
  inspect(
    failure(() => expect(([] : Array[Int])).last().to_equal(0)),
    content=(
      #|expect(received).last()
      #|Expected: a last element
      #|Received: []
    ),
  )
}

///|
test "single" {
  expect([ada]).single().get("name", u => u.name).to_equal("Ada")
  inspect(
    failure(() => expect([1, 2]).single().to_equal(1)),
    content=(
      #|expect(received).single()
      #|Expected: exactly one element
      #|Received: [1, 2]
      #|Length:   2
    ),
  )
}

///|
test "value_at navigates to a map value" {
  let ports = { "http": 80, "https": 443 }
  expect(ports).value_at("http").to_equal(80)
  inspect(
    failure(() => expect(ports, label="ports").value_at("https").to_equal(8443)),
    content=(
      #|ports["https"]: expect(received).to_equal(expected)
      #|Expected: 8443
      #|Received: 443
    ),
  )
  inspect(
    failure(() => expect(ports).value_at("ftp").to_equal(21)),
    content=(
      #|expect(received).value_at(key)
      #|Expected: containing key "ftp"
      #|Received: { "http": 80, "https": 443 }
    ),
  )
}

///|
test "fst and snd navigate into a pair" {
  expect((1, "one")).fst().to_equal(1)
  expect((1, "one")).snd().to_equal("one")
  inspect(
    failure(() => expect((1, "one"), label="pair").snd().to_equal("two")),
    content=(
      #|pair.1: expect(received).to_equal(expected)
      #|Expected: "two"
      #|Received: "one"
    ),
  )
}

///|
test "all runs every matcher on one value" {
  expect(42).all(it => {
    it.to_be_greater_than(0)
    it.to_be_less_than(100)
  })
  inspect(
    failure(() => {
      expect(ada, label="user").all(it => {
        it.get("name", u => u.name).to_equal("Ada")
        it.get("address", u => u.address.city).to_equal("Paris")
      })
    }),
    content=(
      #|user.address: expect(received).to_equal(expected)
      #|Expected: "Paris"
      #|Received: "London"
    ),
  )
  inspect(
    failure(() => expect(42).not().all(it => it.to_be_greater_than(0))),
    content=(
      #|expect(received).not.all()
      #|Error: all cannot be used after not()
    ),
  )
}
