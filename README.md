
# usps 📫

Need to get the USPS shipping zone for two zip codes? `usps` provides a
tidy interface to the [USPS domestic zone calc
API](https://postcalc.usps.com/DomesticZoneChart/).

### Installation Instructions

``` r
if (!require("devtools")) install.packages("devtools")
devtools::install_github('aedobbyn/usps')
```

<br>

<p align="center">

<img src="https://media.giphy.com/media/iVoiJfBtSsi0o/giphy.gif" alt="owl">

</p>

### Usage

Supply a 3-digit origin and, optionally, destination zip to find their
corresponding zone. If no destination is supplied, all desination zips
and their zones are returned for the origin.

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

You can provide a vector of zips and map them nicely into a dataframe.
Here we ask for all destination zips for these three origin zips.

If an origin zip is supplied that is [not in
use](https://en.wikipedia.org/wiki/List_of_ZIP_code_prefixes), it is
messaged and included in the output with `NA`s in the other columns.

The origin “004” is not a valid 3-digit zip.

``` r
origin_zips <- c("2718281828459", "04", "52353")

origin_zips %>% 
  purrr::map_dfr(fetch_zones)
#> Warning in prep_zip(.): Zip can be at most 5 characters; trimming
#> 2718281828459 to 27182.
#> Origin zip 004 is not in use.
#> # A tibble: 4,845 x 3
#>    origin_zip dest_zip zone 
#>    <chr>      <chr>    <chr>
#>  1 271        005      4    
#>  2 271        006      7    
#>  3 271        007      7    
#>  4 271        008      7    
#>  5 271        009      7    
#>  6 271        010      4    
#>  7 271        011      4    
#>  8 271        012      4    
#>  9 271        013      4    
#> 10 271        014      4    
#> # ... with 4,835 more rows
```

Similarly, map over both origin and destination zips and end up at a
dataframe:

``` r
dest_zips <- c("867", "53", "09")

purrr::map2_dfr(origin_zips, dest_zips, 
                fetch_zones,
                verbose = TRUE)
#> Warning in prep_zip(.): Zip can be at most 5 characters; trimming
#> 2718281828459 to 27182.
#> Only 3-character origin zips can be sent to the API. Zip 27182 will be requested as 271.
#> Grabbing origin ZIP 271
#> Recieved 994 destination ZIPs for 8 zones.
#> No zones found for the 271 to 867 pair.
#> Grabbing origin ZIP 004
#> Origin zip 004 is not in use.
#> Only 3-character origin zips can be sent to the API. Zip 52353 will be requested as 523.
#> Grabbing origin ZIP 523
#> Recieved 994 destination ZIPs for 8 zones.
#> # A tibble: 2 x 3
#>   origin_zip dest_zip zone 
#>   <chr>      <chr>    <chr>
#> 1 004        <NA>     <NA> 
#> 2 523        009      8
```

<br> <br>

#### Ranges and other features

The USPS zone calc web interface displays zones only as they pertain to
destination zip code *ranges*:

<p align="center">

<img src="./img/post_calc.jpg" alt="post_calc" width="70%">

</p>

<br>

If you prefer the range representation, you can set `as_range = TRUE`.
Instead of a `dest_zip` column, you’ll get a marker of the beginning of
and end of the range range in `dest_zip_start` and `dest_zip_end`.

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
      - This API endpoint accepts exactly 3 digit origin zips; it mostly
        returns 3 digit destination zips, but notes 5 digit exceptions.
        For that reason,
      - If fewer than three digits are supplied, leading zeroes are
        added with a message
      - If more than five digits are supplied, the zip is truncated to
        the first five with a warning
          - The first three digits of the origin zip are sent to the API
          - If destination is supplied, we filter the results to the
            first 3 digits if `exact_destination` is `FALSE`; otherwise
            we return only the exact destination

<!-- end list -->

``` r
fetch_zones(origin_zip = "12358132134558", 
            destination_zip = "91442",
            show_details = TRUE)     
#> Warning in prep_zip(.): Zip can be at most 5 characters; trimming
#> 12358132134558 to 12358.
#> # A tibble: 1 x 6
#>   origin_zip dest_zip zone  specific_to_prior… same_ndc has_five_digit_ex…
#>   <chr>      <chr>    <chr> <lgl>              <chr>    <chr>             
#> 1 123        914      8     FALSE              FALSE    FALSE
```

<br>

#### 5 digits

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

<br>

Bug reports and PRs
welcome\!

<p align="center">

<img src="https://media.giphy.com/media/2fTYDdciZFEKZJgY7g/giphy.gif" alt="dog">

</p>
