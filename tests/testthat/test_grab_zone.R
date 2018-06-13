testthat::context("Test grab_zone()")

testthat::test_that("Input is correct", {
  testthat::expect_error(grab_zone_from_origin("foo"))

  testthat::expect_error(grab_zone_from_origin(-20))

  testthat::expect_error(grab_zone_from_origin(9999))

  # Not in use
  testthat::expect_is(grab_zone_from_origin(0),
                       "data.frame")

  testthat::expect_is(grab_zone_from_origin("006"),
            "data.frame")

  testthat::expect_is(grab_zone_from_origin(123),
            "data.frame")
})


testthat::test_that("Assignment of validity", {

  invalid_zip <- grab_zone_from_origin(0)
  testthat::expect_equal(attributes(invalid_zip)$validity, "invalid")

})
