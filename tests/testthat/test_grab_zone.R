context("Test grab_zone()")

test_that("Input is correct", {
  expect_error(grab_zone_from_origin("foo"))

  expect_error(grab_zone_from_origin(-20))

  expect_error(grab_zone_from_origin(9999))

  # Not in use
  grab_zone_from_origin(0)

  expect_is(grab_zone_from_origin("006"),
            "data.frame")

  expect_is(grab_zone_from_origin(123),
            "data.frame")
})

test_that("Assignment of validity", {

  invalid_zip <- grab_zone_from_origin(0)
  expect_equal(attributes(invalid_zip)$validity == "invalid")

})
