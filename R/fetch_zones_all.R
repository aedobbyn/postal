#' Grab all the 3-digit origin-destination pairs.
#'
#' @param origins A vector of origin zips. Defaults to all possible origin zips from 000 to 999.
#' @param write_to The path to a CSV file to create and append each result to.
#' @param sleep_time How long to sleep in between requests, plus or minus \code{runif(1)} second.
#' @param n_tries How many times to try getting an origin if we're unsuccessful the first time?
#' @param as_range Do you want zones corresponding to a range of destination zips or a full listing of them?
#' @param show_details Should columns with more details be retained?
#' @param verbose Message what's going on?
#' @param ... Other arguments
#'
#' @details For all the 3-digit origin zip codes, grab all destination zips and their corresponding zones. This is equivalent to running \code{\link{fetch_zones}} for all possible 3 digit origin zips.
#'
#' If this fails partway through, origins that could not be retrieved get a "no_success" value in their \code{dest_zip} and \code{zone} columns but we continue trying to grab results for all supplied \code{origins}.
#'
#' @importFrom magrittr %>%
#' @importFrom readr write_csv
#'
#' @examples \dontrun{
#'
#' fetch_all(sample(all_possible_origins, 4))
#'
#' fetch_all(show_details = TRUE, verbose = TRUE,
#'     write_to = glue::glue(here::here("data", "{Sys.Date()}_zip_zones.csv")))
#' }
#'
#' @return A tibble with origin zip and destination zips (in ranges or unspooled) and the USPS zones the origin-destination pair corresponds to.
#' @export

fetch_all <- function(origins = all_possible_origins,
                      write_to = NULL,
                      sleep_time = 1,
                      n_tries = 3,
                      as_range = FALSE,
                      show_details = FALSE,
                      verbose = TRUE, ...) {
  fetch_and_sleep <- function(origin, sleep_time = 1,
                                verbose = TRUE, ...) {
    this <- fetch_zones(origin,
      as_range = as_range,
      show_details = show_details,
      verbose = verbose, ...
    )

    this_sleep <- sleep_time + runif(1)
    if (verbose) message(glue::glue("Sleeping {round(this_sleep, 3)} seconds."))
    Sys.sleep(this_sleep)

    if (!is.null(write_to)) {
      if (origin == origins[1]) { # Only add headers to the first origin
        readr::write_csv(this, write_to, append = TRUE, col_names = TRUE)
        if (substr(write_to, nchar(write_to) - 3, nchar(write_to)) != ".csv") {
          warning("write_to file extension is not csv but will still be written as CSV.")
        }
      } else {
        readr::write_csv(this, write_to, append = TRUE, col_names = FALSE)
      }
    }

    return(this)
  }

  out <-
    origins %>%
    purrr::map_dfr(fetch_and_sleep)

  return(out)
}
