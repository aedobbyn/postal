
test <- "https://postcalc.usps.com/Calculator/GetMailServices?countryID=0&countryCode=US&origin=60647&isOrigMil=False&destination=11238&isDestMil=False&shippingDate=6%2F22%2F2018+12%3A00%3A00+AM&shippingTime=14%3A29&itemValue=&dayOldPoultry=False&groundTransportation=False&hazmat=False&liveAnimals=False&nonnegotiableDocument=False&mailShapeAndSize=Package&pounds=15&ounces=0&length=0&height=0&width=0&girth=0&shape=Rectangular&nonmachinable=False&isEmbedded=False"

lst <- jsonlite::fromJSON(test)

nested <-
  fj$Page$MailServices %>%
  tibble::as_tibble() %>%
  dplyr::select(-ImageURL)

unnested <-
  fj2 %>%
  map_df(dobtools::replace_x) %>%
  tidyr::unnest(DeliveryOptions)


country_id = 0
country_code = "US"
origin_zip = 60647
destination_zip = 11238
shipping_date = "6%2F22%2F2018+12%3A00%3A00+AM"
shipping_time = "14%3A29"
ground_transportation = "False"
pounds = 15
ounces = 0
length = 0
height = 0
width = 0
girth = 0
shape = "Rectangular"


get_mail <- function(country_id = 0,
                     country_code = "US",
                     origin_zip = NULL,
                     destination_zip = NULL,
                     shipping_date = "6%2F22%2F2018+12%3A00%3A00+AM",
                     shipping_time = "14%3A29",
                     ground_transportation = "False",
                     pounds = NULL,
                     ounces = 0,
                     length = 0,
                     height = 0,
                     width = 0,
                     girth = 0,
                     shape = "Rectangular") {

full_url <- glue::glue("https://postcalc.usps.com/Calculator/GetMailServices?countryID={country_id}&countryCode={country_code}&origin={origin_zip}&isOrigMil=False&destination={destination_zip}&isDestMil=False&shippingDate={shipping_date}&shippingTime={shipping_time}&itemValue=&dayOldPoultry=False&groundTransportation={ground_transportation}&hazmat=False&liveAnimals=False&nonnegotiableDocument=False&mailShapeAndSize=Package&pounds={pounds}&ounces={ounces}&length={length}&height={height}&width={width}&girth={girth}&shape={shape}&nonmachinable=False&isEmbedded=False")

  lst <- jsonlite::fromJSON(full_url)

  nested <-
    lst$Page$MailServices %>%
    tibble::as_tibble() %>%
    dplyr::select(-ImageURL)

  unnested <-
    nested %>%
    map_df(dobtools::replace_x) %>%
    tidyr::unnest(DeliveryOptions)

  return(unnested)
}

get_mail(origin_zip = 60647,
         destination_zip = 11238,
         pounds = 15)
