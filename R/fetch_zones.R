#' Fetch zones for a 3-digit origin zip or an origin-destination pair
#'
#' For a given 3-digit origin zip code, grab all destination zips and their corresponding zones.
#'
#' @param origin_zip A single origin zip as character. If > 3 digits and contains leading zeros, make sure to supply as character.
#' @param destination_zip Optional destination zip. If not included, returns all possible desinations for the origin provided. If > 3 digits and contains leading zeros, make sure to supply as character.
#' @param as_range Do you want zones corresponding to a range of destination zips or a full listing of them?
#' @param show_details Should columns with more details be retained?
#' @param verbose Message what's going on?
#' @param ... Other arguments
#'
#' @details The result of a call to \url{https://postcalc.usps.com/DomesticZoneChart/GetZoneChart?zipCode3Digit=}.
#'
#'
#' @importFrom magrittr %>%
#'
#' @examples \dontrun{
#'
#' a_zip <- fetch_zones(123)
#' nrow(a_zip)
#'
#' fetch_zones(123, 456, show_details = TRUE)
#'
#' (double_oh_seven <- fetch_zones("007", as_range = TRUE))
#' attr(double_oh_seven, "validity")}
#'
#' @return A tibble with origin zip and destination zips (in ranges or unspooled) and the USPS zones the origin-destination pair corresponds to.
#' Validity attribute lets you know whether the origin zip code is in use (see also \url{https://en.wikipedia.org/wiki/List_of_ZIP_code_prefixes}).
#' @export

fetch_zones <- function(origin_zip = NULL,
                        destination_zip = NULL,
                        as_range = FALSE,
                        show_details = FALSE,
                        verbose = FALSE, ...) {

  if (is.null(origin_zip) | is.na((origin_zip))) stop("origin_zip cannot be missing.")

  destination_zip_original <- destination_zip

  origin_zip <-
    origin_zip %>% prep_zip(verbose = verbose)

  if (!is.null(destination_zip)) {
    destination_zip <-
      destination_zip %>% prep_zip(verbose = verbose)
  }

  out <-
    substr(origin_zip, 1, 3) %>%   # We trimmed to first 5, but only send first 3
    get_zones(verbose = verbose)

  out %<>% sticky::sticky()

  if (as_range == FALSE) {
    out <-
      out %>%
      sticky::sticky() %>%
      interpolate_zips() %>%
      sticky::sticky() %>%
      dplyr::select(origin_zip, dest_zip, zone, validity, specific_to_priority_mail, same_ndc, has_five_digit_exceptions)

    if (!is.null(destination_zip)) {
      out <-
        out %>%
        sticky::sticky() %>%
        dplyr::filter(dest_zip == destination_zip)
    }

  } else {
    if (!is.null(destination_zip)) {
      out <-
        out %>%
        dplyr::filter(as.numeric(dest_zip_start) <= as.numeric(destination_zip) &
                 as.numeric(dest_zip_end) >= as.numeric(destination_zip) |
                   is.na(dest_zip_start) & is.na(dest_zip_end)) %>%   # Or we have a missing origin
        dplyr::select(origin_zip, dest_zip_start, dest_zip_end, zone, specific_to_priority_mail, same_ndc, has_five_digit_exceptions)
    }
  }

  out %<>% sticky::sticky()

  if (show_details == FALSE) {
    out <-
      out %>%
      sticky::sticky() %>%
      dplyr::select(-validity,
                    -specific_to_priority_mail,
                    -same_ndc,
                    -has_five_digit_exceptions)
  } else {
    out <-
      out %>%
      sticky::sticky() %>%
      dplyr::select(dplyr::everything(), specific_to_priority_mail, same_ndc, has_five_digit_exceptions)
  }

  return(out)
}

