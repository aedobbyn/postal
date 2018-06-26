#' @import magrittr

# -------------- Fetch Zones ---------------- #

three_digit_base_url <-
  "https://postcalc.usps.com/DomesticZoneChart/GetZoneChart?zipCode3Digit="

five_digit_base_url <-
  "https://postcalc.usps.com/DomesticZoneChart/GetZone"


#' Details
#'
#' @name zone_detail_definitions
#' @rdname zone_detail_definitions
#' @export
#' @usage zone_detail_definitions
zone_detail_definitions <-
  tibble::tribble(
    ~name, ~digit_endpoint, ~definition,
    "specific_to_priority_mail", "3, 5",
    "This zone designation applies to Priority Mail only.",
    "same_ndc", "3, 5",
    "The origin and destination zips are in the same Network Distribution Center.",
    "has_five_digit_exceptions", "3",
    "This 3 digit destination zip prefix appears at the beginning of certain 5 digit destination zips that correspond to a different zone.",
    "local", "5",
    "Is this a local zone?",
    "full_response", "5",
    "Prose API response for these two 5-digit zips."
  )


prepend_zeros <- function(x, verbose = FALSE, ...) {
  if (nchar(x) == 1) {
    y <- stringr::str_c("00", x, collapse = "")
    if (verbose) message(glue::glue("Making {x} into {y}"))
  } else if (nchar(x) == 2) {
    y <- stringr::str_c("0", x, collapse = "")
    if (verbose) message(glue::glue("Making {x} into {y}"))
    # 5 digit zip that lost its leading 0 during interpolate_zips() and needs it back;
    # user-supplied 4 digit zips are not allowed by prep_zip()
  } else if (nchar(x) == 4) {
    y <- stringr::str_c("0", x, collapse = "")
  } else {
    y <- x
  }
  return(y)
}


#' All possible 3-digit origins
#'
#' @name all_possible_origins
#' @rdname all_possible_origins
#' @export
#' @usage all_possible_origins
all_possible_origins <-
  0:999 %>%
  as.character() %>%
  purrr::map_chr(prepend_zeros)


replace_x <- function(x, replacement = NA_character_) {
  if (length(x) == 0) {
    replacement
  } else {
    x
  }
}


