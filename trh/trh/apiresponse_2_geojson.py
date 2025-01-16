# Merge the GPS data, with the observations. 
# its already merged....
# convert the one file to geojson

from trh.config import api_response_obs_by_sensor, trh_utrecht_sensor
import json
import geopandas as gpd
import os


geojson = {
    "type": "FeatureCollection",
    "features": []
}

with open(api_response_obs_by_sensor, 'r') as jsonl_file:
    for line in jsonl_file:
        device_data = json.loads(line)
        
        device_id = device_data["device_id"]
        
        all_device_observations = device_data['responses']
        
        for observation in all_device_observations:
                        
            iot_id = observation['@iot.id']
            coordinates = observation.get("FeatureOfInterest").get("feature").get("coordinates")
            gps_quality = observation["FeatureOfInterest"]["properties"]["quality"]
            # stencil for geojson geometry format
            geometry = {
                    "type"       : "Point",
                    "coordinates": coordinates
                    }
            
            feature = {
                "type": "Feature",
                "geometry": geometry,
                "properties": {
                    "device_id"     : device_id,
                    "phenomenonTime": observation["phenomenonTime"],
                    "type"          : observation["result"]["type"],
                    "value"         : observation["result"]["measurement"],
                    "gps_quality"   : gps_quality,
                    "@iot.id"       : iot_id
                }
            }
            geojson["features"].append(feature)




# Write the GeoJSON to a file
os.makedirs(os.path.dirname(trh_utrecht_sensor), exist_ok=True)
with open(trh_utrecht_sensor, "w") as file:
    json.dump(geojson, file, indent=2)

print(f"GeoJSON file created: {trh_utrecht_sensor}")