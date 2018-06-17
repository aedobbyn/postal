

five_digit_base_url <-
  "https://postcalc.usps.com/DomesticZoneChart/GetZone"

fetch_five_digit <- function(origin, destination) {
  url <-
    glue::glue("{five_digit_base_url}?origin={origin}&destination={destination}")

  resp <-
    jsonlite::fromJSON(url)

  if (resp$OriginError != "" |
      resp$DestinationError != "" |
      resp$PageError != "") {
    stop("Error.")
  }

  zone <-
    resp$ZoneInformation %>%
    str_extract("The Zone is [0-9]+") %>%
    str_extract("[0-9]+")

  return(zone)
}
