
base_url <- "https://postcalc.usps.com/DomesticZoneChart/GetZoneChart?zipCode3Digit="


to_ignore <- c("ZIPCodeError", "PageError", "Zip5Digit")  # TODO: address Zip5Digit


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


get_zones <- function(vec, sleep_time = 1, verbose = TRUE, ...) {
  out <- NULL

  for (i in seq_along(vec)) {
    if (verbose) {
      message(glue("Grabbing origin ZIP {vec[i]}"))
    }

    this_url <- str_c(base_url, vec[i], collapse = "")
    this_origin <- get_data(this_url)

    if (this_origin$PageError == "No Zones found for the entered ZIP Code.") {
      this_origin <- NULL
      message(glue("Origin zip {vec[i]} is not in use."))

    } else {
      suppressWarnings({
        this_origin <- get_data(this_url) %>%
          clean_data(o_zip = vec[i])

        if (verbose) {
          message(glue("Recieved {as.numeric(max(this_origin$dest_zip_end)) - as.numeric(min(this_origin$dest_zip_start))} destination ZIPs for {as.numeric(max(this_origin$zone)) - as.numeric(min(this_origin$zone))} zones."))
        }
      })
    }

    Sys.sleep(sleep_time + runif(1))

    out <- out %>% bind_rows(this_origin)
  }

  return(out)
}



