

import json
from trh.config import trh_utrecht


# Load the GeoJSON file as a dictionary
with open(trh_utrecht, "r") as f:
    geojson_data = json.load(f)


minimum = 0
all_values = []
# Iterate through features and check property values
for feature in geojson_data["features"]:
    for key, value in feature["properties"].items():
        if isinstance(value, int):
            all_values.append(value)
            
            if value < minimum:
                minimum = value

            if (value < -2**63 or value > 2**63 - 1):
                print(f"Column: {key}, Value: {value}")
                print(f"")


print(minimum)


1+1
print ('hi')