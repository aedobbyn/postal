
test <- "https://postcalc.usps.com/Calculator/GetMailServices?countryID=0&countryCode=US&origin=60647&isOrigMil=False&destination=11238&isDestMil=False&shippingDate=6%2F22%2F2018+12%3A00%3A00+AM&shippingTime=14%3A29&itemValue=&dayOldPoultry=False&groundTransportation=False&hazmat=False&liveAnimals=False&nonnegotiableDocument=False&mailShapeAndSize=Package&pounds=15&ounces=0&length=0&height=0&width=0&girth=0&shape=Rectangular&nonmachinable=False&isEmbedded=False"

fj <- jsonlite::fromJSON(test)

fj2 <-
  fj$Page$MailServices %>%
  tibble::as_tibble() %>%
  dplyr::select(-ImageURL)

fj3 <-
  fj2 %>%
  map_df(dobtools::replace_x) %>%
  tidyr::unnest(DeliveryOptions)


bind_d_o <- function() {
  out <- NULL
  for (i in seq_along(fj$Page$MailServices$DeliveryOptions)) {
    print(i)
    out <- out %>%
      bind_rows(fj$Page$MailServices$DeliveryOptions[[i]])
  }
  return(out)
}


