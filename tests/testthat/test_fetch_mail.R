testthat::context("Test mail fetching")

testthat::test_that("postcalc returns something", {
  test <- "https://postcalc.usps.com/Calculator/GetMailServices?countryID=0&countryCode=US&origin=60647&isOrigMil=False&destination=11238&isDestMil=False&shippingDate=6%2F22%2F2018+12%3A00%3A00+AM&shippingTime=14%3A29&itemValue=&dayOldPoultry=False&groundTransportation=False&hazmat=False&liveAnimals=False&nonnegotiableDocument=False&mailShapeAndSize=Package&pounds=15&ounces=0&length=0&height=0&width=0&girth=0&shape=Rectangular&nonmachinable=False&isEmbedded=False"

  lst <- jsonlite::fromJSON(test)

  testthat::expect_is(
    lst,
    "list"
  )
  testthat::expect_equal(
    lst$PageError,
    ""
  )

  testthat::expect_equal(
    10,
    lst$Page$MailServices %>%
      tibble::as_tibble() %>%
      dplyr::select(-ImageURL) %>%
      dplyr::select(-AdditionalDropOffLink) %>%
      purrr::map_df(replace_x) %>%
      tidyr::unnest(DeliveryOptions) %>%
      dplyr::select(-URL) %>%
      ncol()
  )

  testthat::expect_is(
    lst %>% clean_mail(),
    "data.frame"
  )
})


testthat::test_that("fetch_mail_package()", {
  testthat::expect_error(
    fetch_mail_package()
  )

  testthat::expect_error(
    fetch_mail_package("123", "456")
  )

  testthat::expect_error(
    fetch_mail_package("11238", "60647",
      shape = "neither"
    )
  )

  testthat::expect_error(
    fetch_mail_package("11238", "60647",
      shape = "rectangular",
      pounds = "foo")
  )

  testthat::expect_error(
    fetch_mail_package("11238", "60647",
       shape = "rectangular",
       shipping_date = 14
    )
  )

  testthat::expect_error(
    fetch_mail_package("11238", "60647",
       shape = "nonrectangular",
       shipping_time = 123
    )
  )

  testthat::expect_error(
    fetch_mail_package("11238", "60647",
         shape = "nonrectangular",
         live_animals = 123
    )
  )

  testthat::expect_error(
    fetch_mail_package("11238", "60647",
      shape = "nonrectangular",
      girth = 0
    )
  )

  testthat::expect_is(
    fetch_mail_package("11238", "60647",
      shape = "rectangular",
      verbose = TRUE
    ),
    "data.frame"
  )

  testthat::expect_is(
    fetch_mail_package(
      origin_zip = "60647",
      destination_zip = "11238",
      shape = "nonrectangular",
      pounds = 10,
      length = 12,
      width = 8,
      height = 4,
      girth = 7,
      live_animals = TRUE,
      verbose = TRUE
    ),
    "data.frame"
  )

  testthat::expect_is(
    fetch_mail_package(
      origin_zip = "60647",
      destination_zip = "11238",
      show_details = TRUE,
      shape = "rectangular",
      pounds = 10,
      length = 12,
      width = 8,
      height = 4
    ),
    "data.frame"
  )

  origins <- c("11238", "foo", "60647")
  destinations <- c("98109", "94707", "bar")

  much_mail_package <- purrr::map2_dfr(
    origins, destinations,
    fetch_mail_package,
    shape = "rectangular",
    pounds = 8,
    length = 7,
    width = 6,
    height = 5
  )

  testthat::expect_is(
    much_mail_package,
    "data.frame"
  )
})


testthat::test_that("fetch_mail_flat_rate()", {
  testthat::expect_error(
    fetch_mail_flat_rate()
  )

  testthat::expect_error(
    fetch_mail_flat_rate("123", "456")
  )

  testthat::expect_error(
    fetch_mail_flat_rate("11238", "60647",
      type = "neither"
    )
  )

  testthat::expect_is(
    fetch_mail_flat_rate(
      origin_zip = "60647",
      destination_zip = "11238",
      type = "envelope"
    ),
    "data.frame"
  )

  testthat::expect_is(
    fetch_mail_flat_rate(
      origin_zip = "60647",
      destination_zip = "11238",
      type = "box",
      show_details = TRUE
    ),
    "data.frame"
  )

  origins <- c("11238", "foo", "60647")
  destinations <- c("98109", "94707", "bar")

  much_mail_flat <- purrr::map2_dfr(
    origins, destinations,
    fetch_mail_flat_rate,
    type = "box"
  )

  testthat::expect_is(
    much_mail_flat,
    "data.frame"
  )
})
