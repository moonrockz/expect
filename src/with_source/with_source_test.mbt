///|
priv struct User {
  name : String
  age : Int
}

///|
test "the headline shows the expression" {
  let user : User = { name: "Ada", age: 17, }
  inspect(
    @expect.failure_message(() => @with_source.expect(user.age + 1).to_equal(20)),
    content=(
      #|expect(user.age + 1).to_equal(expected)
      #|Expected: 20
      #|Received: 18
    ),
  )
  inspect(
    @expect.failure_message(() => {
      @with_source.expect(user.name, label="name").not().to_equal("Ada")
    }),
    content=(
      #|name: expect(user.name).not.to_equal(expected)
      #|Expected: not "Ada"
      #|Received: "Ada"
    ),
  )
}

///|
test "an expression over several lines is shown on one line" {
  let values = [1, 2, 3]
  inspect(
    @expect.failure_message(() => {
      @with_source.expect(
        values.map(number => number * 2).filter(number => number > 1).length(),
      ).to_equal(7)
    }),
    content=(
      #|expect(values.map(number => number * 2).filter(number => number > 1).length()).to_equal(expected)
      #|Expected: 7
      #|Received: 3
    ),
  )
}

///|
test "navigation shows the path, not the expression" {
  let user : User = { name: "Ada", age: 17, }
  inspect(
    @expect.failure_message(() => {
      @with_source.expect(user).get("age", u => u.age).to_equal(18)
    }),
    content=(
      #|age: expect(received).to_equal(expected)
      #|Expected: 18
      #|Received: 17
    ),
  )
}

///|
test "expect_call shows the function" {
  inspect(
    @expect.failure_message(() => {
      @with_source.expect_call(() => @string.parse_int("12")).to_raise()
    }),
    content=(
      #|expect(() => @string.parse_int("12")).to_raise()
      #|Expected: an error
      #|Received: no error
    ),
  )
}
