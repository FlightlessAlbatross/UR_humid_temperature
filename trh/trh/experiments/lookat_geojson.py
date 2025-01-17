import json
import geopandas as gpd
from trh.config import trh_utrecht


data = gpd.read_file(trh_utrecht)

print(data['geometry_altitude'].max())