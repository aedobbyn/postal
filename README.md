
# usps 📫

[![Project Status: Active - The project has reached a stable, usable
state and is being actively
developed.](http://www.repostatus.org/badges/latest/active.svg)](http://www.repostatus.org/#active)
[![Travis build
status](https://travis-ci.org/aedobbyn/usps.svg?branch=master)](https://travis-ci.org/aedobbyn/usps)
[![Coverage
status](https://codecov.io/gh/aedobbyn/usps/branch/master/graph/badge.svg)](https://codecov.io/github/aedobbyn/usps?branch=master)

Need to get the USPS shipping zone between two zip codes? `usps`
provides a tidy interface to the [USPS domestic zone calc
API](https://postcalc.usps.com/DomesticZoneChart/).

There are `99999^2` or 9,999,800,001 possible 5-digit origin-destination
zip combinations in the US. The USPS Zone Calc tool narrows down that
search space a bit by trimming zips to their first 3 digits.

A zone is a [measure of
distance](https://ribbs.usps.gov/zone_charts/documents/tech_guides/ZoneChartExceptionsWebinar.pdf)
between the origin and the destination zip codes and are used in
determining postage rates.

### Installation

``` r
# install.packages("devtools")
devtools::install_github("aedobbyn/usps")
```

<br>

<p align="center">

<img src="https://media.giphy.com/media/iVoiJfBtSsi0o/giphy.gif" alt="owl">

</p>

### Usage

`fetch_zones` lets you find the zone corresponding to a 3-digit origin
zip prefix and one or many 3-digit destination zip prefixes.

``` r
library(usps)

fetch_zones(origin_zip = "123", 
            destination_zip = "581")
#> # A tibble: 1 x 3
#>   origin_zip dest_zip zone 
#>   <chr>      <chr>    <chr>
#> 1 123        581      6
```

If no destination is supplied, all valid desination zips and zones are
returned for the origin.

``` r
fetch_zones(origin_zip = "321")
#> # A tibble: 2,422 x 3
#>    origin_zip dest_zip zone 
#>    <chr>      <chr>    <chr>
#>  1 321        005      5    
#>  2 321        006      6    
#>  3 321        007      6    
#>  4 321        008      6    
#>  5 321        009      6    
#>  6 321        010      5    
#>  7 321        011      5    
#>  8 321        012      5    
#>  9 321        013      6    
#> 10 321        014      6    
#> # ... with 2,412 more rows
```

<br>

#### Multiple zips

You can provide a vector of zips and map them nicely into a long
dataframe. Here we ask for all destination zips for these three origin
zips.

If an origin zip is supplied that is [not in
use](https://en.wikipedia.org/wiki/List_of_ZIP_code_prefixes), it is
messaged and included in the output with `NA`s in the other columns. For
example, the origin `"001"` is not a valid 3-digit zip prefix.

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
dataframe. `verbose` gives you a play-by-play if you want it. (More on
auto-prepending leading 0s to input zips in the Digits section below.)

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
of postage the zone designation applies to.

``` r
fetch_zones(origin_zip = "404",
            show_details = TRUE)  
#> # A tibble: 2,422 x 6
#>    origin_zip dest_zip zone  specific_to_prior… same_ndc has_five_digit_e…
#>    <chr>      <chr>    <chr> <lgl>              <lgl>    <lgl>            
#>  1 404        005      4     FALSE              FALSE    FALSE            
#>  2 404        006      7     FALSE              FALSE    FALSE            
#>  3 404        007      7     FALSE              FALSE    FALSE            
#>  4 404        008      7     FALSE              FALSE    FALSE            
#>  5 404        009      7     FALSE              FALSE    FALSE            
#>  6 404        010      5     FALSE              FALSE    FALSE            
#>  7 404        011      5     FALSE              FALSE    FALSE            
#>  8 404        012      5     FALSE              FALSE    FALSE            
#>  9 404        013      5     FALSE              FALSE    FALSE            
#> 10 404        014      5     FALSE              FALSE    FALSE            
#> # ... with 2,412 more rows
```

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

The API endpoint used in `fetch_zones` accepts exactly 3 digits for the
origin zip; it mostly returns 3 digit destination zips, but also some 5
digit exceptions. For that reason,

  - If *fewer than 3 digits* are supplied, leading zeroes are added with
    a message
      - e.g. `"08"` becomes `"008"`
  - If *more than 5 digits* are supplied, the zip is truncated to the
    first 5 with a warning
      - If the zip is an origin, only the first 3 of those 5 digits are
        sent to the API
      - If the zip is a destination, the `exact_destination` flag
        determines whether we results for the that destination’s 3-digit
        prefix filter or filter to only the exact 5-digit destination

For example, when a 5-digit destination is supplied and
`exact_destination` is `FALSE`, we include results for the destination
`962` as well as for the exact one supplied, `96240`.

``` r
fetch_zones(origin_zip = "12358132134558", 
            destination_zip = "96240",
            exact_destination = FALSE)     
#> Warning in prep_zip(.): Zip can be at most 5 characters; trimming
#> 12358132134558 to 12358.
#> # A tibble: 2 x 3
#>   origin_zip dest_zip zone 
#>   <chr>      <chr>    <chr>
#> 1 123        962      8    
#> 2 123        96240    5
```

When `exact_destination` is `TRUE`, we filter only to `96240`, which is
a 5 digit exception as its zone is different from its 3-digit prefix’s.

``` r
fetch_zones(origin_zip = "12358132134558", 
            destination_zip = "96240",
            exact_destination = TRUE)  
#> Warning in prep_zip(.): Zip can be at most 5 characters; trimming
#> 12358132134558 to 12358.
#> # A tibble: 1 x 3
#>   origin_zip dest_zip zone 
#>   <chr>      <chr>    <chr>
#> 1 123        96240    5
```

<br>

#### I just want to supply 5 digits

`fetch_zones` should cover most 5 digit cases and supply the most
information when `show_details` is `TRUE`. But if you just want to use
the equivalent of the [“Get Zone for ZIP Code
Pair”](https://postcalc.usps.com/DomesticZoneChart/) tab, you can use
`fetch_five_digit`.

``` r
fetch_five_digit("31415", "92653")
#> # A tibble: 1 x 3
#>   origin_zip dest_zip zone 
#>   <chr>      <chr>    <chr>
#> 1 31415      92653    8
```

Details given when `show_details = TRUE` in `fetch_five_digit` are
slightly different than they are for `fetch_zones`.

<br>

### All of the data

If you want the most up-to-date zip-zone mappings, `fetch_all` allows
you to use the 3 digit endpoint to fetch all possible origins and,
optionally, write them to a CSV as you go.

By default we use every possible origin from `"000"` to `"999"`; as of
now `"000"` through `"004"` are all not in use along with a smattering
of others like `"404"` and `"867"` – but who knows, they might be used
in the future.

``` r
fetch_all(all_possible_origins,
          sleep_time = 0.5,   # How long to sleep in between requests, on average
          write_to = "path/to/my/file.csv")
```

If there’s a network error when grabbing a zip, we back off and try a
few times and finally write `"no_success"` (rather than `NA`s which
indicate that the origin zip is not in use) in the destination zip
columns.

What that looks like in the event we switch on the internet between
asking for origin `"123"` and origin `"456"`:

    #> # A tibble: 8 x 3
    #>   origin_zip dest_zip   zone      
    #>   <chr>      <chr>      <chr>     
    #> 1 123        no_success no_success
    #> 2 456        005        4         
    #> 3 456        006        7         
    #> 4 456        007        7         
    #> 5 456        008        7         
    #> 6 456        009        7         
    #> 7 456        010        4         
    #> 8 ...        ...        ...

<br>

#### Well, not all of it

The `zips_zones` dataset included in this package contains a 1,000,000
row sample of all the 3 digit origin-destination pairs. You can access
it with:

``` r
data(zips_zones)
```

It’s what you’d get by running `fetch_all(show_details = TRUE)`, waiting
a while, and then taking a sample.

``` r
zips_zones
#> # A tibble: 1,000,000 x 6
#>    origin_zip dest_zip  zone specific_to_prior… same_ndc has_five_digit_e…
#>    <chr>      <chr>    <int> <lgl>              <lgl>    <lgl>            
#>  1 003        <NA>        NA NA                 NA       NA               
#>  2 004        <NA>        NA NA                 NA       NA               
#>  3 005        012          2 FALSE              FALSE    FALSE            
#>  4 005        027          2 FALSE              FALSE    FALSE            
#>  5 005        028          2 FALSE              FALSE    FALSE            
#>  6 005        030          3 FALSE              FALSE    FALSE            
#>  7 005        042          3 FALSE              FALSE    FALSE            
#>  8 005        044          4 FALSE              FALSE    FALSE            
#>  9 005        051          3 FALSE              FALSE    FALSE            
#> 10 005        053          3 FALSE              FALSE    FALSE            
#> # ... with 999,990 more rows
```

The sample is about a quarter of the total number of rows between all
origin prefixes and all destination prefixes, plus the 5 digit
exceptions (3,804,494 rows). See it put to use in the
[vignette](https://github.com/aedobbyn/usps/blob/dev/vignettes/getting-zoned.Rmd).

<br>

That’s it\! [Bug reports](https://github.com/aedobbyn/usps/issues) and
PRs
welcome\!

<p align="center">

<img src="https://media.giphy.com/media/2fTYDdciZFEKZJgY7g/giphy.gif" alt="dog">

</p>
