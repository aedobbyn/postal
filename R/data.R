#' @importFrom tibble tibble
NULL

#' Zips and Zones
#'
#' All 3-digit zips and zones. The result of running fetch_all() with \code{as_range = TRUE}.
#'
#' @format A data frame with 3,804,494 rows and 6 variables:
#' \describe{
#'   \item{origin_zip}{Origin zip}
#'   \item{dest_zip}{Destination zip}
#'   \item{zone}{weight of the diamond, in carats}
#'   \item{has_five_digit_exceptions}{Does this 3 digit zip have 5 digit zips with different zones?}
#'   \item{same_ndc}{Origin and destination in same Network Distribution Center?}
#'   \item{specific_to_priority_mail}{Zone specific to Priority Mail?}
#' }
"zips_zones"
