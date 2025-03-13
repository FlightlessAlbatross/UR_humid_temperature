exclude_variable_residuals <- function(model, exclusion_variable_name) {
  # Extract model formula
  model_formula <- formula(model)
  
  # Convert formula to character and remove the excluded variable
  terms <- all.vars(model_formula)
  response_var <- terms[1]  # First term is the dependent variable
  predictors <- setdiff(terms[-1], exclusion_variable_name)  # Exclude the specified variable
  
  # Create new formula excluding the variable
  new_formula <- as.formula(paste(response_var, "~", paste(predictors, collapse = " + ")))
  
  # Fit new model without the excluded variable
  new_model <- lm(new_formula, data = model$model)  # Use original model's data
  
  # Return residuals of the new model
  return(residuals(new_model))
}

install.packages("gganimate")
install.packages("gifski")
# install.packages("transformr")

library(ggplot2)
library(gganimate)
library(dplyr)
# library(gisky)


source("C:/Users/hofer/Documents/urbanreleaf/UR_humid_temperature/trh/trh/__pipeline.R")
data$temp_reference <- data$temp_value + data$temp_deviation


data$temp_reference <- data$temp_value + data$temp_deviation

index_drop <- with(data, 
                   gps_outlier == 'jumpy' &  !is.na(gps_outlier)  | 
                     distance_building == 0  | 
                     distance_water == 0 )


outliers <- data[index_drop,]
trh      <- data[!index_drop,]

set.seed(42)
train_indices <- sample(1:nrow(trh), size = 0.8 * nrow(trh))
train_data <- trh[train_indices, ]
test_data  <- trh[-train_indices, ]


linear_model <- lm(temp_value ~ temp_reference + distance_building + distance_water + distance_grass, data = train_data)
train_data$residual_exclude <- exclude_variable_residuals(linear_model, 'temp_reference')




# Define animation settings
fps <- 10  # Frames per second
pause_frames <- fps / 2  # 0.5 seconds of pause
n_frames <- 30  # Transition frames

# Define an easing function for smooth acceleration & deceleration
ease_function <- function(t) {
  return(ifelse(t < 0.5, 4 * t^3, 1 - (-2 * t + 2)^3 / 2))  # Cubic easing
}

# Generate transition data
anim_data <- train_data %>%
  mutate(residual_exclude = residual_exclude, temp_value = temp_value) %>%
  tidyr::crossing(frame = seq(0, 1, length.out = n_frames)) %>%
  mutate(
    eased_frame = ease_function(frame),  # Apply easing function
    y_value = residual_exclude * (1 - eased_frame) + temp_value * eased_frame  # Interpolated y-values
  )

# Create duplicate frames at start & end for pauses
first_frame <- anim_data %>% filter(frame == min(frame)) %>% mutate(frame = -pause_frames / n_frames)
last_frame <- anim_data %>% filter(frame == max(frame)) %>% mutate(frame = 1 + pause_frames / n_frames)

# Combine the data
anim_data <- bind_rows(first_frame, anim_data, last_frame)

# Create the animation
p <- ggplot(anim_data, aes(x = temp_reference, y = y_value)) +
  geom_point(alpha = 0.7) +
  geom_smooth(se = FALSE) +
  labs(title = "Smooth Transition from Residuals to Actual Temperature",
       subtitle = "Frame: {frame_time}",
       y = "Interpolated Value") +
  transition_time(frame) +
  ease_aes('cubic-in-out')

# Render animation with extra frames for pauses
animate(p, renderer = gifski_renderer(), fps = fps, duration = (n_frames + 2 * pause_frames) / fps)



# stabalize y

# Define animation settings
fps <- 10  # Frames per second
pause_frames <- fps / 2  # 0.5s pause at start & end
n_frames <- 30  # Transition frames

# Generate transition data
anim_data <- train_data %>%
  mutate(residual_exclude = residual_exclude, temp_value = temp_value) %>%
  tidyr::crossing(frame = seq(0, 1, length.out = n_frames)) %>%
  mutate(
    eased_frame = ease_function(frame),  # Apply easing function
    y_value = residual_exclude * (1 - eased_frame) + temp_value * eased_frame  # Interpolated y-values
  )

# Compute the average shift at each frame
mean_shift <- anim_data %>%
  group_by(frame) %>%
  summarise(mean_y_shift = mean(y_value)) %>%
  ungroup()

# Adjust y-values to keep the point cloud centered
anim_data <- anim_data %>%
  left_join(mean_shift, by = "frame") %>%
  mutate(y_value_centered = y_value - mean_y_shift)

# Create duplicate frames at start & end for pauses
first_frame <- anim_data %>% filter(frame == min(frame)) %>% mutate(frame = -pause_frames / n_frames)
last_frame <- anim_data %>% filter(frame == max(frame)) %>% mutate(frame = 1 + pause_frames / n_frames)

# Combine the data
anim_data <- bind_rows(first_frame, anim_data, last_frame)

# Create the animation
p <- ggplot(anim_data, aes(x = temp_reference, y = y_value_centered)) +
  geom_point(alpha = 0.7) +
  geom_smooth(se = FALSE) +
  labs(title = "Stabilized Transition from Residuals to Actual Temperature",
       subtitle = "Frame: {frame_time}",
       y = "Interpolated Value (Centered)") +
  transition_time(frame) +
  ease_aes('cubic-in-out')

