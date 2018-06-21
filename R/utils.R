#' @import magrittr

three_digit_base_url <-
  "https://postcalc.usps.com/DomesticZoneChart/GetZoneChart?zipCode3Digit="

five_digit_base_url <-
  "https://postcalc.usps.com/DomesticZoneChart/GetZone"


#' Details
#'
#' @name detail_definitions
#' @rdname detail_definitions
#' @export
#' @usage detail_definitions
detail_definitions <-
  tibble::tribble(
    ~name, ~definition,
    "specific_to_priority_mail",
      "This 5 digit zone designation applies to Priority Mail only; for Standard, refer to the 3 digit zone designation.",
    "same_ndc",
      "The origin and destination zips are in the same Network Distribution Center.",
    "has_five_digit_exceptions",
      "This 3 digit destination zip prefix appears at the beginning of certain 5 digit destination zips that correspond to a different zone."
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


prep_zip <- function(zip, ...) {
  if (!is.character(zip)) {
    stop(glue::glue("Invalid zip {zip}; must be of type character."))
  }

  if (stringr::str_detect(zip, "[^0-9]")) {
    stop(glue::glue("Invalid zip {zip}; only numeric characters are allowed."))
  }

  if (nchar(zip) == 4) {
    stop(glue::glue("Invalid zip {zip}; don't know whether 4 digit zip supplied should be interpreted as 3 or 5 digits."))
  }

  if (nchar(zip) > 5) {
    warning(glue::glue("Zip can be at most 5 characters; trimming {zip} to {substr(zip, 1, 5)}."))
    zip <- zip %>% substr(1, 5)
  }

  zip <- zip %>%
    prepend_zeros()

  return(zip)
}


get_data <- function(url) {
  # TODO: figure out namespace error
  # if (!curl::has_internet()) {
  #   message("No internet connection detected.")
  # }

  url %>%
    jsonlite::fromJSON()
}


try_get_data <-
  purrr::safely(get_data)


clean_data <- function(dat, o_zip) {
  if (dat$ZIPCodeError != "") {
    stop(glue::glue("ZIPCodeError returned from API for {o_zip}: {dat$ZIPCodeError}"))
  }

  to_ignore <- c("ZIPCodeError", "PageError")

  dat <- dat[!names(dat) %in% to_ignore]

  if ("Zip5Digit" %in% names(dat)) {
    five_digit_zips <-
      dat$Zip5Digit
  } else {
    five_digit_zips <- tibble::tibble()
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
      origin_zip = o_zip
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
  this_try <- 1
  resp <- try_get_data(this_url)

  if (!is.null(resp$error)) {
    while (this_try <= n_tries) {
      this_try <- this_try + 1
      message(glue::glue("Error on request. Beginning try {this_try} of {n_tries}."))
      Sys.sleep(this_try ^ 2)
      resp <- try_get_data(this_url)

      if (this_try == n_tries) {
        message(glue::glue("Unsuccessful grabbing data for {inp}."))
        no_success <- tibble::tibble(
          origin_zip = inp,
          dest_zip_start = "no_success",
          dest_zip_end = "no_success",
          zone = "no_success",
          specific_to_priority_mail = NA,
          same_ndc = NA,
          has_five_digit_exceptions = NA,
          validity = "no_success"
        )

        return(no_success)
      }
    }
  }

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
      out <- get_data(this_url) %>%
        clean_data(o_zip = inp)

      out <-
        out %>%
        dplyr::mutate(validity = "valid")

      if (verbose) {
        message(glue::glue("Recieved {as.numeric(max(out$dest_zip_end)) - as.numeric(min(out$dest_zip_start))} destination ZIPs for {as.numeric(max(out$zone)) - as.numeric(min(out$zone))} zones."))
      }
    })
  }

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


#' Pipe operator
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom magrittr %>%
#' @usage lhs \%>\% rhs
