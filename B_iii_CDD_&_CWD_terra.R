################################################################################
# Calculates CDD (Consecutive Dry Days) and CWD (Consecutive Wet Days) for 
# all ESMs, scenarios, and 30-year climatologies in one script.
# Output: Annual CDD/CWD rasters + climatology means
################################################################################

# 1. Load required libraries
library(terra)

# 2. Define model and spatial configuration
models <- list(
  list(ESM = "IPSL-CM6A-LR", Variant = "r1i1p1f1", Grid = "gr"),
  list(ESM = "GFDL-ESM4",    Variant = "r1i1p1f1", Grid = "gr1"),
  list(ESM = "MPI-ESM1-2-HR",Variant = "r1i1p1f1", Grid = "gn"),
  list(ESM = "MRI-ESM2-0",   Variant = "r1i1p1f1", Grid = "gn"),
  list(ESM = "UKESM1-0-LL",  Variant = "r1i1p1f2", Grid = "gn")
)

Geo <- "Borneo"
version <- "v2.0"
base_path <- "C:/Users/User/Documents/NASAdata/"

# 3. Define scenarios and their year ranges
scenarios <- list(
  historical = 1981:2010,
  ssp126 = 2011:2100,
  ssp245 = 2011:2100,
  ssp370 = 2011:2100,
  ssp585 = 2011:2100
)

# 4. Define climatology periods
climatology_periods <- list(
  historical = c(1981, 2010),
  ssp126_2011_2040 = c(2011, 2040),
  ssp126_2041_2070 = c(2041, 2070),
  ssp126_2071_2100 = c(2071, 2100),
  ssp245_2011_2040 = c(2011, 2040),
  ssp245_2041_2070 = c(2041, 2070),
  ssp245_2071_2100 = c(2071, 2100),
  ssp370_2011_2040 = c(2011, 2040),
  ssp370_2041_2070 = c(2041, 2070),
  ssp370_2071_2100 = c(2071, 2100),
  ssp585_2011_2040 = c(2011, 2040),
  ssp585_2041_2070 = c(2041, 2070),
  ssp585_2071_2100 = c(2071, 2100)
)

# 5. Thresholds for CDD and CWD (in mm/day)
thresholds <- list(
  CDD = list(type = "below", value = 1), # Dry if < 1 mm/day
  CWD = list(type = "above", value = 1)  # Wet if > 1 mm/day
)

# 6. Function to calculate CDD/CWD
cd_days <- function(x, type, value) {
  y <- if (type == "below") rle((x < value) * 1) else rle((x >= value) * 1)
  z <- y$lengths[y$values == 1]
  return(max(z, 0))
}

# 7. Calculate annual CDD/CWD
for (model in models) {
  ESM <- model$ESM
  Variant <- model$Variant
  Grid <- model$Grid
  
  for (ssp in names(scenarios)) {
    years <- scenarios[[ssp]]
    
    for (year in years) {
      input_file <- paste0(base_path, ESM, "/", ssp, "/", "pr/", 
                           Geo, "_pr_day_", ESM, "_", ssp, "_", Variant, "_", Grid, "_", year,"_", version, ".nc")
      
      if (!file.exists(input_file)) {
        message("Missing file: ", input_file)
        next
      }
      
      DaysB <- rast(input_file)
      crs(DaysB) <- "EPSG:4326" 
      
      for (index_name in names(thresholds)) {
        index_info <- thresholds[[index_name]]
        DaysCount <- app(DaysB, function(x) cd_days(x, index_info$type, index_info$value))
        
        prefix <- paste0(index_name, "_1mm")  # CDD_1mm or CWD_1mm
        out_dir <- paste0(base_path, ESM, "/", ssp, "/", prefix, "/")
        dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
        
        output_file <- paste0(out_dir, Geo, "_", prefix, "_", ESM, "_", ssp, "_", Variant, "_", Grid, "_", year,"_", version, ".tif")
        writeRaster(DaysCount, output_file, filetype = "GTiff", NAflag = -9999, overwrite = TRUE)
        message("Saved: ", output_file)
      }
    }
  }
}

# 8. Compute climatology means & max
for (model in models) {
  ESM <- model$ESM
  Variant <- model$Variant
  Grid <- model$Grid
  
  for (index_name in names(thresholds)) {
    prefix <- paste0(index_name, "_1mm")
    
    for (period_key in names(climatology_periods)) {
      period <- climatology_periods[[period_key]]
      ssp_match <- gsub("_.*", "", period_key)  # Extract scenario name
      
      if (!ssp_match %in% names(scenarios)) next
      
      years <- seq(period[1], period[2])
      files <- paste0(base_path, ESM, "/", ssp_match, "/", prefix, "/", 
                      Geo, "_", prefix, "_", ESM, "_", ssp_match, "_", Variant, "_", Grid, "_", years,"_", version, ".tif")
      files <- files[file.exists(files)]
      
      if (length(files) == 0) {
        message("No files found for ", ESM, " ", prefix, " ", period_key)
        next
      }
      
      raster_stack <- rast(files)
      climatology_mean <- app(raster_stack, mean, na.rm = TRUE)
      climatology_max <- app(raster_stack, max, na.rm = TRUE)
      
      out_file_mean <- paste0(base_path, ESM, "/", ssp_match, "/", prefix, "/", 
                         Geo, "_", prefix, "_mean_", ESM, "_", ssp_match, "_", period[1], "-", period[2],"-", version, ".tif")
      out_file_max <- paste0(base_path, ESM, "/", ssp_match, "/", prefix, "/", 
                              Geo, "_", prefix, "_max_", ESM, "_", ssp_match, "_", period[1], "-", period[2],"-", version, ".tif")
      writeRaster(climatology_mean, out_file_mean, filetype = "GTiff", NAflag = -9999, overwrite = TRUE)
      writeRaster(climatology_max, out_file_max, filetype = "GTiff", NAflag = -9999, overwrite = TRUE)
      message("Climatology saved: ", out_file_mean)
      message("Climatology saved: ", out_file_max)
      }
  }
}

