#' Get postage options for a package
#'
#' Supply some information about the package.
#'
#' @param origin_zip A single origin zip as character. If > 3 digits and contains leading zeros, make sure to supply as character.
#' @param destination_zip Optional destination zip. If not included, returns all possible destinations for the origin provided. If > 3 digits and contains leading zeros, make sure to supply as character.
#' @param shipping_date Date you plan to ship the package on in "MM-DD-YYY" format as character, or "today".
#' @param shipping_time Time of day you plan to ship in "HH:MM" form, or "now".
#' @param ground_transportation_needed Does the package need to be transported by ground?
#' @param type One of: "box", "envelope".
#' @param pounds Number of pounds the package weighs.
#' @param ounces Number of ounces the package weighs.
#' @param length Length of the package. This is the longest dimension.
#' @param height Height of the package.
#' @param width Width of the package.
#' @param girth Girth of the package, required if \code{shape} is "Nonrectangular". This is the distance around the thickest part.
#' @param shape Shape of the package: "Rectangular" or "Nonrectangular". "Nonrectangular" reqires a non-null \code{girth} value.
#'
#' @details Displays the result of a query to the ["Postage Price Calculator"](https://postcalc.usps.com/Calculator/).
#'
#' @importFrom magrittr %>%
#' @importFrom janitor clean_names
#'
#' @examples \dontrun{
#'
#' get_mail(origin_zip = 60647,
#'          destination_zip = 11238,
#'          pounds = 15)
#' }
#'
#' @return A tibble with information for different postage options.
#' @export
#'


fetch_mail_flat_rate <-
                function(origin_zip = NULL,
                     destination_zip = NULL,
                     shipping_date = "today",
                     shipping_time = "now",
                     type = "box",
                     ground_transportation_needed = FALSE,
                     show_details = FALSE,
                     verbose = TRUE, ...) {

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
