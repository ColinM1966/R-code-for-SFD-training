# Load libraries
library(terra)
library(ncdf4)

# Set the start and end years
start_year <- 2011
end_year <- 2100

# Load reference raster
ref_raster <- rast("C:/Users/User/Documents/Borneo_pr_day_GFDL-ESM4_ssp126_r1i1p1f1_gr1_2015.tif")

# Define metadata
Var <- "pr"  # Options: pr, tas, tasmin, tasmax, hurs
ESM <- "GFDL-ESM4"
SSP <- "ssp585"
Variant <- "r1i1p1f1"
Grid <- "gr1"
Geo <- "Borneo"

# Version codes
Ver_historic <- "v2.0"
Ver_future <- "v2.0"

# Output directory
output_dir <- file.path("C:/Users/User/Documents/NASAdata", ESM, SSP, Var)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# Loop over years
for (year in start_year:end_year) {
  
  # Determine scenario and version
  scenario <- ifelse(year < 2015, "historical", SSP)
  version <- ifelse(year < 2015, Ver_historic, Ver_future)
  
  # Input file path
  nc_file <- file.path("C:/Users/User/Documents/NASAdata", ESM, scenario, Var,
                       paste0(Var, "_day_", ESM, "_", scenario, "_", Variant,"_", Grid, "_", year, "_", version, ".nc"))
  
  if (!file.exists(nc_file)) {
    warning(paste("File not found:", nc_file))
    next
  }
  
  # Load NetCDF as SpatRaster
  cat("Loading:", nc_file, "\n")
  data <- rast(nc_file)
  
  # Conditional unit conversion
  if (Var == "pr") {
    data <- data * 86400  # kg/m²/s → mm/day
    unit_str <- "mm/day"
    varname_str <- "precip"
    
  } else if (Var %in% c("tas", "tasmin", "tasmax")) {
    data <- data - 273.15  # Kelvin → °C
    unit_str <- "°C"
    varname_str <- Var  # use original variable name
    
  } else if (Var == "hurs") {
    # no conversion
    unit_str <- "%"
    varname_str <- "hurs"
  } else {
    warning(paste("Unrecognized variable:", Var))
    next
  }
  
  # Crop to reference raster extent
  data_cropped <- crop(data, ref_raster)
  
  # Output file path
  output_file <- file.path(output_dir,
                           paste0(Geo, "_", Var, "_day_", ESM, "_", SSP, "_", Variant,"_", Grid, "_", year, "_", version, ".nc"))
  
  # Write output
  cat("Writing to:", output_file, "\n")
  writeCDF(data_cropped,
           filename = output_file,
           varname = varname_str,
           unit = unit_str,
           overwrite = TRUE)
}
