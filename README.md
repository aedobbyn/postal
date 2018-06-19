
# usps 📫

[![Travis build
status](https://travis-ci.org/aedobbyn/usps.svg?branch=master)](https://travis-ci.org/aedobbyn/usps)
[![Coverage
status](https://codecov.io/gh/aedobbyn/usps/branch/master/graph/badge.svg)](https://codecov.io/github/aedobbyn/usps?branch=master)

Need to get the USPS shipping zone between two zip codes? `usps`
provides a tidy interface to the [USPS domestic zone calc
API](https://postcalc.usps.com/DomesticZoneChart/).

A zone is a [measure of
distance](https://ribbs.usps.gov/zone_charts/documents/tech_guides/ZoneChartExceptionsWebinar.pdf)
between the origin and the destination zip codes and are used in
determining postage rates.

### Installation

``` r
# install.packages("devtools")
devtools::install_github('aedobbyn/usps')
```

<br>

<p align="center">

<img src="https://media.giphy.com/media/iVoiJfBtSsi0o/giphy.gif" alt="owl">

</p>

### Usage

There are 99999^2 or 9.999810^{9} possible origin-destination zip
combinations. USPS narrows down that search space a bit by trimming it
it to the first 3 digits of the zip.

Supply a 3-digit origin and, optionally, destination zip prefix to find
their corresponding zone. If no destination is supplied, all desination
zips and zones are returned for the origin.

``` r
library(usps)

fetch_zones(origin_zip = "123", 
            destination_zip = "581")
#> # A tibble: 1 x 3
#>   origin_zip dest_zip zone 
#>   <chr>      <chr>    <chr>
#> 1 123        581      6
```

<br>

#### Multiple zips

You can provide a vector of zips and map them nicely into a long
dataframe. Here we ask for all destination zips for these three origin
zips.

If an origin zip is supplied that is [not in
use](https://en.wikipedia.org/wiki/List_of_ZIP_code_prefixes), it is
messaged and included in the output with `NA`s in the other columns. For
example, the origin “001” is not a valid 3-digit zip.

``` r
origin_zips <- c("001", "271", "828")

origin_zips %>% 
  purrr::map_dfr(fetch_zones)
#> Origin zip 001 is not in use.
#> # A tibble: 4,845 x 3
#>    origin_zip dest_zip zone 
#>    <chr>      <chr>    <chr>
#>  1 001        <NA>     <NA> 
#>  2 271        005      4    
#>  3 271        006      7    
#>  4 271        007      7    
#>  5 271        008      7    
#>  6 271        009      7    
#>  7 271        010      4    
#>  8 271        011      4    
#>  9 271        012      4    
#> 10 271        013      4    
#> # ... with 4,835 more rows
```

Similarly, map over both origin and destination zips and end up at a
dataframe. `verbose` gives you a play-by-play if you want it.

``` r
dest_zips <- c("867", "53", "09")

purrr::map2_dfr(origin_zips, dest_zips, 
                fetch_zones,
                verbose = TRUE)
#> Grabbing origin ZIP 001
#> Origin zip 001 is not in use.
#> Grabbing origin ZIP 271
#> Recieved 994 destination ZIPs for 8 zones.
#> Grabbing origin ZIP 828
#> Recieved 994 destination ZIPs for 8 zones.
#> # A tibble: 3 x 3
#>   origin_zip dest_zip zone 
#>   <chr>      <chr>    <chr>
#> 1 001        <NA>     <NA> 
#> 2 271        053      5    
#> 3 828        009      8
```

<br> <br>

#### Ranges and other features

The USPS zone calc web interface displays zones only as they pertain to
destination zip code *ranges*:

<p align="center">

<img src="./man/figures/post_calc.jpg" alt="post_calc" width="70%">

</p>

<br>

If you prefer the range representation, you can set `as_range = TRUE`.
Instead of a `dest_zip` column, you’ll get a marker of the beginning of
and end of the range in `dest_zip_start` and `dest_zip_end`.

``` r
fetch_zones("42", "42",
            as_range = TRUE)
#> # A tibble: 1 x 4
#>   origin_zip dest_zip_start dest_zip_end zone 
#>   <chr>      <chr>          <chr>        <chr>
#> 1 042        039            043          1
```

<br>

### Details

You can optionally display other details about the zips, zones, and type
of postage it applies to.

Definitions of these details can be found in `detail_definitions`.

``` r
detail_definitions %>% 
  knitr::kable()
```

| name                         | definition                                                                                                                            |
| :--------------------------- | :------------------------------------------------------------------------------------------------------------------------------------ |
| specific\_to\_priority\_mail | This 5 digit zone designation applies to Priority Mail only; for Standard, refer to the 3 digit zone designation.                     |
| same\_ndc                    | The origin and destination zips are in the same Network Distribution Center.                                                          |
| has\_five\_digit\_exceptions | This 3 digit destination zip prefix appears at the beginning of certain 5 digit destination zips that correspond to a different zone. |

<br>

### On Digits

#### The Nitpicky

  - Number of digits:
      - This API endpoint used in `fetch_zones` accepts exactly 3 digits
        for the origin zip; it mostly returns 3 digit destination zips,
        but notes 5 digit exceptions. For that reason,
      - If fewer than three digits are supplied, leading zeroes are
        added with a message
      - If more than five digits are supplied, the zip is truncated to
        the first five with a warning
          - The first three digits of the origin zip are sent to the API
          - If destination and is 5 digits, `exact_destination`
            determines whether we filter to the 5-digit destination only
            or include results for the 3-digit destination prefix

<!-- end list -->

``` r
fetch_zones(origin_zip = "12358132134558", 
            destination_zip = "91442",
            show_details = TRUE)     
#> Warning in prep_zip(.): Zip can be at most 5 characters; trimming
#> 12358132134558 to 12358.
#> # A tibble: 1 x 6
#>   origin_zip dest_zip zone  specific_to_prior… same_ndc has_five_digit_ex…
#>   <chr>      <chr>    <chr> <lgl>              <lgl>    <lgl>             
#> 1 123        914      8     FALSE              FALSE    FALSE
```

Consider as opposed to:

``` r
fetch_zones(origin_zip = "12358132134558", 
            destination_zip = "91442",
            show_details = TRUE,
            exact_destination = TRUE)  
#> Warning in prep_zip(.): Zip can be at most 5 characters; trimming
#> 12358132134558 to 12358.
#> # A tibble: 0 x 6
#> # ... with 6 variables: origin_zip <chr>, dest_zip <chr>, zone <chr>,
#> #   specific_to_priority_mail <lgl>, same_ndc <lgl>,
#> #   has_five_digit_exceptions <lgl>
```

<br>

#### I just want to supply 5 digits

`fetch_zones` should cover most 5 digit cases and supply the most
information when `show_details` is `TRUE`, but if you just want to use
the equivalent of the [“Get Zone for ZIP Code
Pair”](https://postcalc.usps.com/DomesticZoneChart/) tab, you can use
`fetch_five_digit`.

``` r
fetch_five_digit("31415", "92653",
                 show_details = TRUE)
#> # A tibble: 1 x 7
#>   origin_zip dest_zip zone  priority_mail_zo… local same_ndc full_response
#>   <chr>      <chr>    <chr> <chr>             <lgl> <lgl>    <chr>        
#> 1 31415      92653    8     <NA>              FALSE FALSE    The Zone is …
```

Details in `fetch_five_digit` are slightly different than in
`fetch_zones`.

<br>

### All of the data

If you want the most up-to-date zip-zone mappings, `fetch_all` allows
you to use the 3 digit endpoint to fetch all possible origins and write
them to a CSV as you go.

By default we use every possible origin from “000” to “999”; as of now
“000” through “004” are all not in use.

``` r
fetch_all(all_possible_origins,
          sleep_time = 0.5, 
          write_to = glue::glue(here::here("data", "{Sys.Date()}_all_my_zones.csv")))
```

If there’s a network error, we back off and try a few times and finally
write “no\_success” (rather than `NA`s which indicate that the origin
zip is not in use). What that looks like in the event we get internet
between asking for origin “123” and origin “456”:

    #> # A tibble: 8 x 3
    #>   origin dest       zip       
    #>   <chr>  <chr>      <chr>     
    #> 1 123    no_success no_success
    #> 2 456    005        4         
    #> 3 456    006        7         
    #> 4 456    007        7         
    #> 5 456    008        7         
    #> 6 456    009        7         
    #> 7 456    010        4         
    #> 8 ...    ...        ...

<br>

Bug reports and PRs
welcome\!

<p align="center">

<img src="https://media.giphy.com/media/2fTYDdciZFEKZJgY7g/giphy.gif" alt="dog">

</p>
