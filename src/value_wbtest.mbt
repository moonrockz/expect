///|
test "to_be_one_of" {
  expect(2).to_be_one_of([1, 2, 3])
  expect(5).not().to_be_one_of([1, 2, 3])
  inspect(
    failure(() => expect("d").to_be_one_of(["a", "b"])),
    content=(
      #|expect(received).to_be_one_of(values)
      #|Expected: one of ["a", "b"]
      #|Received: "d"
    ),
  )
}

///|
test "to_be_in" {
  let allowed = Set([1, 2, 3])
  expect(2).to_be_in(allowed)
  expect(5).not().to_be_in(allowed)
  inspect(
    failure(() => expect(5).to_be_in(Set([1]))),
    content=(
      #|expect(received).to_be_in(set)
      #|Expected: in <Set: [1]>
      #|Received: 5
    ),
  )
}

///|
test "because adds a reason to the failure" {
  expect(1).because("never fails").to_equal(1)
  inspect(
    failure(() => {
      expect(3, label="retries")
      .because("the client retries three times")
      .to_equal(4)
    }),
    content=(
      #|retries: expect(received).to_equal(expected)
      #|Expected: 4
      #|Received: 3
      #|Because:  the client retries three times
    ),
  )
  inspect(
    failure(() => {
      expect([1, 2]).because("ids are unique").first().not().to_equal(1)
    }),
    content=(
      #|[0]: expect(received).not.to_equal(expected)
      #|Expected: not 1
      #|Received: 1
      #|Because:  ids are unique
    ),
  )
}

///|
test "Char matchers" {
  expect('7').to_be_digit()
  expect('a').to_be_letter()
  expect(' ').to_be_whitespace()
  expect('A').to_be_upper_case()
  expect('a').to_be_lower_case()
  expect('a').not().to_be_digit()
  expect('1').not().to_be_letter()
  inspect(
    failure(() => expect('x').to_be_digit()),
    content=(
      #|expect(received).to_be_digit()
      #|Expected: an ASCII digit
      #|Received: 'x' (U+0078)
    ),
  )
  inspect(
    failure(() => expect('é').to_be_letter()),
    content=(
      #|expect(received).to_be_letter()
      #|Expected: an ASCII letter
      #|Received: 'é' (U+00E9)
    ),
  )
  inspect(
    failure(() => expect('a').to_be_upper_case()),
    content=(
      #|expect(received).to_be_upper_case()
      #|Expected: an ASCII upper-case letter
      #|Received: 'a' (U+0061)
    ),
  )
}
