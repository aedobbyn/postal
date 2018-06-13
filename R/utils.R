
base_url <- "https://postcalc.usps.com/DomesticZoneChart/GetZoneChart?zipCode3Digit="

to_ignore <- c("ZIPCodeError", "PageError", "Zip5Digit")

all_possible_origins <- 0:999 %>%
  as.character() %>%
  map_chr(prepend_zeros)


replace_x <- function(x, replacement = NA_character_) {
  if (length(x) == 0) {
    replacement
  } else {
    x
  }
}


prepend_zeros <- function(x) {
  if (nchar(x) == 1) {
    x <- str_c("00", x, collapse = "")
  } else if (nchar(x) == 2) {
    x <- str_c("0", x, collapse = "")
  }
  x
}


get_data <- function(url) {
  url %>%
    fromJSON()
}


clean_data <- function(dat, o_zip) {
  dat <- dat[!names(dat) %in% to_ignore]

  out <- dat %>%
    bind_rows() %>%
    as_tibble()

  out <- out %>%
    select(-MailService) %>%
    separate(ZipCodes,
             into = c("dest_zip_start", "dest_zip_end"),
             sep = "---") %>%
    rowwise() %>%
    mutate(
      dest_zip_end = ifelse(is.na(dest_zip_end), dest_zip_start, dest_zip_end)
    ) %>%
    ungroup() %>%
    mutate(
      zone = str_extract_all(Zone, "[0-9]", simplify = TRUE),
      modifier_1 = str_extract(Zone, "[*]"),
      modifier_2 = str_extract(Zone, "[+]")
    ) %>%
    select(-Zone) %>%
    mutate(
      origin_zip = o_zip
    ) %>%
    select(origin_zip, everything())

  out$modifier_1 %<>% map_chr(replace_x)
  out$modifier_2 %<>% map_chr(replace_x)

  return(out)
}


interpolate_zips <- function(df) {
  out <- df %>%
    rowwise() %>%
    mutate(
      houser = as.numeric(dest_zip_start):as.numeric(dest_zip_end) %>% list()
    ) %>%
    unnest() %>%
    rowwise() %>%
    mutate(
      dest_zip = as.character(houser) %>% prepend_zeros
    ) %>%
    select(origin_zip, dest_zip, zone) %>%
    ungroup()

  return(out)
}


get_zones <- function(inp, verbose = TRUE, ...) {

  if (verbose) {
    message(glue("Grabbing origin ZIP {inp}"))
  }

  this_url <- str_c(base_url, inp, collapse = "")
  out <- get_data(this_url)

  if (out$PageError == "No Zones found for the entered ZIP Code.") {
    out <- tibble(
      origin_zip = NA_character_,
      dest_zip_start = NA_character_,
      dest_zip_end = NA_character_,
      zone = NA_character_,
      modifier_1 = NA_character_,
      modifier_2 = NA_character_
    )
    attributes(out)$validity <- "invalid"

    message(glue("Origin zip {inp} is not in use."))

  } else {
    suppressWarnings({
      out <- get_data(this_url) %>%
        clean_data(o_zip = inp)

      attributes(out)$validity <- "valid"

      if (verbose) {
        message(glue("Recieved {as.numeric(max(out$dest_zip_end)) - as.numeric(min(out$dest_zip_start))} destination ZIPs for {as.numeric(max(out$zone)) - as.numeric(min(out$zone))} zones."))
      }
    })
  }

  return(out)
}

