import json
from trh.config import api_response_observations_geolocation, trh_utrecht


# Input and output file paths
input_file = api_response_observations_geolocation 
output_file = trh_utrecht 

# Prepare the GeoJSON structure
geojson = {
    "type": "FeatureCollection",
    "features": []
}


with open(input_file, "r") as file:
    for line in file:
        record = json.loads(line.strip())
        feature = {
            "type": "Feature",
            "geometry": record["geometry"],
            "properties": {
                "device_id": record["device_id"],
                "phenomenonTime": record["phenomenonTime"],
                "type": record["type"],
                "value": record["value"],
                "geoloc_url": record["geoloc_url"],
                "location_quality": record["location_quality"],
                "geometry_altitude": record["geometry_altitude"]
            }
        }
        geojson["features"].append(feature)

# Write the GeoJSON to a file
with open(output_file, "w") as file:
    json.dump(geojson, file, indent=2)

print(f"GeoJSON file created: {output_file}")
