


# Load required packages
library(ggplot2)

# setwd("C:/Users/hofer/Documents/urbanreleaf/UR_humid_temperature/trh/trh_plotting")
# Path to the reference data (as .rds)
reference_data_path <- "./data/utrecht_reference.RDS"


# Define a function to load reference data selectively
load_reference_data <- function(start_time, end_time) {
  all_reference_data <- readRDS(reference_data_path)
  filtered_reference_data <- all_reference_data[all_reference_data$time >= start_time & all_reference_data$time <= end_time, ]
  return(filtered_reference_data)
}

# Define the function for plotting temperature data
plot_temperature <- function(temp_data) {
  
  # Ensure data are in the correct format
  if (!all(c("time", "temperature") %in% names(temp_data))) {
    stop("temp_data must have 'time' and 'temperature' columns.")
  }
  
  # Determine the time range from temp_data
  time_min <- min(temp_data$time)
  time_max <- max(temp_data$time)
  
  # Load the necessary reference data
  reference_data <- load_reference_data(time_min, time_max)
  
  # Filter temp_data to only include the time span of reference_data
  filtered_temp_data <- temp_data[temp_data$time >= min(reference_data$time) & temp_data$time <= max(reference_data$time), ]
  
  # Create the ggplot
  p <- ggplot() +
    geom_line(data = reference_data, aes(x = time, y = temperature), color = "gray", alpha = 0.5, lwd = 1) +
    geom_point(data = filtered_temp_data, aes(x = time, y = temperature), color = "blue", size = 2, shape = 1) +
    labs(title = "Temperature Plot with Reference Data",
         x = "Time",
         y = "Temperature") +
    theme_minimal()
  
  p

}

# Wrapper for command-line usage
plot_temperature_cli <- function(args) {
  if (length(args) < 1) {
    stop("Usage: Rscript script_name.R <temp_data.csv> [output_path]")
  }
  
  # Read the arguments
  temp_data_path <- args[1]
  output_path <- ifelse(length(args) > 1, args[2],  gsub("\\.csv$", ".png", temp_data_path))
  
  # Check the file extension and set default if missing
  if (tools::file_ext(output_path) == "") {
    output_path <- paste0(output_path, ".png")
  }
  
  # Load the data
  temp_data <- read.csv(temp_data_path)
  
  # Ensure time is in the correct format (as.POSIXct or numeric)
  temp_data$time <- as.POSIXct(temp_data$time, format = "%Y-%m-%d %H:%M:%S")
  
  # Call the plot function
  p <- plot_temperature(temp_data)
  
  ggsave(output_path, p, width = 8, height = 6, device = "png")
}

# Allow the script to be executed from the command line
if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  plot_temperature_cli(args)
}
