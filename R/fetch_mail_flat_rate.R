#' Get postage options for a flat-rate envelope or box
#'
#' @param origin_zip 5-digit origin zip code.
#' @param destination_zip 5-digit destination zip code.
#' @param shipping_date Date you plan to ship the package on in "MM-DD-YYYY" format as character, or "today".
#' @param shipping_time Time of day you plan to ship in 24-hour "HH:MM" format as character, or "now".
#' @param type One of: "box", "envelope".
#' @param ground_transportation_needed Does the package need to be transported by ground?
#' @param show_details Non-essential details of the response are hidden by default. Show them by setting this to TRUE.
#' @param n_tries How many times to try the API if at first we don't succeed?
#' @param verbose Should messages, (e.g. shipping date time be dispalyed if the defaults "today" and "now" are chosen) be messageed?
#' @param ... Other arguments.
#'
#' @details Supply the required information about the package and receive a tibble. Displays the result of a query to the ["Postage Price Calculator"](https://postcalc.usps.com/Calculator/). For non-flat-rate packages, use \code{\link{fetch_mail_package}}.
#'
#' @importFrom magrittr %>%
#' @importFrom janitor clean_names
#'
#' @examples \dontrun{
#'
#' fetch_mail_flat_rate(origin_zip = "60647",
#'          destination_zip = "11238", type = "envelope")
#' }
#'
#' @return A tibble with information for different postage options, including price and box/envelope dimensions.
#' @export
#'

fetch_mail_flat_rate <- function(origin_zip = NULL,
                                 destination_zip = NULL,
                                 shipping_date = "today",
                                 shipping_time = "now",
                                 type = c("envelope", "box"),
                                 ground_transportation_needed = FALSE,
                                 show_details = FALSE,
                                 n_tries = 3,
                                 verbose = TRUE, ...) {
  if (length(type) > 1) stop("type must be either envelope or box")

  if (type == "envelope") {
    type <- "FlatRateEnvelope"
  } else if (type == "box") {
    type <- "FlatRateBox"
    shape <- "Rectangular"
  }

  pounds <- ounces <- length <- height <- width <- girth <- 0
  shape <- "Rectangular"

  resp <- get_mail(
    origin_zip = origin_zip,
    destination_zip = destination_zip,
    shipping_date = shipping_date,
    shipping_time = shipping_time,
    type = type,
    ground_transportation_needed = ground_transportation_needed,
    pounds = pounds,
    ounces = ounces,
    length = length,
    height = height,
    width = width,
    girth = girth,
    shape = shape,
    n_tries = n_tries
  )

  if (!is.null(resp$error)) {
    no_success <-
      tibble::tibble(
        origin_zip = origin_zip,
        dest_zip = destination_zip,
        title = "no_success",
        delivery_day = "no_success",
        retail_price = "no_success",
        click_n_ship_price = "no_success",
        dimensions = "no_success",
        delivery_option = "no_success"
      )

    if (show_details == FALSE) {
      no_success <-
        no_success %>%
        dplyr::select(-delivery_option)
    }

    message(glue::glue("Unsuccessful grabbing data for the supplied arguments."))
    return(no_success)
  } else {
    out <- resp$result
  }

  out <-
    out %>%
    clean_mail(show_details = show_details) %>%
    dplyr::mutate(
      origin_zip = origin_zip,
      dest_zip = destination_zip
    ) %>%
    dplyr::select(
      origin_zip, dest_zip,
      dplyr::everything()
    )

  return(out)
}
