#' Get postage options for a package
#'
#' Supply some information about the package.
#'
#' @param origin_zip A single origin zip as character. If > 3 digits and contains leading zeros, make sure to supply as character.
#' @param destination_zip Optional destination zip. If not included, returns all possible destinations for the origin provided. If > 3 digits and contains leading zeros, make sure to supply as character.
#' @param shipping_date Date you plan to ship the package on.
#' @param shipping_time Time of day you plan to ship.
#' @param ground_transportation_needed Does the package need to be transported by ground?
#' @param pounds Number of pounds the package weighs.
#' @param ounces Number of ounces the package weighs.
#' @param length Length of the package.
#' @param height Height of the package.
#' @param width Width of the package.
#' @param girth Girth of the package.
#' @param shape Shape of the package.
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

get_mail <- function(origin_zip = NULL,
                     destination_zip = NULL,
                     shipping_date = "6-22-2018",
                     shipping_time = "14:29",
                     ground_transportation_needed = FALSE,
                     pounds = 0,
                     ounces = 0,
                     length = 0,
                     height = 0,
                     width = 0,
                     girth = 0,
                     shape = "Rectangular") {

  if (ground_transportation_needed == FALSE) {
    ground_transportation_needed <- "False"
  } else {
    ground_transportation_needed <- "True"
  }

  shipping_date <-
    shipping_date %>%
    str_replace_all("-", "%2F")

  shipping_time <-
    shipping_time %>%
    str_replace_all(":", "%3A")

url <- glue::glue("https://postcalc.usps.com/Calculator/GetMailServices?countryID=0&countryCode=US&origin={origin_zip}&isOrigMil=False&destination={destination_zip}&isDestMil=False&shippingDate={shipping_date}&shippingTime={shipping_time}&itemValue=&dayOldPoultry=False&groundTransportation={ground_transportation}&hazmat=False&liveAnimals=False&nonnegotiableDocument=False&mailShapeAndSize=Package&pounds={pounds}&ounces={ounces}&length={length}&height={height}&width={width}&girth={girth}&shape={shape}&nonmachinable=False&isEmbedded=False")

  lst <- jsonlite::fromJSON(url)

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

