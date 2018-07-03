#' Fetch postage details
#'
#' Get postage options for a flat-rate envelope, flat-rate box, or package.
#'
#' @param origin_zip (character) A single 5-digit origin zip code.
#' @param destination_zip (character) A single 5-digit destination zip code.
#' @param shipping_date (character) Date you plan to ship the package on in "MM-DD-YYYY" format as character, or "today".
#' @param shipping_time (character) Time of day you plan to ship in 24-hour "HH:MM" format as character, or "now".
#' @param type (character) One of: "box", "envelope", "package". The types "box" and "envelope" refer to flat-rate boxes and envelopes.
#' @param ground_transportation_needed (boolean) does the package need to be transported by ground?
#' @param live_animals (boolean) Does this contain live animals? See \url{https://pe.usps.com/text/pub52/pub52c5_003.htm} for more details.
#' @param day_old_poultry (boolean) Does this contain day-old poultry? See \url{https://pe.usps.com/text/pub52/pub52c5_008.htm#ep184002} for more details.
#' @param hazardous_materials (boolean) Does this contain any hazardous materials? See \url{https://pe.usps.com/text/pub52/pub52c3_001.htm} for more details.
#' @param pounds (numeric) Number of pounds the package weighs.
#' @param ounces (numeric) Number of ounces the package weighs.
#' @param length (numeric) Length of the package in inches. This is the longest dimension.
#' @param height (numeric) Height of the package in inches.
#' @param width (numeric) Width of the package in inches.
#' @param girth (numeric) Girth of the package in inches. Required if \code{shape} is "nonrectangular". This is the distance around the thickest part.
#' @param shape (character) Shape of the package: "rectangular" or "nonrectangular". "nonrectangular" reqires a non-null \code{girth} value.
#' If \code{type} is box or envelope, \code{shape} will always be "rectangular".
#' @param show_details (boolean) Non-essential details of the response are hidden by default. Show them by setting this to TRUE.
#' @param n_tries (numeric) How many times to try the API if at first we don't succeed.
#' @param verbose (boolean) Should information like the shipping date time be dispalyed if the defaults "today" and "now" are chosen be messageed?
#'
#' @details Supply the required information about the package and receive a tibble. Displays the result of a query to the  \href{https://postcalc.usps.com/Calculator/}{"Postage Price Calculator"} in dataframe format. The inputs \code{origin_zip}, \code{destination_zip}, \code{shipping_date}, and \code{shipping_time} are included in the result.
#'
#' If \code{type} is "envelope" or "box", the response is the same regardless of measurements (\code{pounds}, \code{ounces}, \code{height}, \code{width}, \code{girth} and \code{shape}) applied. These only vary outcomes for "package"s.
#'
#' The result can be further cleaned and stardardized by piping the result to \code{scrub_mail}.
#'
#' Multiple origins, destinations, and other options can be supplied and mapped together using, e.g. \code{purrr::pmap}.
#'
#' The API is tried \code{n_tries} times until a tibble is returned with \code{no_success} in columns that could not be returned. This indicates either that the connection was interrupted during the request or that one or more of the arguments supplied were malformed.
#'
#' If a response is successfully recieved but there are no shipping options, the columns are filled with \code{NA}s.
#'
#'
#' @seealso \link{scrub_mail}
#' @importFrom magrittr %>%
#'
#' @examples \dontrun{
#'
#' fetch_mail(origin_zip = "90210",
#'          destination_zip = "59001",
#'          type = "envelope")
#'
#'
#' fetch_mail(origin_zip = "68003",
#'          destination_zip = "23285",
#'          pounds = 4,
#'          ground_transportation_needed = TRUE,
#'          type = "package",
#'          shape = "rectangular",
#'          show_details = TRUE)
#'
#' # Contains an invalid zip ("foobar"), which will get a "no_success" row
#' origins <- c("90210", "foobar", "59001")
#' destinations <- c("68003", "94707", "23285")
#'
#' purrr::map2_dfr(
#'   origins, destinations,
#'   fetch_mail,
#'   type = "package"
#' )
#'
#' # A syntactically fine request, but no results are returned
#' fetch_mail(origin_zip = "04101",
#'     destination_zip = "97211",
#'     shipping_date = "3018-07-04",  # way in the future!
#'     type = "package",
#'     show_details = TRUE)
#'
#' }
#'
#' @return A tibble with information for different postage options, including price and box/envelope dimensions.
#' @export
#'

