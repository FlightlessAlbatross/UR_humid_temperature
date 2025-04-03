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

# source("./trh/trh/__pipeline.R")
library(stargazer)
library(sf)
library(dplyr)
library(lubridate)
library(ggplot2)

setwd("C:/Users/hofer/Documents/urbanreleaf/UR_humid_temperature")

data <- st_read("data/temp/qgispipe.geojson")

data$temp_reference <- data$temp_value + data$temp_deviation
data$h <- hour(data$time)
data$sun_hours <- pmin(pmax(0, hour(data$time)-6), 15)
plot(data$sun_hours, hour(data$time))

data <- data %>%
  mutate(
    area_gras_10m_binary = as.numeric(area_gras_10m > 0),
    area_gras_10m_log = ifelse(area_gras_10m > 0, log(area_gras_10m), 0),
    
    area_building_10m_binary = as.numeric(area_building_10m > 0),
    area_building_10m_log = ifelse(area_building_10m > 0, log(area_building_10m), 0),
    
    area_water_10m_binary = as.numeric(area_water_10m > 0),
    area_water_10m_log = ifelse(area_water_10m > 0, log(area_water_10m), 0)
  )



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

# We have autocorrelation obvious in hindsight. 
linear_osmonly_model     <- lm(temp_value ~ distance_building + distance_water + distance_grass, data = train_data)
linear_osmareaonly_model <- lm(temp_value ~ area_gras_30m + area_building_30m + area_water_30m, data = train_data)
lm_augmented <- lm(temp_value ~ 
                     area_gras_10m_binary + area_gras_10m + 
                     area_building_10m_binary + area_building_10m + 
                     area_water_10m_binary + area_water_10m, 
                   data = data)
summary(lm_augmented)
summary(linear_osmonly_model)
summary(linear_osmareaonly_model)


effect_sizes <- function(model){
  
  apply(model$model[,-1], 2,  quantile, probs = c(0.75, 0.25)) * matrix(rep(model$coefficients[-1], 2), nrow = 2, byrow = T)
  
}

effect_sizes(linear_osmonly_model)
effect_sizes(linear_osmareaonly_model)



linear_model <- lm(temp_value ~ temp_reference + distance_building + distance_water + distance_grass, data = train_data)
plot(residuals(linear_model), train_data$temp_value)
cor(residuals(linear_model), train_data$temp_value)

linear_model_reference_only <- lm(temp_value ~ temp_reference, data = train_data)

plot(residuals(linear_model_reference_only), train_data$temp_value)
cor(residuals(linear_model_reference_only), train_data$temp_value)

residual_exclude <- exclude_variable_residuals(linear_model, 'temp_reference')

ggplot(data.frame(train_data, residual_exclude), aes(x = residual_exclude, y = distance_grass)) +
  geom_point() + 
  geom_smooth()

library(lmtest)

lm_reference <- lm(temp_value ~ temp_reference, data = train_data)

dwtest(lm_reference)
dwtest(linear_model)



linear_model <- lm(temp_value ~ temp_reference + distance_building + distance_water + distance_grass, data = train_data)
residual_exclude <- exclude_variable_residuals(linear_model, 'temp_reference')

lm(residual_exclude ~ temp_reference, data=data.frame(train_data, residual_exclude))
lm(residual_exclude ~ temp_reference +  I(temp_reference^2), data=data.frame(train_data, residual_exclude))


ggplot(data.frame(train_data, residual_exclude), aes(y = temp_value, x = temp_reference)) + geom_point() + 
  geom_smooth()+ 
  geom_smooth(method = 'lm', color = 'orange', formula = 'y ~ x + I(x^2)') +
  theme_minimal() + 
  labs(title = 'Reference temperature against measured temperature', 
       subtitle = "Of interest: \n 
       1) they are correlated not just linearly \n 
       2) there are clear straight lines. Maybe these belong to the same trip?")

