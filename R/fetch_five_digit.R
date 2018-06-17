#' Fetch zones for a 5-digit origin origin-destination pair
#'
#' For a given 5-digit origin and destination zip code pair, display the zone number and full response.
#'
#' @param origin_zip A single origin zip as 5-digit character.
#' @param destination_zip Optional destination zip as 5-digit character.
#' @param ... Other arguments
#'
#' @details Displays the result of a query to the ["Get Zone for ZIP Code Pair"](https://postcalc.usps.com/DomesticZoneChart/) tab.
#'
#' @importFrom magrittr %>%
#'
#' @examples \dontrun{
#'
#' fetch_five_digit("90210", "20500")
#'
#' @return A tibble with origin zip and destination zips (in ranges or unspooled) and the USPS zones the origin-destination pair corresponds to.
#' @export

fetch_five_digit <- function(origin_zip, destination_zip, ...) {

  origin_zip <-
    origin_zip %>% prep_zip()

  destination_zip <-
    destination_zip %>% prep_zip()

  url <-
    glue::glue("{five_digit_base_url}?origin={origin_zip}&destination={destination_zip}")

  resp <-
    jsonlite::fromJSON(url)

  if (resp$OriginError != "") stop("Error relating to origin zip.")
  if (resp$DestinationError != "") stop("Error relating to destination zip.")
  if (resp$DestinationError != "") stop("No Zones found for the entered ZIP codes.")

  zone <-
    resp$ZoneInformation %>%
    str_extract("The Zone is [0-9]+") %>%
    str_extract("[0-9]+")

  full_response <-
    resp$ZoneInformation

  out <-
    tibble::tibble(
      origin_zip = origin_zip,
      destination_zip = destination_zip,
      zone = zone,
      full_response = full_response
    )

  return(out)
}
