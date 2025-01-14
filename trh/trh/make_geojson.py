# this script takes in the API responses from the observations and from the geolocations and puts them into a single geojson points cloud. 

import json
from trh.config import api_response_observations_geolocation, trh_utrecht




# Input and output file paths
locations_file = api_response_observations_geolocation 
output_file = trh_utrecht 

# Prepare the GeoJSON structure
geojson = {
    "type": "FeatureCollection",
    "features": []
}


with open(locations_file, "r") as file:
    for line in file:
        record = json.loads(line.strip())
        feature = {
            "type": "Feature",
            "geometry": record["geometry"],
            "properties": {
                "device_id": record["device_id"],
                "phenomenonTime": record["phenomenonTime"],
                "type": record["type"],
                "value": float(record["value"]) if record["value"] is not None else None,
                "geoloc_url": record["geoloc_url"],
                "location_quality": float(record["location_quality"]) if record["location_quality"] is not None else None,
                "geometry_altitude": float(record["geometry_altitude"]) if record["geometry_altitude"] is not None else None
            }
        }
        geojson["features"].append(feature)

# Write the GeoJSON to a file
with open(output_file, "w") as file:
    json.dump(geojson, file, indent=2)

print(f"GeoJSON file created: {output_file}")
