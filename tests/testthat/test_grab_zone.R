testthat::context("Test fetch_zones()")

testthat::test_that("Input is correct", {
  testthat::expect_equal(prep_zip(123456), "123")

  testthat::expect_error(fetch_zones("foo"))

  testthat::expect_error(fetch_zones(-20))

  testthat::expect_warning(fetch_zones(9999))

  # Not in use
  testthat::expect_is(fetch_zones(0),
                       "data.frame")

  testthat::expect_is(fetch_zones("006"),
            "data.frame")

  testthat::expect_is(fetch_zones(123),
            "data.frame")
})


# testthat::test_that("Assignment of validity", {
#
#   invalid_zip <- fetch_zones(0)
#   testthat::expect_equal(attributes(invalid_zip)$validity, "invalid")
#
# })
