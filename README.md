
# usps

A tidy interface to the USPS API.

### Installation Instructions

`if (!require("devtools"))
install.packages("devtools")`

`devtools::install_github('aedobbyn/usps')`

<br>

<p align="center">

<img src="https://media.giphy.com/media/iVoiJfBtSsi0o/giphy.gif" alt="owl">

</p>

### Usage

``` r
library(usps)

purrr::map_dfr(c(1, "007", 123), grab_zone_from_origin)
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
