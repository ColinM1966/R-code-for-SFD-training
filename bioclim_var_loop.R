##############################################################################
#                     *****Bioclim variable using dismos*****
# This code calculates the 19 bioclim variable from the processed CHELSA_CMIP6
# nc files. The code works thru the 4 climatologies for a specified ESM/ssp and
# saves the results as tif files for each of the 19 bioclimatic variables
##############################################################################

library(terra)
library(dismo)

# === User inputs ===
esm <- "MPI-ESM1-2-LR"   # Example: "EC-Earth3", "MPI-ESM1-2-LR"
ssp <- "ssp585"        # Example: "ssp126", "ssp245", "ssp370", "ssp585"
geo <- "Borneo"
# === Base directory ===
base_dir <- "D:/CHELSA"

# === Define time periods ===
time_periods <- list(
  historical = "1981-2010",
  future1    = "2011-2040",
  future2    = "2041-2070",
  future3    = "2071-2100"
)

# === Loop through periods ===
for (tp in names(time_periods)) {
  period <- time_periods[[tp]]
  
  # File paths
  prec_nc <- file.path(base_dir, esm, ssp, 
                       paste0(geo, "_pr_", esm, "_", ssp, "_", period, ".nc"))
  tmin_nc <- file.path(base_dir, esm, ssp, 
                       paste0(geo, "_tasmin_", esm, "_", ssp, "_", period, ".nc"))
  tmax_nc <- file.path(base_dir, esm, ssp, 
                       paste0(geo, "_tasmax_", esm, "_", ssp, "_", period, ".nc"))
  
  # Load data as SpatRaster
  prec <- rast(prec_nc)
  tmin <- rast(tmin_nc)
  tmax <- rast(tmax_nc)
  
  # Convert to RasterStack for dismo::biovars
  prec_r <- stack(prec)
  tmin_r <- stack(tmin)
  tmax_r <- stack(tmax)
  
  # Generate bioclim variables
  bio <- biovars(prec_r, tmin_r, tmax_r)
  
  # Output folder
  out_dir <- file.path(base_dir, esm, ssp, "bioclim", period)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Write each layer
  for (i in 1:nlayers(bio)) {
    out_file <- file.path(out_dir, paste0(geo, "_", esm, "_", ssp, "_", period, "_bio_", i, ".tif"))
    writeRaster(bio[[i]], filename = out_file, overwrite = TRUE, NAflag = -9999)
  }
  
  message("Finished bioclim for: ", esm, " | ", ssp, " | ", period)
}
