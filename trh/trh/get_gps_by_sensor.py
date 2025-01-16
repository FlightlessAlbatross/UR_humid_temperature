import json
import os
from trh.config import api_response_obs_by_sensor, api_response_geolocations
from trh import api_client
import time
from datetime import datetime


# Load all observations grouped by device ID. 
# we don't really need the device ID here, but we will keep the structure. 
observations_by_device = {}
with open(api_response_obs_by_sensor, 'r') as jsonl_file:
        for line in jsonl_file:
            try:
                entry = json.loads(line)
                
                
                if entry['device_id'] in observations_by_device:
                    raise ValueError("This is about to overwrite an existing entry that should not be here.")
                
                data = entry["responses"]
                
                observations_by_device[entry['device_id']] = data
            except json.JSONDecodeError:
                continue  # Handle cases where the file might have partial/corrupt lines


# Load the output JSONL data if the file exists. This allows us to pick up a halfway failed request after restarting. 
gps_ids = set()
if os.path.exists(api_response_geolocations):
    with open(api_response_geolocations, 'r') as jsonl_file:
        for line in jsonl_file:
            try:
                entry = json.loads(line)
                gps_ids.add(entry[""])
            except json.JSONDecodeError:
                continue  # Handle cases where the file might have partial/corrupt lines




with open(api_response_geolocations, 'a') as jsonl_file:
    for device_id, entry in observations_by_device.items():
        
        for gps_entry in entry["responses"]:
            
            # Skip if this entry has already been processed
            if gps_entry['gps_id'] in gps_ids:
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
                current_time = datetime.now()
                print(
                    f"Iteration {i} at: { current_time.strftime('%H:%M') }"
                    )

            gps_ids.add(gps_id)






        