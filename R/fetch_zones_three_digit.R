#' Fetch zones for a 3-digit origin zip or an origin-destination pair
#'
#' For a given 3-digit origin zip code, grab all destination zips and their corresponding zones.
#'
#' @param origin_zip A single origin zip as character. If > 3 digits and contains leading zeros, make sure to supply as character.
#' @param destination_zip Optional destination zip. If not included, returns all possible destinations for the origin provided. If > 3 digits and contains leading zeros, make sure to supply as character.
#' @param exact_destination If \code{destination_zip} is supplied, should the result be filtered to the full destination zip, or its first 3 digits?
#' @param as_range Do you want zones corresponding to a range of destination zips or a full listing of them?
#' @param show_details Should columns with more details be retained?
#' @param n_tries How many times to try getting an origin if we're unsuccessful the first time?
#' @param verbose Message what's going on?
#' @param ... Other arguments
#'
#' @details Displays the result of a query to the ["Get Zone Chart"](https://postcalc.usps.com/DomesticZoneChart/) tab. If you just want to supply two 5-digit zips and get a single zone back, use \code{\link{fetch_zones_five_digit}}.
#'
#' @importFrom magrittr %>%
#'
#' @examples \dontrun{
#'
#' a_zip <- fetch_zones_three_digit("123")
#' nrow(a_zip)
#'
#' fetch_zones_three_digit("123", "456", show_details = TRUE)
#'
#' (double_oh_seven <- fetch_zones_three_digit("007", as_range = TRUE))
#' }
#'
#' @return A tibble with origin zip and destination zips (in ranges or unspooled) and the USPS zones the origin-destination pair corresponds to.
#' @export

fetch_zones_three_digit <-
  function(origin_zip = NULL,
             destination_zip = NULL,
             exact_destination = FALSE,
             as_range = FALSE,
             show_details = FALSE,
             n_tries = 3,
             verbose = FALSE, ...) {
    if (length(origin_zip) < 0 | is.null(origin_zip) | is.na(origin_zip)) {
      stop("origin_zip cannot be missing.")
    }

    origin_zip <-
      origin_zip %>%
      prep_zip(verbose = verbose)

    if (nchar(origin_zip) > 3 & verbose) {
      message(glue::glue("Only 3-character origin zips can be \\
                       sent to the API. Zip {origin_zip} will \\
                       be requested as {substr(origin_zip, 1, 3)}."))
    }

    origin_zip <-
      origin_zip %>%
      substr(1, 3)

    if (!is.null(destination_zip)) {
      destination_zip <-
        destination_zip %>%
        prep_zip(verbose = verbose)

      destination_zip_trim <-
        destination_zip %>%
        substr(1, 3)
    }

    out <-
      origin_zip %>%
      get_zones(verbose = verbose, n_tries = n_tries)

    if (as_range == FALSE) {
      out <-
        out %>%
        interpolate_zips() %>%
        dplyr::select(
          origin_zip, dest_zip, zone,
          specific_to_priority_mail, same_ndc, has_five_digit_exceptions
        ) %>%
        dplyr::arrange(dest_zip)

      if (!is.null(destination_zip)) {
        out <-
          out %>%
          dplyr::filter(dest_zip == destination_zip |
            dest_zip == destination_zip_trim |
            is.na(dest_zip))

        if (exact_destination == TRUE) {
          out <-
            out %>%
            dplyr::filter(dest_zip == destination_zip |
              is.na(dest_zip))
        }
        if (nrow(out) == 0 & verbose) {
          message(glue::glue("No zones found for the \\
                           {origin_zip} to {destination_zip} pair."))
        }
      }
    } else {
      if (!is.null(destination_zip)) {
        out <-
          out %>%
          dplyr::filter(
            as.numeric(dest_zip_start) <= as.numeric(destination_zip) &
              as.numeric(dest_zip_end) >= as.numeric(destination_zip) |
              is.na(dest_zip_start) & is.na(dest_zip_end) # Or our origin isn't in use
          ) %>%
          dplyr::select(
            origin_zip, dest_zip_start, dest_zip_end, zone,
            specific_to_priority_mail, same_ndc, has_five_digit_exceptions
          )
      }
    }

    if (show_details == FALSE) {
      out <-
        out %>%
        dplyr::select(
          -specific_to_priority_mail,
          -same_ndc,
          -has_five_digit_exceptions
        )
    } else {
      out <-
        out %>%
        dplyr::select(
          dplyr::everything(),
          specific_to_priority_mail, same_ndc, has_five_digit_exceptions
        )
    }

    return(out)
  }



#' Fetch zones for a 3-digit origin zip or an origin-destination pair
#'
#' For a given 3-digit origin zip code, grab all destination zips and their corresponding zones.
#'
#' @param origin_zip A single origin zip as character. If > 3 digits and contains leading zeros, make sure to supply as character.
#' @param destination_zip Optional destination zip. If not included, returns all possible destinations for the origin provided. If > 3 digits and contains leading zeros, make sure to supply as character.
#' @param exact_destination If \code{destination_zip} is supplied, should the result be filtered to the full destination zip, or its first 3 digits?
#' @param as_range Do you want zones corresponding to a range of destination zips or a full listing of them?
#' @param show_details Should columns with more details be retained?
#' @param n_tries How many times to try getting an origin if we're unsuccessful the first time?
#' @param verbose Message what's going on?
#' @param ... Other arguments
#'
#' @details Displays the result of a query to the ["Get Zone Chart"](https://postcalc.usps.com/DomesticZoneChart/) tab. If you just want to supply two 5-digit zips and get a single zone back, use \code{\link{fetch_zones_five_digit}}.
#'
#' @importFrom magrittr %>%
#'
#' @examples \dontrun{
#'
#' a_zip <- fetch_zones_three_digit("123")
#' nrow(a_zip)
#'
#' fetch_zones_three_digit("123", "456", show_details = TRUE)
#'
#' (double_oh_seven <- fetch_zones_three_digit("007", as_range = TRUE))
#' }
#'
#' @return A tibble with origin zip and destination zips (in ranges or unspooled) and the USPS zones the origin-destination pair corresponds to.
#' @export
fetch_zones <- fetch_zones_three_digit
