#' Clean the response from fetched mail
#'
#' @param tbl A tibble; the result of a call to \code{\link{fetch_mail_flat_rate}} or \code{\link{fetch_mail_package}}.
#'
#' @details This scrubber converts "Not available"s to \code{NA}s, removes dollar signs from prices and converts them to numeric, and splits \code{delivery_day} into YYYY-MM-DD \code{delivery_date} and \code{delivery_by_time} (if present, the time of day by which the mail should arrive).
#'
#' \code{delivery_date} is inferred from the current year.
#'
#' @importFrom magrittr %>%
#'
#' @examples \dontrun{
#'
#' fetch_mail_flat_rate(origin_zip = "60647",
#'          destination_zip = "11238", type = "envelope") %>% scrub_mail()
#' }
#'
#' @return A tibble with the same number of rows the input. \code{delivery_day} becomes \code{delivery_date} and \code{delivery_by_time}, from which \code{delivery_duration} in days is calculated (\code{delivery_date - shipping_date}).
#' @export
#'

scrub_mail <- function(tbl) {
  out <-
    tbl %>%
    purrr::map_dfr(
      stringr::str_replace_all,
      "Not available", NA_character_
    ) %>%
    purrr::map_dfr(
      dplyr::na_if,
      ""
    ) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      retail_price = retail_price %>%
        stringr::str_replace_all("\\$", "") %>%
        as.numeric(),

      click_n_ship_price = click_n_ship_price %>%
        stringr::str_replace_all("\\$", "") %>%
        as.numeric(),

      delivery_date = delivery_day %>%
        extract_dates(),

      delivery_by_time = delivery_day %>%
        stringr::str_extract("by [A-Za-z0-9: ]+") %>%
        stringr::str_replace_all("by ", ""),

      delivery_duration = delivery_date - lubridate::as_date(shipping_date)
    ) %>%
    dplyr::ungroup() %>%
    dplyr::select(-delivery_day) %>%
    dplyr::select(
      origin_zip, dest_zip, title,
      delivery_date, delivery_by_time,
      delivery_duration,
      retail_price, click_n_ship_price,
      dplyr::everything()
    )

  return(out)
}
