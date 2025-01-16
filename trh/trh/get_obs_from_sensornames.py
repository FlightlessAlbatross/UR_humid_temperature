from trh.config import api_response_sensors_utrecht, apiurl_base_url, api_response_obs_by_sensor
from trh import api_client

import json
import os

base_url = apiurl_base_url

path_sensor_namelist = api_response_sensors_utrecht
path_output = api_response_obs_by_sensor
os.makedirs(os.path.dirname(path_output), exist_ok=True)

with open(path_sensor_namelist, 'r') as json_file:
    sensor_names = json.load(json_file)

sensor_namelist = [x['name'] for x in sensor_names]
del sensor_names

# Check if the output JSONL file already exists
processed_device_ids = set()
if os.path.exists(api_response_obs_by_sensor):
    with open(api_response_obs_by_sensor, 'r') as jsonl_file:
        for line in jsonl_file:
            entry = json.loads(line)
            processed_device_ids.add(entry["device_id"])




with open(path_output, 'a') as output_jsonl:
    for device_id in sensor_namelist:
        if device_id in processed_device_ids:
            continue
        
        all_device_obs = []
        
        url = (
        f"{base_url}/Observations?"
        f"$filter=startswith(Datastream/Sensor/name, '{device_id}')&"
        f"$count=true&"
        f"$orderBy=resultTime desc&"
        f"$expand=FeatureOfInterest($select=feature/coordinates,properties/quality)&"
        f"$expand=Datastream($select=unitOfMeasurement/name,unitOfMeasurement/symbol;"
        f"$expand=ObservedProperty($select=name))"
        )
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

print('All devices responses saved to {path_output}')