fetch_mail <- function(origin_zip = NULL,
                       destination_zip = NULL,
                       shipping_date = "today",
                       shipping_time = "now",
                       type = "package",
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
                       n_tries = 3,
                       verbose = TRUE) {
  if (is.null(type) | length(type) > 1) {
    stop("type must be envelope, box, or package")
  }

  if (type == "envelope") {
    type <- "FlatRateEnvelope"
    shape <- "rectangular"
  } else if (type == "box") {
    type <- "FlatRateBox"
    shape <- "rectangular"
  } else if (type == "package") {
    if (length(shape) > 1 |
      !shape %in% c("rectangular", "nonrectangular")) {
      stop("If type is package, shape must be either rectangular or nonrectangular")
    }
    if (shape == "nonrectangular") {
      if (is.null(girth) | girth == 0) {
        stop("If shape is nonrectangular, girth must be > 0.")
      }
    }
    type <- "Package"
  } else {
    stop("type must be envelope, box, or package")
  }

  if (nchar(origin_zip) != 5 | nchar(destination_zip) != 5) {
    warning("Zip codes supplied must be 5 digits.")
  }

  char_args <- list(
    origin_zip, destination_zip,
    shipping_date, shipping_time, type, shape
  )

  if (any(purrr::map(char_args, is.character) == FALSE)) {
    not_char <- char_args[which(purrr::map(char_args, is.character) == FALSE)] %>%
      stringr::str_c(collapse = ", ")
    stop(glue::glue("Argument {not_char} is not of type character."))
  }

  num_args <- list(
    pounds, ounces, length, width, height, girth
  )

  if (any(purrr::map(num_args, is.numeric) == FALSE) |
      any(purrr::map(num_args, ~.x < 0) == TRUE)) {
    not_num <- num_args[which(purrr::map(num_args, is.numeric) == FALSE)] %>%
      stringr::str_c(collapse = ", ")
    stop(glue::glue("Argument {not_num} is not of type numeric or is < 0."))
  }

  lgl_args <- list(
    ground_transportation_needed, live_animals,
    day_old_poultry, hazardous_materials,
    show_details
  )

  if (any(purrr::map(lgl_args, is.logical) == FALSE)) {
    not_lgl <- lgl_args[which(purrr::map(lgl_args, is.logical) == FALSE)] %>%
      stringr::str_c(collapse = ", ")
    stop(glue::glue("Argument {not_lgl} is not of type logical."))
  }

  shipping_date <- get_shipping_date(shipping_date,
                                     verbose = verbose
  )
  shipping_time <- get_shipping_time(shipping_time,
                                     verbose = verbose
  )

  shipping_date_api <-
    shipping_date %>%
    stringr::str_replace_all("-", "%2F")

  shipping_time_api <-
    shipping_time %>%
    stringr::str_replace_all(":", "%3A")

  ground_transportation_needed <-
    ground_transportation_needed %>%
    tolower() %>%
    cap_word()

  live_animals <-
    live_animals %>%
    tolower() %>%
    cap_word()

  day_old_poultry <-
    day_old_poultry %>%
    tolower() %>%
    cap_word()

  hazardous_materials <-
    hazardous_materials %>%
    tolower() %>%
    cap_word()

  shape <-
    shape %>%
    tolower() %>%
    cap_word()

  url <- glue::glue("https://postcalc.usps.com/Calculator/GetMailServices?countryID=0&countryCode=US&\\
                    origin={origin_zip}&\\
                    isOrigMil=False&\\
                    destination={destination_zip}&\\
                    isDestMil=False&\\
                    shippingDate={shipping_date_api}&\\
                    shippingTime={shipping_time_api}&\\
                    itemValue=&\\
                    dayOldPoultry={day_old_poultry}&\\
                    groundTransportation={ground_transportation_needed}&\\
                    hazmat={hazardous_materials}&\\
                    liveAnimals={live_animals}&\\
                    nonnegotiableDocument=False&\\
                    mailShapeAndSize={type}&\\
                    pounds={pounds}&\\
                    ounces={ounces}&\\
                    length={length}&\\
                    height={height}&\\
                    width={width}&\\
                    girth={girth}&\\
                    shape={shape}\\
                    &nonmachinable=False&isEmbedded=False")
  if (verbose) message(glue::glue("Requesting {url}"))

  resp <- try_n_times(url, n_tries = n_tries)

  # Error in the request
  if (!is.null(resp$error)) {
    message(glue::glue("Unsuccessful grabbing data for the supplied arguments."))
    out <-
      tibble::tibble(
        origin_zip = origin_zip,
        dest_zip = destination_zip,
        title = "no_success",
        delivery_day = "no_success",
        retail_price = "no_success",
        click_n_ship_price = "no_success",
        dimensions = "no_success",
        delivery_option = "no_success"
      )

    # We successfully got a response, and it was that there were no services
  } else if (resp$result$PageError == "No Mail Services were found.") {
    message("No Mail Services were found for this request. Try modifying the argument inputs.")
    out <-
      tibble::tibble(
        origin_zip = origin_zip,
        dest_zip = destination_zip,
        title = NA_character_,
        delivery_day = NA_character_,
        retail_price = NA_character_,
        click_n_ship_price = NA_character_,
        dimensions = NA_character_,
        delivery_option = NA_character_
      )

    # We got a good response
  } else {
    resp <- resp$result

    nested <-
      resp$Page$MailServices %>%
      tibble::as_tibble()

    unnested <-
      nested %>%
      purrr::map_df(replace_x) %>%
      tidyr::unnest(DeliveryOptions)

    out <-
      unnested %>%
      janitor::clean_names() %>%
      dplyr::rename(
        delivery_option = name,
        click_n_ship_price = cn_s_price
      ) %>%
      dplyr::select(
        title, delivery_day, retail_price,
        click_n_ship_price, delivery_option,
        dimensions, postage_service_id
      )
  }

  if (live_animals == TRUE & verbose == TRUE) {
    cowsay::say("Woah Nelly!", by = "buffalo")
  }

  shipping_date <- get_shipping_date(shipping_date,
                                     verbose = verbose
  )
  shipping_time <- get_shipping_time(shipping_time,
                                     verbose = verbose
  )

  if (show_details == FALSE) {
    out <-
      out %>%
      dplyr::select(title, delivery_day, retail_price, click_n_ship_price, dimensions)
  } else if (show_details == TRUE) {
    out <-
      out %>%
      dplyr::select(
        title, delivery_day, retail_price, click_n_ship_price, dimensions,
        delivery_option
      )
  }

  out <-
    out %>%
    dplyr::mutate(
      origin_zip = origin_zip,
      dest_zip = destination_zip,
      shipping_date = shipping_date,
      shipping_time = shipping_time
    ) %>%
    dplyr::select(
      origin_zip, dest_zip,
      dplyr::everything()
    )

  return(out)
}
