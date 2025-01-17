from sklearn.preprocessing import MinMaxScaler
import geopandas as gpd
import pandas as pd

from trh.config import trh_utrecht  # Path to the data

import matplotlib.pyplot as plt
import seaborn as sns


# Load GeoJSON data
path_data = trh_utrecht
data_wgs84 = gpd.read_file(path_data)

# Reproject data to the desired CRS (e.g., EPSG:3035 for ETRS89-extended LAEA)
data_all = data_wgs84.to_crs(3035)

# take only temperature for now. Later we might handle this in a loop. 
data = data_all.loc[data_all['type'] == "temperature"]

# Extract coordinates
data["x"] = data.geometry.x
data["y"] = data.geometry.y

# Assume time and value columns exist in your GeoDataFrame; if not, add placeholders
# Example: Replace 'time_column' and 'value_column' with actual column names
data["time"] = pd.to_datetime(data["phenomenonTime"], errors="coerce")  # Ensure time is in datetime format

# Include IoT ID (unique identifier for each observation)
data["iot_id"] = data["X.iot.id"] 

# Select only the necessary columns
columns_needed = ["iot_id", "device_id", "x", "y", "time", "value"]
data_4d = data[columns_needed]

# Convert time to a numerical value (e.g., seconds since epoch) for uniform scaling
data_4d["time"] = (data_4d["time"] - pd.Timestamp("1970-01-01",tz='UTC' )) // pd.Timedelta("1s")

# Reset index for clean formatting
data_4d = data_4d.reset_index(drop=True)

def find_nearby_observations(group):
    # Sort by time
    group = group.sort_values("time")
    
    # Calculate time difference between consecutive observations
    group["time_diff"] = group["time"].diff().fillna(float('inf'))
    
    # Filter observations where the difference is <= 60 seconds
    nearby_obs = group[group["time_diff"] <= 5]
    
    return nearby_obs

# Apply the function to each device_id group
nearby_observations = data_4d.groupby("device_id", group_keys=False).apply(find_nearby_observations)

# Reset index for the final DataFrame
nearby_observations = nearby_observations.reset_index(drop=True)

# Print or inspect the result
print(nearby_observations.head())



1+1