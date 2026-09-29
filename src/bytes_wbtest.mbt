///|
test "Bytes show as a hex dump" {
  inspect(
    failure(() => expect(b"hello").to_have_length(3)),
    content=(
      #|expect(received).to_have_length(expected)
      #|Expected: length 3
      #|Received: 00000000  68 65 6c 6c 6f                                    |hello|
      #|Length:   5
    ),
  )
}

///|
test "to_equal on Bytes shows the first differing offset" {
  let expected = Bytes::from_array(FixedArray::makei(20, i => i.to_byte()))
  let actual = Bytes::from_array(
    FixedArray::makei(20, i => if i == 17 { b'\xff' } else { i.to_byte() }),
  )
  inspect(
    failure(() => expect(actual).to_equal(expected)),
    content=(
      #|expect(received).to_equal(expected)
      #|Expected:
      #|  00000000  00 01 02 03 04 05 06 07  08 09 0a 0b 0c 0d 0e 0f  |................|
      #|  00000010  10 11 12 13                                       |....|
      #|Received:
      #|  00000000  00 01 02 03 04 05 06 07  08 09 0a 0b 0c 0d 0e 0f  |................|
      #|  00000010  10 ff 12 13                                       |....|
      #|Difference: offset 17 (0x11): expected 0x11, received 0xff
    ),
  )
  inspect(
    failure(() => expect(b"ab").to_equal(b"abc")),
    content=(
      #|expect(received).to_equal(expected)
      #|Expected:   00000000  61 62 63                                          |abc|
      #|Received:   00000000  61 62                                             |ab|
      #|Difference: offset 2 (0x02): expected 0x63, received nothing
    ),
  )
}
