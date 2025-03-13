# Combine the sun expore tifs from shademap

library(terra)

path_1 <- './data/raw/shademap/sun_exposure_2024-07-15_a.tiff'
path_2 <- './data/raw/shademap/sun_exposure_2024-07-15_b.tiff'

path_merged <- './data/processed/shademap/sun_exposure_2024-07-15.tiff'

output_dir <- dirname(path_merged)
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

EPSG3035_wkt <-  "GEOGCRS[\"WGS 84\",\n    DATUM[\"World Geodetic System 1984\",\n        ELLIPSOID[\"WGS 84\",6378137,298.257223563,\n            LENGTHUNIT[\"metre\",1]]],\n    PRIMEM[\"Greenwich\",0,\n        ANGLEUNIT[\"degree\",0.0174532925199433]],\n    CS[ellipsoidal,2],\n        AXIS[\"geodetic latitude (Lat)\",north,\n            ORDER[1],\n            ANGLEUNIT[\"degree\",0.0174532925199433]],\n        AXIS[\"geodetic longitude (Lon)\",east,\n            ORDER[2],\n            ANGLEUNIT[\"degree\",0.0174532925199433]],\n    ID[\"EPSG\",4326]]"

# Load both rasters
raster1 <- rast(path_1)
raster2 <- rast(path_2)


# Align the resolution and extent
aligned_raster2 <- resample(raster2, raster1, method = "bilinear")  # Or use "near" for categorical data

# Merge the rasters
merged_raster <- mosaic(raster1, aligned_raster2, fun = "mean") 

# project to 3035, like the rest of the data
merged_raster_3035 <- project(merged_raster, EPSG3035_wkt)

# shademap tells us that we can get the values to represent minutes by times 6ing it. 
merged_raster_3035 <- merged_raster_3035*6

crs(merged_raster_3035)

# Save the merged raster
writeRaster(merged_raster, path_merged, overwrite = TRUE)
