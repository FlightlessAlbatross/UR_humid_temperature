# convert api_respones by device (with GPS) to a geojson

from trh.config import api_responses__obs_by_sensor_utrecht, trh_utrecht
import json
import os

path_input  = api_responses__obs_by_sensor_utrecht
path_output = trh_utrecht

geojson = {
    "type": "FeatureCollection",
    "features": []
}

with open(path_input, 'r') as jsonl_file:
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
os.makedirs(os.path.dirname(path_output), exist_ok=True)
with open(path_output, "w") as file:
    json.dump(geojson, file, indent=2)

print(f"GeoJSON file created: {path_output}")