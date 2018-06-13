

get_zone <- function(origin_zip, as_range = FALSE, show_modifiers = FALSE) {
  origin_zip <- origin_zip %>% prepend_zeros()

  out <-
    origin_zip %>%
    get_zones()

  if (as_range == FALSE) {
    out <-
      out %>%
      interpolate_zips()
  }

  if (show_modifiers == FALSE) {
    out <-
      out %>%
      select(-starts_with("modifier"))
  }

  return(out)
}

get_zone("006")
