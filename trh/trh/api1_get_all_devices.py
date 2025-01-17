from trh.config import api_responses__sensors_utrecht, api_endpoint_sensors
from trh import api_client

import json
import os

url = api_endpoint_sensors

output_path = api_responses__sensors_utrecht

os.makedirs(os.path.dirname(output_path), exist_ok=True)


all_devices = []
counter = 0
while url:
    response_data = api_client.make_api_request(url)
    
    if response_data['value'] == []:
        raise ValueError("An empty json was returned. ")

    all_devices.extend(response_data.get("value", []))
    counter += 100
    print(f"Fetched the first {counter} observations. ")

    # the url at the end is local. This adds the url we can access remotely. 
    local_url = response_data.get("@iot.nextLink")
    if local_url:
        url = api_client.adjust_frost_url(local_url)
    else: 
        break



with open(output_path, 'w') as json_file:
    json.dump(all_devices, json_file, indent=4)

