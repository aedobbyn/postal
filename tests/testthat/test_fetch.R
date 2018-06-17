testthat::context("Test fetch_zones()")

testthat::test_that("Input is correct", {
  testthat::expect_equal(prep_zip("123456"), "12345")

  testthat::expect_error(fetch_zones("foo"))

  testthat::expect_error(fetch_zones(20))

  testthat::expect_warning(fetch_zones("9999999"))

  # Not in use
  testthat::expect_is(fetch_zones("0"),
                       "data.frame")

  testthat::expect_is(fetch_zones("006"),
            "data.frame")

  testthat::expect_is(fetch_zones("123"),
            "data.frame")
})


testthat::test_that("Assignment of validity", {

  invalid_zip <- fetch_zones("1", show_details = TRUE)
  testthat::expect_equal(invalid_zip$validity, "invalid")

})
