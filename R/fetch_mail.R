#' Get postage options for a package or flat-rate envelope/box
#'
#' @param origin_zip 5-digit origin zip code.
#' @param destination_zip 5-digit destination zip code.
#' @param shipping_date Date you plan to ship the package on in "MM-DD-YYYY" format as character, or "today".
#' @param shipping_time Time of day you plan to ship in 24-hour "HH:MM" format as character, or "now".
#' @param type One of: "box", "envelope", "package". The types "box" and "envelope" can be supplied for flat-rate boxes and envelopes.
#' @param ground_transportation_needed Does the package need to be transported by ground?
#' @param live_animals Boolean: does this contain live animals? See: \url{https://pe.usps.com/text/pub52/pub52c5_003.htm}
#' @param day_old_poultry Boolean: does this contain day-old poultry? See: \url{https://pe.usps.com/text/pub52/pub52c5_008.htm#ep184002}
#' @param hazardous_materials Boolean: does this contain any hazardous materials? See: \url{https://pe.usps.com/text/pub52/pub52c3_001.htm}
#' @param pounds Number of pounds the package weighs.
#' @param ounces Number of ounces the package weighs.
#' @param length Length of the package in inches. This is the longest dimension.
#' @param height Height of the package in inches.
#' @param width Width of the package in inches.
#' @param girth Girth of the package in inches, required if \code{shape} is "nonrectangular". This is the distance around the thickest part.
#' @param shape Shape of the package: "rectangular" or "nonrectangular". "nonrectangular" reqires a non-null \code{girth} value.
#' If \code{type} is box or envelope, \code{shape} will always be "rectangular".
#' @param show_details Non-essential details of the response are hidden by default. Show them by setting this to TRUE.
#' @param n_tries How many times to try the API if at first we don't succeed?
#' @param verbose Should messages, (e.g. shipping date time be dispalyed if the defaults "today" and "now" are chosen) be messageed?
#'
#' @details Supply the required information about the package and receive a tibble. Displays the result of a query to the  \href{https://postcalc.usps.com/Calculator/}{"Postage Price Calculator"} in dataframe format.
#'
#' The result can be further cleaned and stardardized by piping the result to \link{\code{scrub_mail}}.
#'
#' The API is tried \code{n_tries} times until a tibble is returned with \code{no_success} in columns that could not be returned. This indicates either that the connection was interrupted during the request or that one or more of the arguments supplied were malformed.
#'
#' If a response is successfully recieved but there are no shipping options, the columns are filled with \code{NA}s.
#'
#'
#' @seealso scrub_mail
#'
#' @importFrom magrittr %>%
#'
#' @examples \dontrun{
#'
#' fetch_mail(origin_zip = "90210",
#'          destination_zip = "59001",
#'          type = "envelope")
#'
#'
#' fetch_mail(origin_zip = "68003",
#'          destination_zip = "23285",
#'          pounds = 4,
#'          ground_transportation_needed = TRUE,
#'          type = "package",
#'          shape = "rectangular",
#'          show_details = TRUE)
#'
#' origins <- c("90210", "foobar", "59001")  # Contains an invalid zip
#' destinations <- c("68003", "94707", "23285")
#'
#' purrr::map2_dfr(
#'   origins, destinations,
#'   fetch_mail,
#'   type = "package"
#' )
#'
#'
#'
#' }
#'
#' @return A tibble with information for different postage options, including price and box/envelope dimensions.
#' @export
#'

fetch_mail <- function(origin_zip = NULL,
                                 destination_zip = NULL,
                                 shipping_date = "today",
                                 shipping_time = "now",
                                 type = "package",
                                 ground_transportation_needed = FALSE,
                                 live_animals = FALSE,
                                 day_old_poultry = FALSE,
                                 hazardous_materials = FALSE,
                                 pounds = 0,
                                 ounces = 0,
                                 length = 0,
                                 height = 0,
                                 width = 0,
                                 girth = 0,
                                 shape = "rectangular",
                                 show_details = FALSE,
                                 n_tries = 3,
                                 verbose = TRUE) {

  if (is.null(type) | length(type) > 1) {
    stop("type must be envelope, box, or package")
  }

  if (type == "envelope") {
    type <- "FlatRateEnvelope"
    shape <- "rectangular"
  } else if (type == "box") {
    type <- "FlatRateBox"
    shape <- "rectangular"
  } else if (type == "package") {
    type <- "Package"
    if (length(shape) > 1 |
        !shape %in% c("rectangular", "nonrectangular")) {
      stop("If type is package, shape must be either rectangular or nonrectangular")
    }
    if (shape == "nonrectangular") {
      if (is.null(girth) | girth == 0) {
        stop("If shape is nonrectangular, girth must be > 0.")
      }
    }
  } else {
    stop("type must be envelope, box, or package")
  }

  out <-
    process_mail(
      origin_zip = origin_zip,
      destination_zip = destination_zip,
      shipping_date = shipping_date,
      shipping_time = shipping_time,
      type = type,
      ground_transportation_needed = ground_transportation_needed,
      live_animals = live_animals,
      day_old_poultry = day_old_poultry,
      hazardous_materials = hazardous_materials,
      pounds = pounds,
      ounces = ounces,
      length = length,
      height = height,
      width = width,
      girth = girth,
      shape = shape,
      show_details = show_details,
      n_tries = n_tries,
      verbose = verbose
    )

  return(out)
}
