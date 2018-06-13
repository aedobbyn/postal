#' @import magrittr

base_url <- "https://postcalc.usps.com/DomesticZoneChart/GetZoneChart?zipCode3Digit="

to_ignore <- c("ZIPCodeError", "PageError", "Zip5Digit")

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


get_data <- function(url) {
  url %>%
    jsonlite::fromJSON()
}


clean_data <- function(dat, o_zip) {
  dat <- dat[!names(dat) %in% to_ignore]

  out <- dat %>%
    dplyr::bind_rows() %>%
    tibble::as_tibble()

  out <- out %>%
    dplyr::select(-MailService) %>%
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
      modifier_1 = stringr::str_extract(Zone, "[*]"),
      modifier_2 = stringr::str_extract(Zone, "[+]")
    ) %>%
    dplyr::select(-Zone) %>%
    dplyr::mutate(
      origin_zip = o_zip
    ) %>%
    dplyr::select(origin_zip, dplyr::everything())

  out$modifier_1 %<>% purrr::map_chr(replace_x)
  out$modifier_2 %<>% purrr::map_chr(replace_x)

  return(out)
}


get_zones <- function(inp, verbose = TRUE, ...) {

  if (verbose) {
    message(glue::glue("Grabbing origin ZIP {inp}"))
  }

  this_url <- stringr::str_c(base_url, inp, collapse = "")
  out <- get_data(this_url)

  if (out$PageError == "No Zones found for the entered ZIP Code.") {
    out <- tibble::tibble(
      origin_zip = inp,
      dest_zip_start = NA_character_,
      dest_zip_end = NA_character_,
      zone = NA_character_,
      modifier_1 = NA_character_,
      modifier_2 = NA_character_
    )
    out %<>% sticky::sticky()
    attributes(out)$validity <- "invalid"

    message(glue::glue("Origin zip {inp} is not in use."))

  } else {
    suppressWarnings({
      out <- get_data(this_url) %>%
        clean_data(o_zip = inp)
      out %<>% sticky::sticky()

      attributes(out)$validity <- "valid"

      if (verbose) {
        message(glue::glue("Recieved {as.numeric(max(out$dest_zip_end)) - as.numeric(min(out$dest_zip_start))} destination ZIPs for {as.numeric(max(out$zone)) - as.numeric(min(out$zone))} zones."))
      }
    })
  }

  return(out)
}


interpolate_zips <- function(df) {
  if ((attributes(df)$validity == "invalid")) {
    out <-
      df %>%
      dplyr::mutate(dest_zip = NA_character_) %>%
      dplyr::select(origin_zip, dest_zip, zone)

    # attributes(df)$validity <- "invalid"
    return(out)
  }

  out <- df %>%
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
    dplyr::select(origin_zip, dest_zip, zone)

  return(out)
}



#' Pipe operator
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom magrittr %>%
#' @usage lhs \%>\% rhs
