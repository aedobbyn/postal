#' Grab destination zones
#'
#' For a given 3-digit origin zip code, grab all destination zips and their corresponding zones.
#'
#' @param origin_zip A single origin zip, numeric or character
#' @param as_range Do you want zones corresponding to a range of destination zips or a full listing of them?
#' @param show_modifiers Should columns pertaining to the modifiers * and + be retained?
#' @param verbose Message what's going on?
#' @param ... Other arguments
#'
#' @details \url{https://postcalc.usps.com/}
#'
#'
#' @examples \dontrun{
#'
#' a_zip <- grab_zone_from_origin(123)
#' nrow(a_zip)
#'
#' (double_oh_seven <- grab_zone_from_origin("007, as_range = TRUE))
#' attr(double_oh_seven, "validity")}
#'
#' @return A tibble with origin zip and destination zips (in ranges or unspooled) and the USPS zones the origin-destination pair corresponds to.
#' Validity attribute lets you know whether the origin zip code is in use (see also \url{https://en.wikipedia.org/wiki/List_of_ZIP_code_prefixes})
#' @import tidyverse
#' @export

grab_zone_from_origin <- function(origin_zip, as_range = FALSE, show_modifiers = FALSE,
                     verbose = TRUE, ...) {

  if (str_detect(origin_zip, "[^0-9]")) {
    stop("Invalid origin_zip; only numeric characters are allowed.")
  }

  if (nchar(origin_zip) > 3) {
    stop("origin_zip can be at most 3 characters.")
  }

  if (!is.numeric(origin_zip)) {
    origin_zip <- origin_zip %>% as.numeric()
    if (is.na(origin_zip) | origin_zip < 0) {
      stop("Invalid origin_zip.")
    }
  }

  origin_zip <- origin_zip %>%
    prepend_zeros()

  out <-
    origin_zip %>%
    get_zones(verbose = verbose,
              sleep_time = sleep_time)

  if (attributes(out)$validity == "valid") {
    if (as_range == FALSE) {
      out <-
        out %>%
        interpolate_zips()
    }
  }

  if (show_modifiers == FALSE) {
    out <-
      out %>%
      select(-starts_with("modifier"))
  }

  return(out)
}
