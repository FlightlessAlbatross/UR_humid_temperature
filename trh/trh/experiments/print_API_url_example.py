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

target_device = ["2e1a8c0c-228e-4992-96e8-11c85a8306e8", "968419c4-fe72-49ae-a757-733e6458707e"]

print(f"device 0 in list? : {target_device[0] in sensor_namelist}")

# Check if the output JSONL file already exists
processed_device_ids = set()
if os.path.exists(path_output):
    with open(path_output, 'r') as jsonl_file:
        for line in jsonl_file:
            entry = json.loads(line)
            processed_device_ids.add(entry["device_id"])





for device_id in target_device:
   
    all_device_obs = []
    
    url = api_endpoint_obs_by_sensorname(device_id)
    print(url)

    while url:
        response_data = api_client.make_api_request(url)
        
        all_device_obs.extend(response_data.get('value',[]))
        
        all_dates   = [entry['phenomenonTime'] for entry in response_data['value'] if entry['result']['type'] == 'temperature']
        all_iotid   = [entry['@iot.id'] for entry in response_data['value'] if entry['result']['type'] == 'temperature']
        all_gps_x   = [float(entry['FeatureOfInterest']['feature']['coordinates'][0]) for entry in response_data['value'] if entry['result']['type'] == 'temperature']
        all_gps_y   = [float(entry['FeatureOfInterest']['feature']['coordinates'][1]) for entry in response_data['value'] if entry['result']['type'] == 'temperature']

        
        local_url = response_data.get("@iot.nextLink")
        if local_url:
            url = api_client.adjust_frost_url(local_url)
        else: 
            data_out = {"device_id": device_id, 
                        "responses": all_device_obs}
            # write to jsonl and break the while. Onto the next sensor name. 
            break

print(f'All devices responses saved to {path_output}')