# add the trips 


add_trips <- function(data, trip_lenght_seconds = 5*60, time_column = 'time'){

    if ( ! "data.table" %in% class(data) ){
        error('data needs to be of class data.table')
    }

    threshold <- trip_lenght_seconds
    data <- data [ , time_diff     := c(NA, make_difftime(diff(get(time_column)), units = "seconds")), .(type, device_id)]
    
    data[, trip_id := .GRP * 100000 + cumsum(is.na(time_diff) | time_diff > threshold), by = .(device_id)]
    data$time_diff <- NULL
    data
}
