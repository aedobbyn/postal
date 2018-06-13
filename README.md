
# usps

A tidy interface to the USPS API.

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

``` r
library(usps)

origin_zips <- c(1, "007", 123)

origin_zips %>% 
  purrr::map_dfr(grab_zone_from_origin)
#> Grabbing origin ZIP 001
#> Origin zip 001 is not in use.
#> Grabbing origin ZIP 007
#> Recieved 994 destination ZIPs for 8 zones.
#> Grabbing origin ZIP 123
#> Recieved 994 destination ZIPs for 8 zones.
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

<br> <br>

The USPS web interface defaults to destination zip code ranges:

<p align="center">

<img src="./img/post_calc.jpg" alt="post_calc">

</p>

<br>

which you can ask for by setting `as_range`. Instead of a `dest_zip`
column, you’ll get a marker of the beginning of and end of the range
range in `dest_zip_start` and `dest_zip_end`.

<br>

You can optionally display the `*` and `+` modifiers.

``` r
grab_zone_from_origin(42, 
                      as_range = TRUE, 
                      show_modifiers = TRUE)
#> Grabbing origin ZIP 042
#> Recieved 994 destination ZIPs for 8 zones.
#> # A tibble: 127 x 6
#>    origin_zip dest_zip_start dest_zip_end zone  modifier_1 modifier_2
#>  * <chr>      <chr>          <chr>        <chr> <chr>      <chr>     
#>  1 042        005            005          3     <NA>       <NA>      
#>  2 042        006            009          7     <NA>       <NA>      
#>  3 042        010            012          3     *          <NA>      
#>  4 042        013            038          2     *          <NA>      
#>  5 042        039            043          1     *          <NA>      
#>  6 042        044            044          2     *          <NA>      
#>  7 042        045            045          1     *          <NA>      
#>  8 042        046            047          2     *          <NA>      
#>  9 042        048            048          1     *          <NA>      
#> 10 042        049            059          2     *          <NA>      
#> # ... with 117 more rows
```
