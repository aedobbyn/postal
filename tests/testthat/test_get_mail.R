testthat::context("Test get_mail")

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
})


testthat::test_that("get_mail()", {

  testthat::expect_is(
    get_mail(origin_zip = 60647,
             destination_zip = 11238,
             pounds = 15),
    "data.frame"
  )

})
