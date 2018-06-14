
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

Supply an origin and, optionally, a destination zip as character or
numeric.

``` r
library(usps)

fetch_zones(origin_zip = "123", 
            destination_zip = "581")
#> # A tibble: 1 x 3
#>   origin_zip dest_zip zone 
#>   <chr>      <chr>    <chr>
#> 1 123        581      6
```

If no destination is supplied, all desination zips and their zones are
returned.

<br>

#### Multiple origins

You can provide a vector of zips and map them nicely into a dataframe.

Rows corresponding to origin zones that are not in use get `NA`s in
their destination and zone columns.

``` r
origin_zips <- c(1, "007", 123)

origin_zips %>% 
  purrr::map_dfr(fetch_zones)
#> Origin zip 001 is not in use.
#> # A tibble: 1,861 x 3
#>    origin_zip dest_zip zone 
#>    <chr>      <chr>    <chr>
#>  1 001        <NA>     <NA> 
#>  2 007        005      7    
#>  3 007        006      1    
#>  4 007        007      1    
#>  5 007        008      1    
#>  6 007        009      1    
#>  7 007        010      7    
#>  8 007        011      7    
#>  9 007        012      7    
#> 10 007        013      7    
#> # ... with 1,851 more rows
```

Map over both origin and destination zips and end up at a dataframe:

``` r
dest_zips <- c("867", "53", "09")

purrr::map2_dfr(origin_zips, dest_zips, 
                fetch_zones)
#> Origin zip 001 is not in use.
#> # A tibble: 2 x 3
#>   origin_zip dest_zip zone 
#>   <chr>      <chr>    <chr>
#> 1 007        053      7    
#> 2 123        009      7
```

<br> <br>

#### Ranges

The USPS web interface defaults to destination zip code ranges:

<p align="center">

<img src="./img/post_calc.jpg" alt="post_calc">

</p>

<br>

which you can ask for by setting `as_range = TRUE`. Instead of a
`dest_zip` column, you’ll get a marker of the beginning of and end of
the range range in `dest_zip_start` and `dest_zip_end`.

<br>

You can optionally display the `*` and `+` modifiers.

``` r
fetch_zones(42, 42,
            as_range = TRUE, 
            show_modifiers = TRUE)
#> # A tibble: 1 x 6
#>   origin_zip dest_zip_start dest_zip_end zone  modifier_1 modifier_2
#>   <chr>      <chr>          <chr>        <chr> <chr>      <chr>     
#> 1 042        039            043          1     *          <NA>
```

<br>

If more than three digits are supplied, the zip is truncated to the
first three with a warning.

``` r
fetch_zones(origin_zip = 1235813213455, 
            destination_zip = 89144233377)
#> Warning in prep_zip(.): zip can be at most 3 characters; trimming
#> 1235813213455 to 123.
#> Warning in prep_zip(.): zip can be at most 3 characters; trimming
#> 89144233377 to 891.
#> # A tibble: 1 x 3
#>   origin_zip dest_zip zone 
#>   <chr>      <chr>    <chr>
#> 1 123        891      8
```

Happy fetching
🐶

<p align="center">

<img src="https://media.giphy.com/media/2fTYDdciZFEKZJgY7g/giphy.gif" alt="dog">

</p>
