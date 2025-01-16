#config.py

from pathlib import Path
import os
from typing import Tuple

package_dir = Path(os.path.dirname(os.path.dirname(__file__)))
data_dir = package_dir.parent / 'data'

## API Endpoints 
apiurl_base_url = "https://platform-urbanreleaf.iccs.gr/FROST-Server/v1.1"


## data
api_response_sensors_utrecht          = data_dir/ "raw/sensors/utrecht.json"
api_response_obs_by_sensor            = data_dir/ "raw/observations/utrecht_obs_by_sensor.jsonl"
api_response_geolocations             = data_dir / "raw/geolocations/geolocations_devicename.jsonl"

# based on old endpoints
api_response_observations_geolocation = data_dir /"raw/observations/geolocations.jsonl"
api_response_observations_utrecht     = data_dir/ "raw/observations/utrecht.json"
