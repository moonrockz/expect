///|
test "sign matchers" {
  expect(3).to_be_positive()
  expect(-3L).to_be_negative()
  expect(0.0).to_be_zero()
  expect(0).not().to_be_positive()
  expect((1.5 : Float)).to_be_positive()
  inspect(
    failure(() => expect(-2).to_be_positive()),
    content=(
      #|expect(received).to_be_positive()
      #|Expected: > 0
      #|Received: -2
    ),
  )
  inspect(
    failure(() => expect(2.5).to_be_negative()),
    content=(
      #|expect(received).to_be_negative()
      #|Expected: < 0
      #|Received: 2.5
    ),
  )
  inspect(
    failure(() => expect(7).to_be_zero()),
    content=(
      #|expect(received).to_be_zero()
      #|Expected: 0
      #|Received: 7
    ),
  )
}

///|
test "to_be_between with exclusive bounds" {
  expect(1).to_be_between(1, 5)
  expect(1).not().to_be_between(1, 5, low_inclusive=false)
  expect(5).not().to_be_between(1, 5, high_inclusive=false)
  expect(4).to_be_between(1, 5, low_inclusive=false, high_inclusive=false)
  inspect(
    failure(() => expect(5).to_be_between(1, 5, high_inclusive=false)),
    content=(
      #|expect(received).to_be_between(low, high)
      #|Expected: between 1 and 5 (1 inclusive, 5 exclusive)
      #|Received: 5
    ),
  )
  inspect(
    failure(() => {
      expect(1).to_be_between(1, 5, low_inclusive=false, high_inclusive=false)
    }),
    content=(
      #|expect(received).to_be_between(low, high)
      #|Expected: between 1 and 5 (exclusive)
      #|Received: 1
    ),
  )
}

///|
test "to_be_nan and to_be_finite" {
  expect(0.0 / 0.0).to_be_nan()
  expect(1.0).not().to_be_nan()
  expect(1.0).to_be_finite()
  expect(1.0 / 0.0).not().to_be_finite()
  expect(0.0 / 0.0).not().to_be_finite()
  expect((0.0 : Float) / 0.0).to_be_nan()
  inspect(
    failure(() => expect(1.0).to_be_nan()),
    content=(
      #|expect(received).to_be_nan()
      #|Expected: NaN
      #|Received: 1.0
    ),
  )
  inspect(
    failure(() => expect(-1.0 / 0.0).to_be_finite()),
    content=(
      #|expect(received).to_be_finite()
      #|Expected: a finite number
      #|Received: -Infinity
    ),
  )
}

///|
test "to_be_close_to with relative tolerance" {
  expect(1000.0).to_be_close_to(1001.0, relative=0.01)
  expect(1.0).not().to_be_close_to(1.1, relative=0.01)
  inspect(
    failure(() => expect(100.0).to_be_close_to(110.0, relative=0.05)),
    content=(
      #|expect(received).to_be_close_to(expected, relative)
      #|Expected:            within relative tolerance 0.05 of 110.0
      #|Received:            100.0
      #|Difference:          10.0
      #|Relative difference: 0.09090909090909091
    ),
  )
}

///|
test "to_be_close_to with ULP tolerance" {
  let one = 1.0
  let next = (one.reinterpret_as_int64() + 1L).reinterpret_as_double()
  expect(next).to_be_close_to(one, ulps=1)
  expect(next).not().to_be_close_to(one, ulps=0)
  expect(0.0).to_be_close_to(-0.0, ulps=0)
  inspect(
    failure(() => expect(next).to_be_close_to(one, ulps=0)),
    content=(
      #|expect(received).to_be_close_to(expected, ulps)
      #|Expected:     within 0 ULPs of 1.0
      #|Received:     1.0000000000000002
      #|Difference:   2.220446049250313e-16
      #|ULP distance: 1
    ),
  )
}

///|
test "to_be_close_to accepts one tolerance mode" {
  inspect(
    failure(() => expect(1.0).to_be_close_to(1.0, relative=0.1, ulps=1)),
    content=(
      #|expect(received).to_be_close_to(expected, relative, ulps)
      #|Error: give only one of tolerance, relative and ulps
    ),
  )
}

///|
test "Float support" {
  let x : Float = 0.5
  expect(x).to_be_close_to(0.5000001, tolerance=0.001)
  expect(x).to_be_finite()
  inspect(
    failure(() => expect(x).to_be_close_to(1.0, tolerance=0.1)),
    content=(
      #|expect(received).to_be_close_to(expected, tolerance)
      #|Expected:   within 0.1 of 1.0
      #|Received:   0.5
      #|Difference: 0.5
    ),
  )
  let one : Float = 1.0
  let next = Float::reinterpret_from_int(one.reinterpret_as_int() + 1)
  expect(next).to_be_close_to(one, ulps=1)
}
