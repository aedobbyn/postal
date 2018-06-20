

testthat::test_that("Safely getting data works", {
  testthat::expect_null(try_get_data("foo") %>%
                          purrr::pluck("result"))

  testthat::expect_null(try_get_data(glue::glue("{three_digit_base_url}{'007'}")) %>%
                          purrr::pluck("error"))

  testthat::expect_null(try_get_data(
    glue::glue("{five_digit_base_url}?origin={'06840'}&destination={'68007'}")) %>%
      purrr::pluck("error"))

  testthat::expect_error(get_zones("foo"))
})


three_digit_base_url <- "foo"
testthat::expect_error(
  get_zones("bar")
)

three_digit_base_url <-
  "https://postcalc.usps.com/DomesticZoneChart/GetZoneChart?zipCode3Digit="

testthat::test_that("Zips are prepped correctly", {

  # Can't let user supply 4 digits as we don't know whether they mean a 5 digit zip or a 3 digit one
  testthat::expect_error(prep_zip("1234"))
  testthat::expect_error(fetch_zones("1234"))

  testthat::expect_warning(testthat::expect_equal(prep_zip("123456"), "12345"))

  testthat::expect_equal(testthat::expect_message(prepend_zeros("4",
                                                                verbose = TRUE)), "004")
  testthat::expect_equal(prepend_zeros("40"), "040")
  testthat::expect_equal(prepend_zeros("404"), "404")
  testthat::expect_equal(prepend_zeros("4040"), "04040")
})


testthat::test_that("Assignment of validity", {
  testthat::expect_message(fetch_zones("1"), "Origin zip 001 is not in use.")
  testthat::expect_equal("valid",
                         get_zones("112") %>%
                           dplyr::pull(validity) %>%
                           dplyr::first())
})


testthat::test_that("Replacement of nulls", {
  testthat::expect_equal(NA_character_, replace_x(NULL))

  has_missing <- list("foo", vector(), "baz")
  replaced <- has_missing %>% purrr::map(replace_x, "bar")
  testthat::expect_equal(replaced[[2]], "bar")
})


testthat::test_that("Interpolation of zips in between ranges", {
  testthat::expect_equal(2422,
                         get_zones("123") %>%
                           interpolate_zips() %>%
                           nrow())

  testthat::expect_equal("invalid",
                         get_zones("001") %>%
                           interpolate_zips() %>%
                           dplyr::pull("validity"))
})
