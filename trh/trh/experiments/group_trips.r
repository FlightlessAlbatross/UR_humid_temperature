library(sf)
library(data.table)
library(lubridate)
source("./trh/trh_plotting/plot_points_static.R")
source("./trh/trh_plotting/plot_temperature.R")


trh_utrecht <-  "./data/cleaned/trh/utrecht.geojson"

observations <- data.table(st_read(trh_utrecht))

observations <- observations[observations$resultTime < "2024-10-01 00:00:00 CET" & 
                             observations$resultTime > "2024-06-30 23:59:59 CET" ]

observations <- observations[order(resultTime)]

observations <- observations [ , resultTime_diff     := c(NA, make_difftime(diff(resultTime), units = "seconds")), .(type, device_id)]
# observations <- observations [ , phenomenonTime_diff :=  c(NA, diff(phenomenonTime)), .(type, device_id)]


testcase <- observations[type == 'temperature' & device_id == '88901ccb-88c0-435a-af7f-fb37fc890bcb']
threshold <- 15 * 60

testcase[, trip_id = cumsum(is.na(resultTime_diff) | resultTime_diff > threshold), .(type, device_id)]

observations[, trip_id := .GRP * 100000 + cumsum(is.na(resultTime_diff) | resultTime_diff > threshold), by = .(type, device_id)]

observations[, trip_number_obs := .N , .(trip_id, type)]

observations[, trip_duration := diff(range(resultTime)), .(trip_id, type)]

plot_points_static(observations[trip_id == 100001])



plot_temperature(observations[trip_id == 100001, .(time = resultTime,temperature = value)])

temperature <- observations[type == 'temperature',.(time = resultTime,temperature = value) , .(trip_id, device_id)]

for (grp in unique(temperature$trip_id)){

    image_path <- paste0("./plots/temperature_", grp,".png")
    p_temp <- plot_temperature  (temperature[trip_id == grp])
    ggsave("plot.png", plot = p_temp, device = png, type = "cairo", dpi = 300)

}
