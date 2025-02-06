library(sf)
library(data.table)
library(lubridate)


# Load reference temperature data
reference_data_path <- "./trh/trh_plotting/data/utrecht_reference.RDS"

all_reference_data <- data.table(readRDS(reference_data_path))

# Ensure proper datetime format
all_reference_data[, time := as.POSIXct(time, tz = "CET")]

# Reshape to long format
all_reference_data <- melt.data.table(all_reference_data, id.vars = "time", 
                                      variable.name = "type", value.name = "value_reference")

# Load observations

trh_utrecht <- "./data/cleaned/trh/utrecht.geojson"
observations <- data.table(st_read(trh_utrecht))

output_path <- "./data/cleaned/trh/utrecht_trips.geojson"

# Filter date range
observations <- observations[resultTime < as.POSIXct("2024-10-01 00:00:00", tz = "CET") & 
                             resultTime > as.POSIXct("2024-06-30 23:59:59", tz = "CET")]

# Ensure 'type' is a factor and matches reference data
observations[, type := factor(type, levels = unique(all_reference_data$type))]

# Set keys for fast merging
setkey(observations, type, resultTime)
setkey(all_reference_data, type, time)

# Merge using rolling join to get the nearest reference temperature
observations <- all_reference_data[observations, roll = "nearest", on = c("type" = "type", "time" = "resultTime" )]
data[is.na(type)]$type <- 'thermal_stress'

observations[ , value_delta := value - value_reference, ]

output <- st_as_sf(observations[,.(X.iot.id, device_id, type, time, value, value_reference, geometry)])
st_write(output, dsn = output_path, delete_dsn = TRUE)



