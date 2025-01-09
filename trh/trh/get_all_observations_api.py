from trh.config import api_response_observations_utrecht, apiurl_base_url
from trh import api_client

import json
import os

base_url = apiurl_base_url
url = f"{base_url}/Observations?$filter=(Datastream/Thing/name eq 'Utrecht')&$orderby=@iot.id asc"

output_path = api_response_observations_utrecht

os.makedirs(os.path.dirname(output_path), exist_ok=True)

# @iot.id is the unique id for the observation
# FeatureOfInterest@iot.navigationLink points to GPS data

# get the first 100 observations
# get the GPS for these 100 observations
# get the  next 100 while the last entry doesn't link to the next 100 observations.
# store everything as a table


all_observations = []
counter = 0
while url:
    response_data = api_client.make_api_request(url)

    all_observations.extend(response_data.get("value", []))
    counter += 100
    print(f"Fetched the first {counter} observations. ")

    # the url at the end is local. This adds the url we can access remotely. 
    local_url = response_data.get("@iot.nextLink")
    if local_url:
        url = api_client.adjust_frost_url(local_url)
    else: 
        break



with open(output_path, 'w') as json_file:
    json.dump(all_observations, json_file, indent=4)

