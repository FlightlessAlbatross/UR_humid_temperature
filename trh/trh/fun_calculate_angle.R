
# calculate angle between points

angle_between_points_vectorized <- function(x1, y1, x2, y2, x3, y3) {
  # Compute vectors A and B
  A_x <- x1 - x2
  A_y <- y1 - y2
  B_x <- x3 - x2
  B_y <- y3 - y2
  
  # Compute dot product
  dot_product <- A_x * B_x + A_y * B_y
  
  # Compute magnitudes
  mag_A <- sqrt(A_x^2 + A_y^2)
  mag_B <- sqrt(B_x^2 + B_y^2)
  
  # Compute angle in radians
  theta <- acos(pmax(pmin(dot_product / (mag_A * mag_B), 1), -1))  # Ensure values are in [-1,1] range
  
  # Convert to degrees
  theta_degrees <- theta * (180 / pi)
  
  return(theta_degrees)
}




angle_between_points_sf <- function(geometry){
  # This function assumes that the geometry column is ordered
  
  if(length(geometry) < 3) {

    return(rep(NA, length(geometry)))
  }
  
  
  coords <- st_coordinates(geometry)
  x <- coords[,1]
  y <- coords[,2]
  
  # get the indices of 3 consecutive observations with which we calculate the angle
  fulcrum_index <- 2:(length(geometry) - 1)
  lag_index <- fulcrum_index-1
  lead_index  <- fulcrum_index+1
  
  
  angles <- angle_between_points_vectorized(
    x[lag_index],y[lag_index], x[fulcrum_index], y[fulcrum_index], x[lead_index], y[lead_index]
  )
  output <- c(NA,angles,NA)
  stopifnot(length(output) == length(geometry))
  return(output)
  
}


index_to_remove_acute_angle_iterative <- function(x, angle_threshold = 50) {
  
  data <- x
  
  data$id <- 1:nrow(x)
  
  low_angle <- T # initialize
  
  while(any(low_angle)) {
    
    low_angle <- angle_between_points_sf(data$geometry) < angle_threshold
    
    low_angle[is.na(low_angle)] <- F
    
    
    data <- data[!low_angle, ]
    
  }
  
  return(! 1:nrow(x) %in% data$id   )
}

