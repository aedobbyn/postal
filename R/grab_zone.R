

grab_zone_from_origin <- function(origin_zip, as_range = FALSE, show_modifiers = FALSE,
                     verbose = TRUE, sleep_time = 1, ...) {

  if (str_detect(origin_zip, "[^0-9]")) {
    stop("Invalid origin_zip; only numeric characters are allowed.")
  }

  if (nchar(origin_zip) > 3) {
    stop("origin_zip can be at most 3 characters.")
  }

  if (!is.numeric(origin_zip)) {
    origin_zip <- origin_zip %>% as.numeric()
    if (is.na(origin_zip) | origin_zip < 0) {
      stop("Invalid origin_zip.")
    }
  }

  origin_zip <- origin_zip %>%
    prepend_zeros()

  out <-
    origin_zip %>%
    get_zones(verbose = verbose,
              sleep_time = sleep_time)

  if (attributes(out)$validity == "valid") {
    if (as_range == FALSE) {
      out <-
        out %>%
        interpolate_zips()
    }
  }

  if (show_modifiers == FALSE) {
    out <-
      out %>%
      select(-starts_with("modifier"))
  }

  return(out)
}
