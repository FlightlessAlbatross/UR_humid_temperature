from sklearn.preprocessing import MinMaxScaler
import geopandas as gpd
import pandas as pd

from trh.config import trh_utrecht  # Path to the data

from sklearn.cluster import DBSCAN # to find similar obs. 


import matplotlib.pyplot as plt
import seaborn as sns


def cluster_plots(data, device_id):
    # Example scatter plots
    fig, axes = plt.subplots(2, 3, figsize=(15, 10))
    scatter_pairs = [("x", "y"), ("x", "time"), ("x", "value"), ("y", "time"), ("y", "value"), ("time", "value")]

    for ax, (dim1, dim2) in zip(axes.flat, scatter_pairs):
        sns.scatterplot(
            x=dim1, y=dim2, hue="cluster", data=data, palette="tab10", ax=ax, style="cluster"
        )
        ax.set_title(f"{dim1} vs {dim2}")

    plt.tight_layout()
    filename = f"cluster_{device_id}.png"
    plt.savefig(filename)
    plt.close(fig)
    print(f"Plot saved: {filename}")




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




# Normalize and cluster within each device_id
results = []

for device, group in data_4d.groupby("device_id"):
    # Normalize dimensions for this device
    scaler = MinMaxScaler()
    normalized = scaler.fit_transform(group[["x", "y", "time", "value"]])

    # Apply DBSCAN to find near duplicates within this device
    dbscan = DBSCAN(eps=0.05, min_samples=2)  # Adjust `eps` to control threshold
    labels = dbscan.fit_predict(normalized)

    # Add cluster labels back to the group
    group = group.copy()
    group["cluster"] = labels
    results.append(group)
    cluster_plots(group, device)

# Combine results for all devices
clustered_data = pd.concat(results, ignore_index=True)
