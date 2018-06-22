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



get_mail <- function(origin_zip = "60647",
                     destination_zip = "11238",
                     shipping_date = "today",
                     shipping_time = "now",
                     ground_transportation_needed = FALSE,
                     type = "FlatRateBox",
                     pounds = NULL,
                     ounces = NULL,
                     length = 0,
                     height = 0,
                     width = 0,
                     girth = NULL,
                     shape = "Rectangular") {

  if (ground_transportation_needed == FALSE) {
    ground_transportation_needed <- "False"
  } else {
    ground_transportation_needed <- "True"
  }

  if (shipping_date == "today") {
    shipping_date <-
      Sys.Date() %>% as.character()
  }

  if (shipping_time == "now") {
    shipping_time <-
      stringr::str_c(lubridate::now() %>% lubridate::hour(),
            ":",
            lubridate::now() %>% lubridate::minute())

    message(glue::glue("Using time {shipping_time}."))
  }

  shipping_date <-
    shipping_date %>%
    stringr::str_replace_all("-", "%2F")

  shipping_time <-
    shipping_time %>%
    stringr::str_replace_all(":", "%3A")


  url <- glue::glue("https://postcalc.usps.com/Calculator/GetMailServices?countryID=0&countryCode=US&origin={origin_zip}&isOrigMil=False&destination={destination_zip}&isDestMil=False&shippingDate={shipping_date}&shippingTime={shipping_time}&itemValue=&dayOldPoultry=False&groundTransportation={ground_transportation_needed}&hazmat=False&liveAnimals=False&nonnegotiableDocument=False&mailShapeAndSize={type}&pounds={pounds}&ounces={ounces}&length={length}&height={height}&width={width}&girth={girth}&shape={shape}&nonmachinable=False&isEmbedded=False")

  print(url)
  lst <- jsonlite::fromJSON(url)

  return(lst)
}

get_mail_flat_rate <-
                function(origin_zip = NULL,
                     destination_zip = NULL,
                     shipping_date = "today",
                     shipping_time = "now",
                     ground_transportation_needed = FALSE,
                     live_animals = FALSE,
                     day_old_poultry = FALSE,
                     hazardous_materials = FALSE
                     ) {

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
  shape <- NULL

  lst <- get_mail(origin_zip = origin_zip,
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

  nested <-
    lst$Page$MailServices %>%
    tibble::as_tibble() %>%
    dplyr::select(-ImageURL) %>%
    dplyr::select(-AdditionalDropOffLink)

  unnested <-
    nested %>%
    purrr::map_df(replace_x) %>%
    tidyr::unnest(DeliveryOptions) %>%
    dplyr::select(-URL)

  out <-
    unnested %>%
    janitor::clean_names()

  return(out)
}

