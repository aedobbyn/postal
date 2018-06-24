#' Get postage options for a flat-rate envelope or box
#'
#' @param origin_zip 5-digit origin zip code.
#' @param destination_zip 5-digit destination zip code.
#' @param shipping_date Date you plan to ship the package on in "MM-DD-YYYY" format as character, or "today".
#' @param shipping_time Time of day you plan to ship in 24-hour "HH:MM" format as character, or "now".
#' @param type One of: "box", "envelope".
#' @param ground_transportation_needed Does the package need to be transported by ground?
#' @param show_details Non-essential details of the response are hidden by default. Show them by setting this to TRUE.
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

fetch_mail_flat_rate <- function(
                     origin_zip = NULL,
                     destination_zip = NULL,
                     shipping_date = "today",
                     shipping_time = "now",
                     type = c("rectangular", "nonrectangular"),
                     ground_transportation_needed = FALSE,
                     show_details = FALSE,
                     verbose = TRUE, ...) {

  if (is.null(type)) stop("type must be either box or envelope.")

  if (type == "envelope") {
    type <- "FlatRateEnvelope"
  } else if (type == "box") {
    type <- "FlatRateBox"
  }

  pounds <- 0
  ounces <- 0
  length <- 0
  height <- 0
  width <- 0
  girth <- 0
  shape <- 0

  resp <- get_mail(origin_zip = origin_zip,
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
                  shape = shape)

  out <-
    resp %>% clean_mail(show_details = show_details)

  return(out)
}
