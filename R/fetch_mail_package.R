#' Get postage options for a package
#'
#' Supply some information about the package.
#'
#' @param origin_zip 5-digit origin zip code.
#' @param destination_zip 5-digit destination zip code.
#' @param shipping_date Date you plan to ship the package on in "MM-DD-YYYY" format as character, or "today".
#' @param shipping_time Time of day you plan to ship in 24-hour "HH:MM" format as character, or "now".
#' @param type One of: "box", "envelope".
#' @param ground_transportation_needed Does the package need to be transported by ground?
#' @param live_animals Boolean: does this contain live animals?
#' @param day_old_poultry Boolean: does this contain day-old poultry?
#' @param hazardous_materials Boolean: does this contain any hazardous materials? See: \url{https://pe.usps.com/text/pub52/pub52c3_001.htm}
#' @param pounds Number of pounds the package weighs.
#' @param ounces Number of ounces the package weighs.
#' @param length Length of the package. This is the longest dimension.
#' @param height Height of the package.
#' @param width Width of the package.
#' @param girth Girth of the package, required if \code{shape} is "nonrectangular". This is the distance around the thickest part.
#' @param shape Shape of the package: "rectangular" or "nonrectangular". "nonrectangular" reqires a non-null \code{girth} value.
#' @param show_details Non-essential details of the response are hidden by default. Show them by setting this to TRUE.
#' @param verbose Should messages, (e.g. shipping date time be dispalyed if the defaults "today" and "now" are chosen) be messageed?
#' @param ... Other arguments.
#'
#' @details Displays the result of a query to the ["Postage Price Calculator"](https://postcalc.usps.com/Calculator/). For flat rate envelopes or boxes, use \code{\link{fetch_mail_flat_rate}}.
#'
#' @importFrom magrittr %>%
#' @importFrom janitor clean_names
#'
#' @examples \dontrun{
#'
#' fetch_mail_package(origin_zip = "60647",
#'          destination_zip = "11238",
#'          pounds = 15)
#' }
#'
#' @return A tibble with information for different postage options.
#' @export

fetch_mail_package <- function(
                     origin_zip = NULL,
                     destination_zip = NULL,
                     shipping_date = "today",
                     shipping_time = "now",
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
                     verbose = TRUE, ...) {


  if(!shape %in% c("rectangular", "nonrectangular")) stop("shape must be either rectangular or nonrectangular")

  if (shape == "nonrectangular") {
    if (is.null(girth)) {stop("If shape is nonrectangular girth must be non-null.")}
  }

  if (live_animals && verbose) {
    cowsay::say("Woah Nelly!", by = "buffalo")
  }

  type <- "Package"

  resp <- get_mail(origin_zip = origin_zip,
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
                   verbose = verbose)

  out <-
    resp %>%
    clean_mail(show_details = show_details)

  return(out)
}