prep_zip <- function(zip, verbose = FALSE, ...) {
  if (!is.character(zip)) {
    stop(glue::glue("Invalid zip {zip}; must be of type character."))
  }

  if (stringr::str_detect(zip, "[^0-9]")) {
    stop(glue::glue("Invalid zip {zip}; only numeric characters are allowed."))
  }

  if (nchar(zip) == 4) {
    stop(glue::glue("Invalid zip {zip}; don't know whether 4 \\
                    digit zip supplied should be interpreted as 3 or 5 digits."))
  }

  if (nchar(zip) > 5) {
    warning(glue::glue("Zip can be at most 5 characters; \\
                       trimming {zip} to {substr(zip, 1, 5)}."))
    zip <- zip %>% substr(1, 5)
  }

  zip <- zip %>%
    prepend_zeros(verbose = verbose)

  return(zip)
}


get_data <- function(url) {
  if (!curl::has_internet()) {  # nocov start
    message("No internet connection detected.")
  }                             # nocov end

  url %>%
    jsonlite::fromJSON()
}


try_get_data <-
  purrr::safely(get_data)


try_n_times <- function(url, n_tries = 3, ...) {
  this_try <- 1
  resp <- try_get_data(url)

  if (!is.null(resp$error)) {
    while (this_try < n_tries) {
      this_try <- this_try + 1
      message(glue::glue("Error on request. \\
                         Beginning try {this_try} of {n_tries}."))
      Sys.sleep(this_try^2)
      resp <- try_get_data(url)
    }
    return(resp)
  } else {
    return(resp)
  }
}


do_try_n_times <- function(url,
                           origin_zip = NULL,
                           destination_zip = NULL,
                           n_tries = 3, show_details = FALSE) {
  resp <-
    try_n_times(url, n_tries = n_tries)

  if (!is.null(resp$error)) {
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
  } else {
    return(resp)
  }
}


clean_zones <- function(dat, inp) {
  if (dat$ZIPCodeError != "") {
    stop(glue::glue("ZIPCodeError returned from \\
                    API for {inp}: {dat$ZIPCodeError}"))
  }

  to_ignore <- c("ZIPCodeError", "PageError")

  dat <- dat[!names(dat) %in% to_ignore]

  if ("Zip5Digit" %in% names(dat)) {
    five_digit_zips <-
      dat$Zip5Digit
  } else {
    five_digit_zips <- tibble::tibble()   # nocov
  }

  three_digit_zips <-
    dat[!names(dat) %in% to_ignore] %>%
    dplyr::bind_rows() %>%
    tibble::as_tibble()

  out <-
    five_digit_zips %>%
    dplyr::bind_rows(three_digit_zips)

  out <- out %>%
    tidyr::separate(ZipCodes,
      into = c("dest_zip_start", "dest_zip_end"),
      sep = "---"
    ) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      dest_zip_end = ifelse(is.na(dest_zip_end), dest_zip_start, dest_zip_end)
    ) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      zone = stringr::str_extract_all(Zone, "[0-9]", simplify = TRUE),
      modifier_star = stringr::str_extract(Zone, "[*]"),
      modifier_plus = stringr::str_extract(Zone, "[+]"),
      same_ndc = dplyr::case_when(
        !is.na(modifier_star) ~ TRUE,
        is.na(modifier_star) ~ FALSE
      ),
      has_five_digit_exceptions = dplyr::case_when(
        !is.na(modifier_plus) ~ TRUE,
        is.na(modifier_plus) ~ FALSE
      ),
      specific_to_priority_mail = dplyr::case_when(
        MailService == "Priority Mail" ~ TRUE,
        MailService == "" ~ FALSE
      )
    ) %>%
    dplyr::select(
      -Zone, -MailService,
      -modifier_star, -modifier_plus
    ) %>%
    dplyr::mutate(
      origin_zip = inp
    ) %>%
    dplyr::distinct(origin_zip, dest_zip_start, dest_zip_end, zone, .keep_all = TRUE) %>%
    dplyr::select(origin_zip, dplyr::everything()) %>%
    dplyr::arrange(dest_zip_start, dest_zip_end)

  out$same_ndc %<>% purrr::map_lgl(replace_x)
  out$has_five_digit_exceptions %<>% purrr::map_lgl(replace_x)

  return(out)
}


get_zones <- function(inp, verbose = FALSE, n_tries = 3, ...) {
  if (verbose) {
    message(glue::glue("Grabbing origin ZIP {inp}"))
  }

  this_url <- stringr::str_c(three_digit_base_url, inp, collapse = "")
  resp <- do_try_n_times(this_url)

  out <- resp$result

  if (out$PageError != "") {
    if (out$PageError == "No Zones found for the entered ZIP Code.") {
      out <- tibble::tibble(
        origin_zip = inp,
        dest_zip_start = NA,
        dest_zip_end = NA,
        specific_to_priority_mail = NA,
        zone = NA,
        same_ndc = NA,
        has_five_digit_exceptions = NA
      )
    } else if (out$PageError != "") {
      stop(glue::glue("PageError returned from API for {inp}: {out$PageError}"))
    }

    out <-
      out %>%
      dplyr::mutate(validity = "invalid")

    message(glue::glue("Origin zip {inp} is not in use."))
  } else {
    suppressWarnings({
      out <-
        out %>%
        clean_zones(inp)

      out <-
        out %>%
        dplyr::mutate(validity = "valid")

      if (verbose) {
        message(glue::glue("Recieved \\
                           {as.numeric(max(out$dest_zip_end)) - as.numeric(min(out$dest_zip_start))} \\
                           destination ZIPs for \\
                           {as.numeric(max(out$zone)) - as.numeric(min(out$zone))} \\
                           zones."))
      }
    })
  }

  return(out)
}


get_zones_five_digit <- function(origin_zip, destination_zip,
                                 show_details = FALSE,
                                 verbose = FALSE, n_tries = 3, ...) {
  if (verbose) {
    message(glue::glue("Grabbing zone for origin zip \\
                       {origin_zip} and destination zip {destination_zip}"))
  }

  url <-
    glue::glue("{five_digit_base_url}?\\
               origin={origin_zip}&\\
               destination={destination_zip}")

  resp <- do_try_n_times(url)

  out <- resp$result

  return(out)
}


interpolate_zips <- function(df) {
  if (df$validity[1] == "invalid") {
    df <-
      df %>%
      dplyr::mutate(dest_zip = NA_character_)

    return(df)
  } else if (df$validity[1] == "no_success") {
    df <-
      df %>%
      dplyr::mutate(dest_zip = "no_success")

    return(df)
  }

  df <- df %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      houser = as.numeric(dest_zip_start):as.numeric(dest_zip_end) %>% list()
    ) %>%
    tidyr::unnest() %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      dest_zip = as.character(houser) %>% prepend_zeros()
    ) %>%
    dplyr::ungroup() %>%
    dplyr::select(-houser)

  return(df)
}


# -------------- Fetch Mail ---------------- #


cap_word <- function(x) {
  x <- as.character(x)
  substr(x, 1, 1) <-
    toupper(substr(x, 1, 1))
  x
}

get_shipping_date <- function(shipping_date,
                              verbose = FALSE) {
  if (shipping_date == "today") {
    shipping_date <-
      Sys.Date() %>%
      as.character()

    if (verbose) message(glue::glue("Using ship on date {shipping_date}."))
  }
  return(shipping_date)
}


get_shipping_time <- function(shipping_time,
                              verbose = FALSE) {
  if (shipping_time == "now") {
    shipping_time <-
      stringr::str_c(
        lubridate::now() %>% lubridate::hour(),
        ":",
        lubridate::now() %>% lubridate::minute()
      )

    if (verbose) message(glue::glue("Using ship on time {shipping_time}."))
  }
  return(shipping_time)
}


get_mail <- function(origin_zip = NULL,
                     destination_zip = NULL,
                     shipping_date = "today",
                     shipping_time = "now",
                     ground_transportation_needed = TRUE,
                     live_animals = FALSE,
                     day_old_poultry = FALSE,
                     hazardous_materials = FALSE,
                     type = c("box", "envelope"),
                     pounds = 0,
                     ounces = 0,
                     length = 0,
                     height = 0,
                     width = 0,
                     girth = 0,
                     shape = c("rectangular", "nonrectangular"),
                     n_tries = 3,
                     verbose = TRUE, ...) {
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

  if (any(purrr::map(num_args, is.numeric) == FALSE)) {
    not_num <- num_args[which(purrr::map(num_args, is.numeric) == FALSE)] %>%
      stringr::str_c(collapse = ", ")
    stop(glue::glue("Argument {not_num} is not of type numeric."))
  }

  lgl_args <- list(
    ground_transportation_needed, live_animals,
    day_old_poultry, hazardous_materials
  )

  if (any(purrr::map(lgl_args, is.logical) == FALSE)) {
    not_lgl <- lgl_args[which(purrr::map(lgl_args, is.logical) == FALSE)] %>%
      stringr::str_c(collapse = ", ")
    stop(glue::glue("Argument {not_lgl} is not of type logical."))
  }

  shipping_date <- get_shipping_date(shipping_date,
                                     verbose = verbose)
  shipping_time <- get_shipping_time(shipping_time,
                                     verbose = verbose)

  shipping_date <-
    shipping_date %>%
    stringr::str_replace_all("-", "%2F")

  shipping_time <-
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
                    shippingDate={shipping_date}&\\
                    shippingTime={shipping_time}&\\
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

  return(resp)
}


clean_mail <- function(resp, show_details = FALSE) {
  if (resp$PageError == "No Mail Services were found.") {
    stop("No Mail Services were found for this request. Try modifying the argument inputs.")
  }

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

  return(out)
}


extract_dates <- function(d) {
  d <- d %>%
    stringr::str_extract("[A-Za-z]+ [0-9]+") %>%
    stringr::str_c(glue::glue(", {lubridate::now() %>% lubridate::year()}")) %>%
    lubridate::mdy()

  if (d - lubridate::today() < 0) {
    d <- d + 365
  }

  return(d)
}


fetch_mail <- function(origin_zip = NULL,
                       destination_zip = NULL,
                       shipping_date = "today",
                       shipping_time = "now",
                       ground_transportation_needed = TRUE,
                       live_animals = FALSE,
                       day_old_poultry = FALSE,
                       hazardous_materials = FALSE,
                       type = c("box", "envelope"),
                       pounds = 0,
                       ounces = 0,
                       length = 0,
                       height = 0,
                       width = 0,
                       girth = 0,
                       shape = c("rectangular", "nonrectangular"),
                       n_tries = 3,
                       show_details = TRUE,
                       verbose = TRUE, ...) {
  resp <- get_mail(
    origin_zip = origin_zip,
    destination_zip = destination_zip,
    shipping_date = shipping_date,
    shipping_time = shipping_time,
    type = type,
    ground_transportation_needed = ground_transportation_needed,
    pounds = pounds,
    ounces = ounces,
    length = length,
    height = height,
    width = width,
    girth = girth,
    shape = shape,
    n_tries = n_tries,
    verbose = verbose
  )

  if (!is.null(resp$error)) {
    no_success <-
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

    if (show_details == FALSE) {
      no_success <-
        no_success %>%
        dplyr::select(-delivery_option)
    }

    message(glue::glue("Unsuccessful grabbing data for the supplied arguments."))
    return(no_success)
  } else {
    out <- resp$result
  }

  shipping_date <- get_shipping_date(shipping_date,
                                     verbose = verbose)
  shipping_time <- get_shipping_time(shipping_time,
                                     verbose = verbose)

  out <-
    out %>%
    clean_mail(show_details = show_details) %>%
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


#' Forward pipe operator
#'
#' @name %>%
#' @rdname forward_pipe
#' @keywords internal
#' @export
#' @importFrom magrittr %>%
#' @usage lhs \%>\% rhs
