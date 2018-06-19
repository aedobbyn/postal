testthat::context("Test fetching")


testthat::test_that("fetch_zones()", {
  testthat::expect_error(fetch_zones("foo123"))

  testthat::expect_error(fetch_zones(20))

  testthat::expect_warning(fetch_zones("9999999"))

  # # Not in use
  testthat::expect_is(
    fetch_zones("0"),
    "data.frame"
  )

  testthat::expect_is(
    fetch_zones("006"),
    "data.frame"
  )

  testthat::expect_is(
    fetch_zones("123"),
    "data.frame"
  )
})


testthat::test_that("Five digit fetch", {
  testthat::expect_equal(1, fetch_five_digit("60647", "11238") %>% nrow())
  testthat::expect_error(fetch_five_digit("86753", "11238"))
  testthat::expect_error(fetch_five_digit("123", "456"))
})


testthat::test_that("Priority Mail exceptions are noted", {
  has_priority_exceptions <- fetch_five_digit("40360", "09756", show_details = TRUE)
  testthat::expect_equal("3", has_priority_exceptions$priority_mail_zone)
})


testthat::test_that("3 and 5 digit endpoints agree", {
  origins <- c("11238", "60647", "80205")
  destinations <- c("98109", "02210", "94707")

  three_d <- purrr::map2_dfr(
    origins, destinations,
    fetch_zones
  )

  five_d <- purrr::map2_dfr(
    origins, destinations,
    fetch_five_digit
  )

  testthat::expect_equal(three_d$zone, five_d$zone)
})


testthat::test_that("We can grab all origins", {
  testthat::expect_is(
    fetch_all(sample(all_possible_origins, 2)),
    "data.frame"
  )
})



