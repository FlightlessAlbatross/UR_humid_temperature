import json
import os
from trh.config import api_response_observations_utrecht, api_response_observations_geolocation
from trh import api_client
import time


# Load the input JSON data
with open(api_response_observations_utrecht, 'r') as json_file:
    data = json.load(json_file)

# Check if the output JSONL file already exists
processed_ids = set()
if os.path.exists(api_response_observations_geolocation):
    with open(api_response_observations_geolocation, 'r') as jsonl_file:
        for line in jsonl_file:
            try:
                entry = json.loads(line)
                processed_ids.add(entry["device_id"])
            except json.JSONDecodeError:
                continue  # Handle cases where the file might have partial/corrupt lines



with open(api_response_observations_geolocation, 'a') as jsonl_file:
    for i, entry in enumerate(data):
        device_id = entry["@iot.id"]

        # Skip if this entry has already been processed
        if device_id in processed_ids:
            continue

        phenomenon_time = entry["phenomenonTime"]
        variable_type = entry["result"]["type"]
        value = entry["result"]["measurement"]
        feature_url = api_client.adjust_frost_url(entry["FeatureOfInterest@iot.navigationLink"])

        # fetch the geolocations
        gps_response = api_client.make_api_request(feature_url)
        # Extract location, altitude, and quality
        location = gps_response["feature"]["coordinates"]  # [longitude, latitude]
        altitude = gps_response["properties"].get("altitude", None)  # Default to None if not present
        quality = gps_response["properties"].get("quality", None)  # Default to None if not present

        out = {"device_id" : device_id,
            "phenomenonTime": phenomenon_time,
            "type": variable_type,
            "value": value,
            "geoloc_url": feature_url, 
            "location_quality": quality, 
            "geometry_altitude": altitude, 
            "geometry": {"type": "Point", "coordinates": location}}
        
        jsonl_file.write(json.dumps(out) + '\n')
        if i % 100 == 0:
            print(f"Iteration {i}")

        time.sleep(1)






        