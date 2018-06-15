#' Fetch zones for a 3-digit origin zip or an origin-destination pair
#'
#' For a given 3-digit origin zip code, grab all destination zips and their corresponding zones.
#'
#' @param origin_zip A single origin zip, numeric or character. If > 3 digits and contains leading zeros, make sure to supply as character.
#' @param destination_zip Optional destination zip. If not included, returns all possible desinations for the origin provided. If > 3 digits and contains leading zeros, make sure to supply as character.
#' @param as_range Do you want zones corresponding to a range of destination zips or a full listing of them?
#' @param show_modifiers Should columns pertaining to the modifiers * and + be retained?
#' @param verbose Message what's going on?
#' @param ... Other arguments
#'
#' @details \url{https://postcalc.usps.com/}
#'
#' @importFrom magrittr %>%
#'
#' @examples \dontrun{
#'
#' a_zip <- fetch_zones(123)
#' nrow(a_zip)
#'
#' fetch_zones(123, 456, show_modifiers = TRUE)
#'
#' (double_oh_seven <- fetch_zones("007", as_range = TRUE))
#' attr(double_oh_seven, "validity")}
#'
#' @return A tibble with origin zip and destination zips (in ranges or unspooled) and the USPS zones the origin-destination pair corresponds to.
#' Validity attribute lets you know whether the origin zip code is in use (see also \url{https://en.wikipedia.org/wiki/List_of_ZIP_code_prefixes})
#' @export

fetch_zones <- function(origin_zip = NULL,
                        destination_zip = NULL,
                        as_range = FALSE,
                        show_modifiers = FALSE,
                        verbose = FALSE, ...) {

  if (is.null(origin_zip)) stop("origin_zip must be non-null.")

  origin_zip <-
    origin_zip %>% prep_zip()

  if (!is.null(destination_zip)) {
    destination_zip <-
      destination_zip %>% prep_zip()
  }

  out <-
    origin_zip %>%
    get_zones(verbose = verbose)
  out %<>% sticky::sticky()

  if (as_range == FALSE) {
      out <-
        out %>%
        interpolate_zips()

      if (!is.null(destination_zip)) {
        out <-
          out %>%
          dplyr::filter(dest_zip == destination_zip)
      }

  } else {
    if (!is.null(destination_zip)) {
      out <-
        out %>%
        dplyr::filter(as.numeric(dest_zip_start) <= as.numeric(destination_zip) &
                 as.numeric(dest_zip_end) >= as.numeric(destination_zip) |
                   is.na(dest_zip_start) & is.na(dest_zip_end))  # Or we have a missing origin
    }
  }

  if (show_modifiers == FALSE) {
    out <-
      out %>%
      dplyr::select(-mail_service,
                    -same_ndc,
                    -has_five_digit_exceptions)
  }

  return(out)
}

