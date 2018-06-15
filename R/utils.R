#' @import magrittr

base_url <- "https://postcalc.usps.com/DomesticZoneChart/GetZoneChart?zipCode3Digit="

to_ignore <- c("ZIPCodeError", "PageError")

prepend_zeros <- function(x) {
  if (nchar(x) == 1) {
    x <- stringr::str_c("00", x, collapse = "")
  } else if (nchar(x) == 2) {
    x <- stringr::str_c("0", x, collapse = "")
  }
  x
}


all_possible_origins <- 0:999 %>%
  as.character() %>%
  purrr::map_chr(prepend_zeros)


replace_x <- function(x, replacement = NA_character_) {
  if (length(x) == 0) {
    replacement
  } else {
    x
  }
}


prep_zip <- function(zip) {

  if (!is.character(zip)) {
    stop(glue::glue("Invalid zip {zip}; must be of type character."))
  }

  if (stringr::str_detect(zip, "[^0-9]")) {
    stop(glue::glue("Invalid zip {zip}; only numeric characters are allowed."))
  }

  zip <- zip %>%
    prepend_zeros()

  if (nchar(zip) > 5) {
    warning(glue::glue("Zip can be at most 5 characters. Trimming {zip} to {substr(zip, 1, 5)}."))
    zip <- zip %>% substr(1, 5)
  }
  if (nchar(zip) > 3 & verbose) {
    message(glue::glue("Only 3 characters can be sent to the API. Zip {zip} will be requested as {substr(zip, 1, 3)}."))
  }

  return(zip)
}


get_data <- function(url) {
  url %>%
    jsonlite::fromJSON()
}


clean_data <- function(dat, o_zip) {
  if (dat$ZIPCodeError != "") {
    stop("Non-empty ZIPCodeError returned from the API.")
  }

  dat <- dat[!names(dat) %in% to_ignore]

  if ("Zip5Digit" %in% names(dat)) {
    five_digit_zips <-
      dat$Zip5Digit %>%
      dplyr::mutate(
        n_digits = 5
      )
  } else {
    five_digit_zips <- tibble::tibble()
  }

  three_digit_zips <-
    dat[!names(dat) %in% to_ignore] %>%
    dplyr::bind_rows() %>%
    dplyr::mutate(
      n_digits = 3
    ) %>%
    tibble::as_tibble()

  out <-
    five_digit_zips %>%
    dplyr::bind_rows(three_digit_zips)

  out <- out %>%
    tidyr::separate(ZipCodes,
             into = c("dest_zip_start", "dest_zip_end"),
             sep = "---") %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      dest_zip_end = ifelse(is.na(dest_zip_end), dest_zip_start, dest_zip_end)
    ) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      zone = stringr::str_extract_all(Zone, "[0-9]", simplify = TRUE),
      mail_service = MailService,
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
    ) %>%
    dplyr::select(-Zone, -MailService,
                  -modifier_star, -modifier_plus,
                  -n_digits) %>%
    dplyr::mutate(
      origin_zip = o_zip
    ) %>%
    dplyr::distinct(origin_zip, dest_zip_start, dest_zip_end, zone, .keep_all = TRUE) %>%
    dplyr::select(origin_zip, dplyr::everything()) %>%
    dplyr::arrange(dest_zip_start, dest_zip_end)

  out$same_ndc %<>% purrr::map_chr(replace_x)
  out$has_five_digit_exceptions %<>% purrr::map_chr(replace_x)

  return(out)
}


get_zones <- function(inp, verbose = TRUE, ...) {

  if (verbose) {
    message(glue::glue("Grabbing origin ZIP {inp}"))
  }

  this_url <- stringr::str_c(base_url, inp, collapse = "")
  out <- get_data(this_url)

  if (out$PageError != "") {
    if (out$PageError == "No Zones found for the entered ZIP Code.") {
      out <- tibble::tibble(
        origin_zip = inp,
        dest_zip_start = NA_character_,
        dest_zip_end = NA_character_,
        zone = NA_character_,
        same_ndc = NA_character_,
        has_five_digit_exceptions = NA_character_
      )
    } else {
      stop("Non-empty PageError returned from the API.")
    }

    out %<>% sticky::sticky()
    attributes(out)$validity <- "invalid"

    message(glue::glue("Origin zip {inp} is not in use."))

  } else {
    suppressWarnings({
      out <- get_data(this_url) %>%
        clean_data(o_zip = inp)

      out <- out %<>% sticky::sticky()
      attributes(out)$validity <- "valid"

      if (verbose) {
        message(glue::glue("Recieved {as.numeric(max(out$dest_zip_end)) - as.numeric(min(out$dest_zip_start))} destination ZIPs for {as.numeric(max(out$zone)) - as.numeric(min(out$zone))} zones."))
      }
    })
  }

  return(out)
}


interpolate_zips <- function(df) {
  df %<>% sticky::sticky()

  if ((attributes(df)$validity == "invalid")) {
    df %<>% sticky::sticky()
    df <-
      df %>%
      dplyr::mutate(dest_zip = NA_character_)

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
    dplyr::ungroup()

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
