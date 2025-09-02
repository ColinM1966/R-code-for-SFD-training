###############################################################################
#                ****Preparing the CHELSA_CMIP6 Data****
# This code prepares the downloaded CHELSA_CMIP6 data for use in Task 2. It 
# converts tas, tasmax and tasmin from degrees K to degrees C and simplifies 
# the file names. 
#
##############################################################################
#1. Load require packages     
library(terra)
library(stringr)

# --- User settings ---
variables      <- c("tas", "tasmax", "tasmin", "pr")   # Include precipitation
source_id      <- "MPI-ESM1-2-LR"                      # ESM
experiment_id  <- "ssp585"                             # Experiment
institution_id <- "MPI-M"                              # Institution
member_id      <- "r1i1p1f1"                           # Variant

# Input folder with CHELSA_CMIP6 files
input_dir  <- "C:/Users/User/Documents/CHELSA/"
output_dir <- "C:/Users/User/Documents/NASAdata/Processed/"

# Ensure output directory exists
if(!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# --- Processing loop ---
for (var in variables) {
  
  # Match CHELSA file format
  pattern <- paste0("^", experiment_id, "CHELSA_", institution_id, "_", 
                    source_id, "_", var, "_", experiment_id, "_", member_id, "_\\d{4}-\\d{2}-\\d{2}_\\d{4}-\\d{2}-\\d{2}\\.nc$")
  
  files <- list.files(input_dir, pattern = pattern, full.names = TRUE)
  
  for (f in files) {
    # Load raster
    r <- rast(f)
    
    # Convert to °C for temperature variables only
    if (var %in% c("tas", "tasmax", "tasmin")) {
      r <- r - 273.15
    }
    # 'pr' remains unchanged (already mm/day)
    
    # Extract start and end years from filename
    date_parts <- str_extract_all(basename(f), "\\d{4}-\\d{2}-\\d{2}")[[1]]
    start_year <- substr(date_parts[1], 1, 4)
    end_year   <- substr(date_parts[2], 1, 4)
    
    # Build new filename
    out_name <- paste0("Borneo_", var, "_", source_id, "_", 
                       experiment_id, "_", start_year, "-", end_year, ".nc")
    
    out_path <- file.path(output_dir, out_name)
    
    # Save processed NetCDF
    writeCDF(r, filename = out_path, overwrite = TRUE)
    
    cat("Processed:", out_name, "\n")
  }
}
