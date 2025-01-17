import json
import os
from trh.config import api_responses__obs_by_sensor_utrecht, api_responses__observations_geolocation_utrecht
from trh import api_client

path_input = api_responses__obs_by_sensor_utrecht
path_output = api_responses__observations_geolocation_utrecht

os.makedirs(os.path.dirname(path_output), exist_ok=True)

# Load all observations grouped by device ID. 
# we don't really need the device ID here, but we will keep the structure. 
observations_by_device = {}
with open(path_input, 'r') as jsonl_file:
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
if os.path.exists(path_output):
    with open(path_output, 'r') as jsonl_file:
        for line in jsonl_file:
            entry = json.loads(line)
            gps_ids.add(entry[""])



with open(path_output, 'a') as jsonl_file:
    for device_id, entry in observations_by_device.items():
        
        for gps_entry in entry:
            
            # Skip if this entry has already been processed
            iot_id = gps_entry['@iot.id']
            if iot_id in gps_ids:
                continue
            
            feature_url = api_client.adjust_frost_url(gps_entry["FeatureOfInterest@iot.navigationLink"])

            # fetch the geolocations
            gps_response = api_client.make_api_request(feature_url)
            
            jsonl_file.write(json.dumps(gps_response) + '\n')
            gps_ids.add(iot_id)






        