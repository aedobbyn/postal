context("Test grab_zone()")

test_that("Input is correct", {
  expect_error(grab_zone_from_origin("foo"))

  expect_error(grab_zone_from_origin(-20))

  expect_error(grab_zone_from_origin(9999))

  expect_is(grab_zone_from_origin("006"),
            "data.frame")

  expect_is(grab_zone_from_origin(123),
            "data.frame")
})
