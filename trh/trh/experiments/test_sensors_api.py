from trh.config import api_response_sensors_utrecht, apiurl_sensors, apiurl_base_url
from trh import api_client

import json
import os


base_url = apiurl_base_url

output_filename = 'u1.json'
output_path = f"{api_response_sensors_utrecht}/{output_filename}"

os.makedirs(api_response_sensors_utrecht, exist_ok=True)



data = api_client.make_api_request(apiurl_sensors)


with open(output_path, 'w') as json_file:
    json.dump(data, json_file, indent=4)

