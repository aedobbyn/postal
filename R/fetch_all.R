#' Grab all the origin-destination pairs.
#'
#'
#' @param origins A vector of origin zips.
#' @param sleep_time How long to sleep in between requests, plus or minus \code{runif(1)} second.
#' @param verbose Message what's going on?
#' @param ... Other arguments
#'
#' @details For all the 3-digit origin zip codes, grab all destination zips and their corresponding zones.
#'
#' @importFrom magrittr %>%
#'
#' @examples \dontrun{
#'
#' fetch_all(sample(all_possible_origins, 4))
#' }
#'
#' @return A tibble with origin zip and destination zips (in ranges or unspooled) and the USPS zones the origin-destination pair corresponds to.
#' @export

fetch_all <- function(origins = all_possible_origins,
                      sleep_time = 1, verbose = TRUE, ...) {

  fetch_and_sleep <- function(origin, sleep_time = 1,
                              verbose = TRUE, ...) {

    this_sleep <- sleep_time + runif(1)

    if (verbose) message(glue::glue("Sleeping {round(this_sleep, 3)} seconds."))
    Sys.sleep(this_sleep)

    this <- fetch_zones(origin, verbose = verbose, ...)
    return(this)
  }

  out <-
    origins %>%
    purrr::map_dfr(fetch_and_sleep)

  return(out)
}


