from trh.config import api_response_sensors_utrecht, apiurl_base_url
from trh import api_client

import json
import os

base_url = apiurl_base_url
device_id = "8zxUAuBsVdr99AQS9gM94"

url = f"{base_url}/Sensors?$select=name&$count=true&$filter=Datastreams/Thing/name eq 'Utrecht'"

# url = (
#     f"{base_url}/Observations?"
#     f"$filter=startswith(Datastream/Sensor/name, '{device_id}')&"
#     f"$count=true&"
#     f"$orderBy=resultTime desc&"
#     f"$expand=FeatureOfInterest($select=feature/coordinates,properties/quality)&"
#     f"$expand=Datastream($select=unitOfMeasurement/name,unitOfMeasurement/symbol;"
#     f"$expand=ObservedProperty($select=name))"
# )


output_path = api_response_sensors_utrecht

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

