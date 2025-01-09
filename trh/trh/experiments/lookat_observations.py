import json
from trh.config import api_response_observations_utrecht



with open(api_response_observations_utrecht, 'r') as json_file:
    data = json.load(json_file)


print(len(data))

counter = {}

for i, entry in enumerate(data):
    vartype = entry['result'].get('type','error')
    if vartype in counter:
        counter[vartype] += 1
    else:
        counter[vartype] = 1

print(counter)