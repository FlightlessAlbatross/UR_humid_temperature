#config.py

from pathlib import Path
import os
from typing import Tuple

package_dir = Path(os.path.dirname(os.path.dirname(__file__)))
data_dir = package_dir.parent / 'data'

## API Endpoints 
# TODO: rename apiurl_base_url -> api_url_base
apiurl_base_url = "https://platform-urbanreleaf.iccs.gr/FROST-Server/v1.1"

# Get all Sensor names
api_endpoint_sensors = f"{apiurl_base_url}/Sensors?$select=name&$count=true&$filter=Datastreams/Thing/name eq 'Utrecht'"

def api_endpoint_obs_by_sensorname(device_id):
    url = (
    f"{apiurl_base_url}/Observations?"
    f"$filter=startswith(Datastream/Sensor/name, '{device_id}')&"
    f"$count=true&"
    f"$orderBy=resultTime desc&"
    f"$expand=FeatureOfInterest($select=feature/coordinates,properties/quality)&"
    f"$expand=Datastream($select=unitOfMeasurement/name,unitOfMeasurement/symbol;"
    f"$expand=ObservedProperty($select=name))")
    return url
            

## data
api_responses__sensors_utrecht                  = data_dir / "raw/api_responses/sensors_utrecht.json"
api_responses__observations_by_sensor_utrecht   = data_dir / "raw/api_responses/observations_by_sensor_utrecht.jsonl" 
api_responses__observations_geolocation_utrecht = data_dir / "raw/api_responses/observations_geolocation_utrecht.jsonl" 

trh_utrecht = data_dir / "processed/trh/utrecht_global.geojson"


# Utrecht polygon
LAU_utrecht = data_dir / "reference/LAU_utrecht_4326.geojson" # needs to be in the data folder from the start.
