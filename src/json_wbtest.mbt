///|
let order : Json = {
  "id": 7,
  "customer": { "name": "Ada", "tags": ["vip", "early"] },
  "items": [{ "sku": "A1", "qty": 2 }, { "sku": "B2", "qty": 1 }],
}

///|
test "at navigates to a value" {
  expect(({ "a": [{ "b": 1 }] } : Json)).at("a[0].b").to_equal(1)
  expect(order).at("id").to_equal(7)
  expect(order).at("customer.name").to_equal("Ada")
  expect(order).at("customer.tags[1]").to_equal("early")
  expect(order).at("items[0].sku").to_equal("A1")
  inspect(
    failure(() => expect(order, label="order").at("items[1].qty").to_equal(3)),
    content=(
      #|order.items[1].qty: expect(received).to_equal(expected)
      #|Expected: Number(3)
      #|Received: Number(1)
    ),
  )
}

///|
test "at fails on a missing path and shows the deepest part that exists" {
  inspect(
    failure(() => expect(order).at("customer.email").to_equal("x")),
    content=(
      #|expect(received).at(path)
      #|Expected: a value at "customer.email"
      #|Received: {"id":7,"customer":{"name":"Ada","tags":["vip","early"]},"items":[{"sku":"A1","qty":2},{"sku":"B2","qty":1}]}
      #|Found:    customer has no key "email"
    ),
  )
  inspect(
    failure(() => expect(order).at("items[5].sku").to_equal("x")),
    content=(
      #|expect(received).at(path)
      #|Expected: a value at "items[5].sku"
      #|Received: {"id":7,"customer":{"name":"Ada","tags":["vip","early"]},"items":[{"sku":"A1","qty":2},{"sku":"B2","qty":1}]}
      #|Found:    items is an array of length 2
    ),
  )
  inspect(
    failure(() => expect(order).at("id.value").to_equal("x")),
    content=(
      #|expect(received).at(path)
      #|Expected: a value at "id.value"
      #|Received: {"id":7,"customer":{"name":"Ada","tags":["vip","early"]},"items":[{"sku":"A1","qty":2},{"sku":"B2","qty":1}]}
      #|Found:    id is a number, not an object
    ),
  )
  inspect(
    failure(() => expect(order).at("items[x]").to_equal("x")),
    content=(
      #|expect(received).at(path)
      #|Error: invalid path "items[x]"
    ),
  )
}

///|
test "to_contain_json" {
  expect(({ "id": 7, "qty": 2 } : Json)).to_contain_json({ "id": 7 })
  expect(order).to_contain_json({ "id": 7 })
  expect(order).to_contain_json({ "customer": { "name": "Ada" } })
  expect(order).to_contain_json({ "items": [{ "sku": "A1" }, { "qty": 1 }] })
  expect(order).not().to_contain_json({ "id": 8 })
  inspect(
    failure(() => {
      expect(order).to_contain_json({
        "id": 8,
        "customer": { "name": "Ada", "email": "ada@example.com" },
        "items": [{ "sku": "A1" }],
      })
    }),
    content=(
      #|expect(received).to_contain_json(expected)
      #|Expected: containing {"id":8,"customer":{"name":"Ada","email":"ada@example.com"},"items":[{"sku":"A1"}]}
      #|Received: {"id":7,"customer":{"name":"Ada","tags":["vip","early"]},"items":[{"sku":"A1","qty":2},{"sku":"B2","qty":1}]}
      #|Missing:  customer.email
      #|Different:
      #|  id: expected 8, received 7
      #|  items: expected an array of length 1, received length 2
    ),
  )
}