# Render animation with extra frames for pauses
animate(p, renderer = gifski_renderer(), fps = fps, duration = (n_frames + 2 * pause_frames) / fps)


library(ggplot2)
library(gganimate)
library(dplyr)

# Define animation settings
fps <- 10  # Frames per second
pause_frames <- fps / 2  # 0.5s pause at start & end
n_frames <- 30  # Transition frames

# Define an easing function for smooth acceleration & deceleration
ease_function <- function(t) {
  return(ifelse(t < 0.5, 4 * t^3, 1 - (-2 * t + 2)^3 / 2))  # Cubic easing
}

# Generate transition data
anim_data <- train_data %>%
  mutate(temp_value = temp_value, residual_exclude = residual_exclude) %>%
  tidyr::crossing(frame = seq(0, 1, length.out = n_frames)) %>%
  mutate(
    eased_frame = ease_function(frame),  # Apply easing function
    y_value = temp_value * (1 - eased_frame) + residual_exclude * eased_frame
  )

# Compute dynamic y-axis limits at each frame
y_limits <- anim_data %>%
  group_by(frame) %>%
  summarise(y_min = min(y_value), y_max = max(y_value)) %>%
  ungroup()

# Merge with animation data
anim_data <- anim_data %>%
  left_join(y_limits, by = "frame")

# Create duplicate frames at start & end for pauses
first_frame <- anim_data %>% filter(frame == min(frame)) %>% mutate(frame = -pause_frames / n_frames)
last_frame <- anim_data %>% filter(frame == max(frame)) %>% mutate(frame = 1 + pause_frames / n_frames)

# Combine the data
anim_data <- bind_rows(first_frame, anim_data, last_frame)

# Create the animation with camera following the y-axis movement
p <- ggplot(anim_data, aes(x = temp_reference, y = y_value)) +
  geom_point(alpha = 0.7) +
  geom_smooth(se = FALSE) +
  labs(title = "Camera Following Transition from Residuals to Actual Temperature",
       subtitle = "Frame: {frame_time}",
       y = "Interpolated Value") +
  transition_time(frame) +
  ease_aes('cubic-in-out') +
  theme_minimal()+
  view_follow(fixed_x = TRUE, fixed_y = FALSE)  # Let the camera follow y-axis movement

# Render animation with extra frames for pauses
animate(p, renderer = gifski_renderer(), fps = fps, duration = (n_frames + 2 * pause_frames) / fps)

data <- train_data
x_col       = "temp_reference"
y_start_col = "temp_value"
y_end_col   = "residual_exclude"
pause_time = 0.5
fps = 10
n_frames = 30
reverse = FALSE
animate_transition <- function(data, x_col, y_start_col, y_end_col, reverse = FALSE, fps = 10, n_frames = 30, pause_time = 0.5) {
  # Define easing function
  ease_function <- function(t) {
    return(ifelse(t < 0.5, 4 * t^3, 1 - (-2 * t + 2)^3 / 2))  # Cubic easing
  }
  
  # Convert column names to symbols for dplyr
  x_sym <- sym(x_col)
  y_start_sym <- sym(y_start_col)
  y_end_sym <- sym(y_end_col)
  
  # Compute pause frames
  pause_frames <- fps * pause_time  
  
  # Generate transition data
  anim_data <- data %>%
    tidyr::crossing(frame = seq(0, 1, length.out = n_frames)) %>%
    mutate(
      eased_frame = ease_function(frame),  # Apply easing
      y_value = ifelse(reverse, 
                       !!y_end_sym * (1 - eased_frame) + !!y_start_sym * eased_frame,  # Reverse mode
                       !!y_start_sym * (1 - eased_frame) + !!y_end_sym * eased_frame)  # Normal mode
    )
  
  # Compute dynamic y-axis limits per frame
  y_limits <- anim_data %>%
    group_by(frame) %>%
    summarise(y_min = min(y_value), y_max = max(y_value)) %>%
    ungroup()
  
  # Merge y-limits into anim_data
  anim_data <- anim_data %>%
    left_join(y_limits, by = "frame")
  
  # Create duplicate frames at start & end for pauses
  first_frame <- anim_data %>% filter(frame == min(frame)) %>% mutate(frame = -pause_frames / n_frames)
  last_frame <- anim_data %>% filter(frame == max(frame)) %>% mutate(frame = 1 + pause_frames / n_frames)
  
  # Combine full dataset
  anim_data <- bind_rows(first_frame, anim_data, last_frame)
  
  # Create animation with camera following the y-axis movement
  p <- ggplot(anim_data, aes(x = !!x_sym, y = y_value)) +
    geom_point(alpha = 0.7) +
    geom_smooth(se = FALSE) +
    labs(title = "Animated Transition", 
         subtitle = "Frame: {frame_time}",
         y = "Interpolated Value") +
    transition_time(frame) +
    ease_aes('cubic-in-out') +
    view_follow(fixed_x = TRUE, fixed_y = FALSE)  # Camera follows y-movement
  
  # Render animation
  animate(p, renderer = gifski_renderer(), fps = fps, duration = (n_frames + 2 * pause_frames) / fps)
}

animate_transition(train_data, "temp_reference", "temp_value", "residual_exclude")
