///|
test "parse_location" {
  @expect.expect(parse_location("src/a_test.mbt:4:30-5:2@me/app")).to_equal(
    Some(("src/a_test.mbt", 4, 30, 5, 2)),
  )
  @expect.expect(parse_location("C:/code/a.mbt:1:2-1:5@me/app")).to_equal(
    Some(("C:/code/a.mbt", 1, 2, 1, 5)),
  )
  @expect.expect(parse_location("nonsense")).to_be_none()
}

///|
test "source_text falls back to an empty string" {
  @expect.expect(source_text("src/missing_file.mbt:1:1-1:5@me/app")).to_equal(
    "",
  )
  @expect.expect(source_text("nonsense")).to_equal("")
  // A location past the end of the file.
  @expect.expect(source_text("src/with_source/moon.pkg:999:1-999:5@me/app")).to_equal(
    "",
  )
}
