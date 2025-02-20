# look at the europlaan data
# when we look at the points colored in 'Deviation from reference' there are often clusters with very differing deviations. 
# in this script I look into that. 

# Priors: Its peoples homes. At startup gps often takes a second to orient itself. 
# Maybe the observations are at the beginning of trips?

# what do the lows have in common with each other and the highs. 
# These different observations are either a blessing OR a boon!. 

library(sf)
library(data.table)
library(lubridate)
library(dplyr)

# Load functions
source("./trh/trh_plotting/plot_points_static.R")
source("./trh/trh_plotting/plot_temperature.R")
source("./trh/trh/fun__make_trips.r")

# Load observations
trh_utrecht <- "./data/cleaned/trh/utrecht_temperature.geojson"
# trh_rosevelt <- "./data/cleaned/trh/rooseveltlaan.geojson"
euplaan_path <- "./data/cleaned/trh/explain_this/europalaan.geojson"


trh_roosevelt <- st_read(trh_rosevelt)
euplaan <- st_read(euplaan_path)


euplaan %>% group_by(device_id, trip_id) %>%
  summarise(number = n())

euplaan[ , .N , .(device_id, trip_id)]

euplaan_trips <- observations_raw[observations_raw$device_id %in% unique(euplaan$trip_id)]


# in which temperature average percentile does this sensor fall into?
euplaan_device_avg <- unique(euplaan$device_id)


observations_raw <- (st_read(trh_utrecht))
temp <- observations_raw[observations_raw$device_id != '88901ccb-88c0-435a-af7f-fb37fc890bcb' & 
                           observations_raw$type == 'temperature',]



temp <- st_as_sf( add_trips(data.table(temp)))

temp$deviation <- temp$value - temp$value_reference


# handeling table related tasks is easier with data.table
dt <- data.table(st_drop_geometry(temp), st_coordinates(temp))




plot_paths_static(euplaan, color_column = 'trip_id')

