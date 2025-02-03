from trh.config import api_responses__observations_by_sensor_utrecht, api_responses__sensors_utrecht, api_endpoint_obs_by_sensorname
from trh import api_client

import json
import os


path_sensor_namelist = api_responses__sensors_utrecht
path_output = api_responses__observations_by_sensor_utrecht
os.makedirs(os.path.dirname(path_output), exist_ok=True)

with open(path_sensor_namelist, 'r') as json_file:
    sensor_names = json.load(json_file)

sensor_namelist = [x['name'] for x in sensor_names]
del sensor_names

# Check if the output JSONL file already exists
processed_device_ids = set()
if os.path.exists(path_output):
    with open(path_output, 'r') as jsonl_file:
        for line in jsonl_file:
            entry = json.loads(line)
            processed_device_ids.add(entry["device_id"])




with open(path_output, 'a') as output_jsonl:
    for device_id in sensor_namelist:
        if device_id in processed_device_ids:
            continue
        
        all_device_obs = []
        
        url = api_endpoint_obs_by_sensorname(device_id)

        while url:
            response_data = api_client.make_api_request(url)
            
            all_device_obs.extend(response_data.get('value',[]))
            
            local_url = response_data.get("@iot.nextLink")
            if local_url:
                url = api_client.adjust_frost_url(local_url)
            else: 
                data_out = {"device_id": device_id, 
                            "responses": all_device_obs}
                output_jsonl.write(json.dumps(data_out) + '\n')
                # write to jsonl and break the while. Onto the next sensor name. 
                break

print(f'All devices responses saved to {path_output}')