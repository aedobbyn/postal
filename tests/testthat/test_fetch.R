testthat::context("Test fetching")


testthat::test_that("Safely getting data works", {
  testthat::expect_null(try_get_data("foo") %>%
                           purrr::pluck("result"))
  testthat::expect_null(try_get_data(glue::glue("{three_digit_base_url}{'007'}")) %>%
                          purrr::pluck("error"))
  testthat::expect_null(try_get_data(
    glue::glue("{five_digit_base_url}?origin={'06840'}&destination={'68007'}")) %>%
                          purrr::pluck("error"))
})


testthat::test_that("Zips are prepped correctly", {
  testthat::expect_warning(testthat::expect_equal(prep_zip("123456"), "12345"))
})


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


testthat::test_that("Assignment of validity", {
  testthat::expect_message(fetch_zones("1"), "Origin zip 001 is not in use.")
  testthat::expect_equal("valid",
                         get_zones("112") %>%
                           dplyr::pull(validity) %>%
                           dplyr::first())
})


testthat::test_that("Interpolation of zips in between ranges", {
  testthat::expect_equal(2422,
                         get_zones("123") %>%
                           interpolate_zips() %>%
                           nrow())
})


testthat::test_that("Priority Mail exceptions are noted", {
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
