testthat::context("Test fetching")


testthat::test_that("Zips are prepped correctly", {
  testthat::expect_equal(prep_zip("123456"), "12345")
})


testthat::test_that("fetch_zones()", {

  testthat::expect_error(fetch_zones("foo123"))

  testthat::expect_error(fetch_zones(20))

  testthat::expect_warning(fetch_zones("9999999"))

  # # Not in use
  testthat::expect_is(fetch_zones("0"),
                       "data.frame")

  testthat::expect_is(fetch_zones("006"),
            "data.frame")

  testthat::expect_is(fetch_zones("123"),
            "data.frame")
})



testthat::test_that("Priority Mail exceptions are noted", {
  has_priority_exceptions <- fetch_five_digit("40360", "09756", show_details = TRUE)
  testthat::expect_equal("3", has_priority_exceptions$priority_mail_zone)
})



testthat::test_that("Assignment of validity", {

  testthat::expect_message(fetch_zones("1"), "Origin zip 001 is not in use.")

})
