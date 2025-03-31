
utrecht_reference_1h  <- readRDS("./trh/trh_plotting/data/utrecht_reference_hourly.RDS")
utrecht_reference_10m <- readRDS("./trh/trh_plotting/data/utrecht_reference_10m.RDS")

utrecht_reference_10m <- utrecht_reference_10m[month(utrecht_reference_10m$time) %in% 7:9,]
utrecht_reference_1h  <- utrecht_reference_1h [month(utrecht_reference_1h$time) %in% 7:9,]

ggplot(mapping = aes(x = time, y = temperature)) + 
  geom_line(data = utrecht_reference_10m) + 
  geom_line(data = utrecht_reference_1h, color = 'blue')


date_selection <- seq.Date(from = as.Date("2024-08-10"), to = as.Date("2024-08-15"), by = 1)

ggplot(mapping = aes(x = time, y = temperature)) + 
  geom_line(data = subset(utrecht_reference_10m, as.Date(time) %in% date_selection) ) + 
  geom_line(data = subset(utrecht_reference_1h, as.Date(time) %in% date_selection), color = 'blue')

ggplot(mapping = aes(x = time, y = temperature)) + 
  geom_line(data = utrecht_reference_10m) + 
  geom_line(data = utrecht_reference_1h, color = 'blue')

setDT(utrecht_reference_1h)
setDT(utrecht_reference_10m)

combined <- utrecht_reference_1h[utrecht_reference_10m[ , .(time, temperature_10m = temperature, relative_humidity_10m = relative_humidity) , ], roll = "nearest", on = c("time")]
ggplot(combined, aes(x = temperature, y = temperature_10m)) + geom_point() + geom_smooth()
