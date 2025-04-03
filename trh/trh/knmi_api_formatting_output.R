setwd("C:/Users/hofer/Documents/urbanreleaf/UR_humid_temperature")

library(jsonlite)

kmni_api_folder_path <- "./data/raw/weather/kmni_api/"
reference_out_file <- "./trh/trh_plotting/data/utrecht_reference_10m.RDS"

# dir.create(dirname(temperature_out_file), recursive = T)

x <- lapply(list.files(kmni_api_folder_path,full.names = T), fromJSON)

names(x) <- sapply(strsplit(list.files(kmni_api_folder_path,full.names = F), split = '_'), '[', 1)

format_variable <- function(x, var_id){
time   <- x$coverages$domain$axes$t$values[[1]]
desc   <- x$parameters[[var_id]]$description$en
name   <- x$parameters[[var_id]]$`eumetnet:standard_name`
unit   <- x$parameters[[var_id]]$unit$label$en
values <- x$coverages$ranges[[var_id]]$values[[1]]

out <- data.frame(name, desc, unit, time, values)
return(out)
}

d <- format_variable(x[['temperature']], 'tgn')

d <- d[order(d$time),]
# There is an overlap from when we requested the data by time window. One observation overlaps between the separate queries. 
d <- d[!duplicated(d),]
d$time <- lubridate::as_datetime(d$time)

out_temperature <- d[d$name == 'air_temperature', c('time', 'values')]
names(out_temperature) <- c('time', 'temperature')


# 
d <- format_variable(x[['dewpoint']], 'td')
d <- d[order(d$time),]
d <- d[!duplicated(d),]
d$time <- lubridate::as_datetime(d$time)
out_dewpoint <- d[d$name == 'dew_point_temperature', c('time', 'values')]
names(out_dewpoint) <- c('time', 'dewpoint_temperature')

combined <- merge(out_dewpoint, out_temperature, by = c('time'))

# use August-Roche-Magnus approximation to get relative humidity
august_roche_magnus <- function(temperature, dewpoint_temperature){
  
  e_s <- 6.112 * exp(  (17.67*         temperature) / (         temperature + 243.5)  )
  e   <- 6.112 * exp(  (17.67*dewpoint_temperature) / (dewpoint_temperature + 243.5)  )
  
  rh <- 100*e/e_s
  rh
}

combined$relative_humidity <- august_roche_magnus(combined$temperature, combined$dewpoint_temperature)

out_trh <-combined[,c("time", "temperature", "relative_humidity") ]

saveRDS(out_trh, file = reference_out_file)
