#' Fetch zones for a 5-digit origin origin-destination pair
#'
#' For a given 5-digit origin and destination zip code pair, display the zone number and full response.
#'
#' @param origin_zip A single origin zip as 5-digit character.
#' @param destination_zip Required destination zip as 5-digit character.
#' @param show_details Extract extra stuff from the response?
#' @param n_tries How many times to try the API if at first we don't succeed?
#' @param verbose Message what's going on?
#' @param ... Other arguments
#'
#' @details Displays the result of a query to the ["Get Zone for ZIP Code Pair"](https://postcalc.usps.com/DomesticZoneChart/) tab.
#'
#' If you want all destinations for a given origin, use \code{\link{fetch_zones}} with the first 3 digits of the origin; there you don't need to supply a destination.
#'
#' @importFrom magrittr %>%
#' @importFrom stats runif
#'
#' @examples \dontrun{
#' fetch_five_digit("90210", "20500")
#'
#' fetch_five_digit("40360", "09756", show_details = TRUE)
#'
#' purrr::map2_dfr(c("11238", "60647", "80205"),
#'                 c("98109", "02210", "94707"),
#'       fetch_five_digit)
#' }
#'
#' @return A tibble with origin zip and destination zips (in ranges or unspooled) and the USPS zones the origin-destination pair corresponds to.
#' @export

fetch_five_digit <- function(origin_zip, destination_zip,
                             n_tries = 3,
                             show_details = FALSE,
                             verbose = FALSE, ...) {
  origin_zip <-
    origin_zip %>%
    prep_zip(verbose = verbose)

  destination_zip <-
    destination_zip %>%
    prep_zip(verbose = verbose)

  url <-
    glue::glue("{five_digit_base_url}?\\
               origin={origin_zip}&\\
               destination={destination_zip}")

  resp_full <-
    try_n_times(url, n_tries = n_tries)

  if (!is.null(resp_full$error)) {
    no_success <-
      tibble::tibble(
        origin_zip = origin_zip,
        dest_zip = destination_zip,
        zone = "no_success",
        specific_to_priority_mail = NA,
        local = NA,
        same_ndc = NA,
        full_response = NA
      )

    if (show_details == FALSE) {
      no_success <-
        no_success %>%
        dplyr::select(origin_zip, dest_zip, zone)
    }

    message(glue::glue("Unsuccessful grabbing data for \\
                       origin {origin_zip} and \\
                       destination {destination_zip}."))

    return(no_success)
  }

  resp <- resp_full$result

  if (resp$OriginError != "") stop("Invalid origin zip.")
  if (resp$DestinationError != "") stop("Invalid destination zip.")

  zone <-
    resp$ZoneInformation %>%
    stringr::str_extract("The Zone is [0-9]") %>%
    stringr::str_extract("[0-9]+")

  full_response <-
    resp$ZoneInformation

  out <-
    tibble::tibble(
      origin_zip = origin_zip,
      dest_zip = destination_zip,
      zone = zone,
      specific_to_priority_mail = NA, # Default to NA
      full_response = full_response
    ) %>%
    dplyr::mutate(
      specific_to_priority_mail = full_response %>%
        stringr::str_extract(
          "except for Priority Mail services where the Zone is [0-9]"
        ) %>%
        stringr::str_extract("[0-9]")
    )

  if (show_details == TRUE) {
    out <- out %>%
      dplyr::mutate(
        local = ifelse(
          stringr::str_detect(
            full_response, "This is not a Local Zone"
          ),
          FALSE, TRUE
        ),

        same_ndc = ifelse(
          stringr::str_detect(
            full_response, "The destination ZIP Code is not \\
            within the same NDC as the origin ZIP Code"
          ),
          FALSE, TRUE
        ),
      ) %>%
      dplyr::select(origin_zip, dest_zip, zone, specific_to_priority_mail, local, same_ndc, full_response)
  } else {
    out <- out %>%
      dplyr::select(origin_zip, dest_zip, zone)
  }

  return(out)
}
