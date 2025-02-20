
ogr2ogr -f "GeoJSON" -t_srs EPSG:3035 -spat 3982791 3227165 3991173 3235973 -spat_srs EPSG:3035 -where "natural='water'"  utrecht_water_3.geojson europe-latest.osm.pbf multipolygons

ogr2ogr -f "GeoJSON" -t_srs EPSG:3035 -spat 3982791 3227165 3991173 3235973 -spat_srs EPSG:3035 -where "building IS NOT NULL" utrecht_buildings_3.geojson europe-latest.osm.pbf multipolygons