ggplot(data.frame(train_data, residual_exclude), aes(y = residual_exclude, x = temp_reference)) + geom_point() + 
  geom_smooth()+ 
  geom_smooth(method = 'lm', color = 'orange', formula = 'y ~ x + I(x^2)')+
  theme_minimal() + 
  labs(title = 'reference temperature against temperature-intercept-distance_to_buildings_water_grass', 
       subtitle = "Of interest: \n 
       1) they are correlated not just linearly \n 
          1.1) Are these the points at night, when we saw bigger deviations?\n 
       2) the straight lines are gone! \n 
       3) calcualte greenness area around point, rather than distance! TODO
       4) Have to think about the buildings, just area doesn't seem to cut it.\n 
       So maybe more generally the streen canyon. Do I look for that, or calculate it myself?\n
       Or how much nonbuilding area is there... Thats the same as a constant minus the area of the buildi ng so...\n
       5) Cummulative Sunhours of that day on that spot/ in the area?")

ggplot(data.frame(train_data, residual_exclude), aes(y = residual_exclude, x = temp_reference)) + geom_point() + 
  geom_smooth()+ 
  geom_smooth(method = 'lm', color = 'orange', formula = 'y ~ x + I(x^2)')+
  theme_minimal() + 
  labs(title = 'Residuals of closeness features against measured temperature', 
       subtitle = "Of interest: \n"
      )

pairs(~ temp_value + temp_reference + residual_exclude, data = data.frame(train_data, residual_exclude))



linear_model <- lm(temp_value ~ temp_reference + distance_building + distance_water + distance_grass, data = train_data)
linear_model2 <- lm(temp_value ~ temp_reference + sun_hours + distance_building + distance_water + distance_grass, data = train_data)
linear_model3 <- lm(temp_value ~ temp_reference + h + I(h^2) , data = train_data)
linear_model3.1 <- lm(temp_value ~ temp_reference + h + I(h^2) + distance_building + distance_water + distance_grass, data = train_data)
linear_model3.2 <- lm(temp_value ~ (temp_reference + h + I(h^2) + distance_building + distance_water + distance_grass)^2, data = train_data)

summary(linear_model3.2)

stargazer(linear_model, linear_model2,linear_model3, linear_model3.1, type = 'text')
stargazer(linear_model3, linear_model3.1, linear_model3.2, type = 'text')


plot(linear_model$fitted.values, linear_model$model$temp_value)
plot(linear_model2$fitted.values, linear_model2$model$temp_value)
plot(linear_model3$fitted.values, linear_model3$model$temp_value)


library(effects)
library(ggeffects)

plot(allEffects(linear_model3.1))


plot(allEffects(linear_model3.2))
plot(predictorEffects(linear_model3.2))

summary(linear_model3.2)
plot(ggpredict(linear_model3.2, terms = c("temp_reference", "h")))
plot(ggpredict(linear_model3.2, terms = c("h", "temp_reference")))
plot(ggpredict(linear_model3.2, terms = c("h", "distance_grass")))

plot(ggpredict(linear_model3.2, terms = c("h", "distance_water", "temp_reference")))
plot(ggpredict(linear_model3.2, terms = c("h","distance_water", "distance_grass", "distance_building")))


plot(ggpredict(linear_model3.1, terms = c("temp_reference", "distance_grass")))


# try random effects model. 
library(lme4)
# Allow slope of temp_reference to vary by trip
mixed_model1 <- lmer(
  temp_value ~ temp_reference + distance_building + distance_water + distance_grass +
    area_gras_30m + area_building_30m + area_water_30m +
    hour(time) + I(hour(time)^2) +
    (1 + temp_reference | trip_id),
  data = data, REML = FALSE
)

mixed_model2 <- lmer(
  temp_value ~ temp_reference + distance_building + distance_water + distance_grass +
    hour(time) + I(hour(time)^2) +
    (1 + temp_reference | trip_id),
  data = data, REML = FALSE
)
BIC(mixed_model1)
BIC(linear_model3.1)
summary(mixed_model1)
stargazer(mixed_model2, mixed_model1, type = 'text')

# install.packages("sjPlot")
library(sjPlot)
# Plot fixed effects
plot_model(mixed_model1, type = "est")  # barplot of effect sizes

plot(ggpredict(mixed_model1, terms = c("distance_building")))

