library(here)
library(tidyverse)
library(jsonlite)

# Objective here is to get zones for all combinations of origin and destination ZIP codes
# Zone is determined by the combination of origin and destination
# Website: https://postcalc.usps.com/DomesticZoneChart

# Sample API request to the single endpoint
sample_url <- "https://postcalc.usps.com/DomesticZoneChart/GetZoneChart?zipCode3Digit=005"

# Columns from JSON to ignore
to_ignore <- c("ZIPCodeError", "PageError", "Zip5Digit")  # TODO: address Zip5Digit


replace_x <- function(x, replacement = NA_character_) {
  if (length(x) == 0) {
    replacement
  } else {
    x
  }
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


get_zones <- function(vec) {
  out <- NULL

  for (i in seq_along(vec)) {
    this_origin <- get_data() %>%
      clean_data(o_zip = vec[i])

    Sys.sleep(1)

    out <- out %>% bind_rows(this_origin)
  }

  return(out)
}


# Get the full set
ups_zones <- fob_replink$fob_zip_trim %>%
  get_zones()

# write_csv(ups_zones, here("data", "dervived", "zip_zone.csv"))


