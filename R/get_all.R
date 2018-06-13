

get_all_zones <- function(verbose = TRUE, ...) {

  out <-
    all_possible_origins %>%
    grab_zone_from_origin()

  return(out)
}


