
# usps 📫

Need to get the USPS shipping zone for two zip codes? `usps` provides a
tidy interface to the [USPS zone calc
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

Supply an origin and, optionally, a destination zip to find their
corresponding zone.

``` r
library(usps)

fetch_zones(origin_zip = "123", 
            destination_zip = "581")
#> # A tibble: 1 x 3
#>   origin_zip dest_zip zone 
#>   <chr>      <chr>    <chr>
#> 1 123        581      6
```

#### Details

  - If no destination is supplied, all desination zips and their zones
    are returned for the origin
  - If an origin zip is supplied that is [not in
    use](https://en.wikipedia.org/wiki/List_of_ZIP_code_prefixes), it is
    messaged and included in the output with `NA`s in the other columns
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
            destination_zip = "91442")     
#> Warning in prep_zip(., verbose = verbose): Zip can be at most 5 characters.
#> Trimming 12358132134558 to 12358.
#> # A tibble: 1 x 3
#>   origin_zip dest_zip zone 
#>   <chr>      <chr>    <chr>
#> 1 123        914      8
```

<br>

#### Multiple zips

You can provide a vector of zips and map them nicely into a dataframe.
Here we ask for all destination zips for these three origin zips.

<!-- The origin "001" is not a valid 3-digit zip. -->

``` r
origin_zips <- c("271", "8281828459", "045235")

origin_zips %>% 
  purrr::map_dfr(fetch_zones)
#> Warning in prep_zip(., verbose = verbose): Zip can be at most 5 characters.
#> Trimming 8281828459 to 82818.
#> Warning in prep_zip(., verbose = verbose): Zip can be at most 5 characters.
#> Trimming 045235 to 04523.
#> # A tibble: 7,266 x 3
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
#> # ... with 7,256 more rows
```

Similarly, map over both origin and destination zips and end up at a
dataframe:

``` r
dest_zips <- c("867", "53", "09")

purrr::map2_dfr(origin_zips, dest_zips, 
                fetch_zones,
                verbose = TRUE)
#> Grabbing origin ZIP 271
#> Recieved 994 destination ZIPs for 8 zones.
#> No zones found for the 271 to 867 pair.
#> Only 3 characters can be sent to the API. Zip 8281828459 will be requested as 828.
#> Warning in prep_zip(., verbose = verbose): Zip can be at most 5 characters.
#> Trimming 8281828459 to 82818.
#> Grabbing origin ZIP 828
#> Recieved 994 destination ZIPs for 8 zones.
#> Only 3 characters can be sent to the API. Zip 045235 will be requested as 045.
#> Warning in prep_zip(., verbose = verbose): Zip can be at most 5 characters.
#> Trimming 045235 to 04523.
#> Grabbing origin ZIP 045
#> Recieved 994 destination ZIPs for 8 zones.
#> # A tibble: 2 x 3
#>   origin_zip dest_zip zone 
#>   <chr>      <chr>    <chr>
#> 1 828        053      7    
#> 2 045        009      7
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

<br>

You can optionally display other details about the zips, zones, and type
of postage it applies to.

``` r
fetch_zones("42", "42",
            as_range = TRUE, 
            show_details = TRUE)
#> # A tibble: 1 x 7
#>   origin_zip dest_zip_start dest_zip_end zone  specific_to_prior… same_ndc
#>   <chr>      <chr>          <chr>        <chr> <lgl>              <chr>   
#> 1 042        039            043          1     FALSE              TRUE    
#> # ... with 1 more variable: has_five_digit_exceptions <chr>
```

<br>

Definitions of these details can be found in `detail_definitions`.

``` r
detail_definitions %>% 
  knitr::kable()
```

| name                         | definition                                                                                                                            |
| :--------------------------- | :------------------------------------------------------------------------------------------------------------------------------------ |
| specific\_to\_priority\_mail | This zone designation applies to Priority Mail only                                                                                   |
| same\_ndc                    | The origin and destination zips are in the same Network Distribution Center                                                           |
| has\_five\_digit\_exceptions | This 3 digit destination zip prefix appears at the beginning of certain 5 digit destination zips that correspond to a different zone. |

#### 5 digits

`fetch_zones` should cover most 5 digit cases and supply the most
information when `show_details` is `TRUE`, but if you just want to use
the equivalent of the [“Get Zone for ZIP Code
Pair”](https://postcalc.usps.com/DomesticZoneChart/) tab, you can use
`fetch_five_digit`.

``` r
fetch_five_digit("31415", "92653")
#> # A tibble: 1 x 4
#>   origin_zip destination_zip zone  full_response                          
#>   <chr>      <chr>           <chr> <chr>                                  
#> 1 31415      92653           8     The Zone is 8. This is not a Local Zon…
```

<br>

Bug reports and PRs
welcome\!

<p align="center">

<img src="https://media.giphy.com/media/2fTYDdciZFEKZJgY7g/giphy.gif" alt="dog">

</p>
