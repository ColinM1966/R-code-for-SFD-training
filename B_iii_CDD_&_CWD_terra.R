################################################################################
# Calculates CDD (Consecutive Dry Days) and CWD (Consecutive Wet Days) for 
# all ESMs, scenarios, and 30-year climatologies in one script.
# Output: Annual CDD/CWD rasters + climatology means
# 
################################################################################
## A. For a single ESM/SSP
# 1. Load package
library(terra)

#2. Set up the run 
ESM     <- "EC-Earth3"
Variant <- "r1i1p1f1"
Grid    <- "gr"
future_ssp <- "ssp126"
Geo <- "Borneo"
version <- "v2.0"
base_path <- "C:/Users/User/Documents/Trial/"

#3. Define the 4 climatology blocks
clims <- list(
  hist   = list(ssp="historical", start=1981, end=2010),
  fut1   = list(ssp=future_ssp,  start=2011, end=2040),
  fut2   = list(ssp=future_ssp,  start=2041, end=2070),
  fut3   = list(ssp=future_ssp,  start=2071, end=2100)
)

#5. Set the thresholds
thresholds <- list(
  CDD = list(type="below",  value=1),
  CWD = list(type="aboveeq",value=1)  # >= 1 mm/day
)

cd_days <- function(x,type,value){
  if(type=="below")   m <- (x <  value)
  if(type=="aboveeq") m <- (x >= value)
  y <- rle(m*1)
  z <- y$lengths[y$values==1]
  if(length(z)==0) return(0) else return(max(z))
}

#6. Main workings for calculating CDD and CWD - don't need to modify things in here

for(block in names(clims)){
  
  ssp <- clims[[block]]$ssp
  yrs <- clims[[block]]$start:clims[[block]]$end
  
  message("processing ", block, " ", ssp)
  
  for(year in yrs){
    
    f_in <- sprintf("%s%s/%s/pr/%s_pr_day_%s_%s_%s_%s_%d_%s.nc",
                    base_path, ESM, ssp, Geo, ESM, ssp, Variant, Grid, year, version)
    
    if(!file.exists(f_in)){
      message("missing: ", f_in)
      next
    }
    
    r <- rast(f_in)
    crs(r) <- "EPSG:4326"
    
    for(idx in names(thresholds)){
      info <- thresholds[[idx]]
      DaysCount <- app(r, function(x) cd_days(x,info$type,info$value))
      
      prefix <- paste0(idx,"_1mm")
      outdir <- sprintf("%s%s/%s/%s/",base_path,ESM,ssp,prefix)
      dir.create(outdir,recursive=TRUE,showWarnings=FALSE)
      
      f_out <- sprintf("%s%s_%s_%s_%s_%s_%s_%d_%s.tif",
                       outdir, Geo, prefix, ESM, ssp, Variant, Grid, year, version)
      writeRaster(DaysCount,f_out,overwrite=TRUE)
    }
  }
}

# 7. Workings for calculating the CLIMATOLOGY mean + max for block defined in section 3

for(block in names(clims)){
  
  ssp <- clims[[block]]$ssp
  yrs <- clims[[block]]$start:clims[[block]]$end
  
  for(idx in names(thresholds)){
    prefix <- paste0(idx,"_1mm")
    
    files <- sprintf("%s%s/%s/%s/%s_%s_%s_%s_%s_%s_%d_%s.tif",
                     base_path, ESM, ssp, prefix,
                     Geo, prefix, ESM, ssp, Variant, Grid, yrs, version)
    files <- files[file.exists(files)]
    if(length(files)==0){ next }
    
    s <- rast(files)
    meanr <- app(s,mean,na.rm=TRUE)
    maxr  <- app(s,max,na.rm=TRUE)
    
    fout_mean <- sprintf("%s%s/%s/%s/%s_%s_mean_%s_%s_%d-%d_%s.tif",
                         base_path, ESM, ssp, prefix,
                         Geo, prefix, ESM, ssp,
                         clims[[block]]$start, clims[[block]]$end,
                         version)
    fout_max  <- sub("_mean_","_max_",fout_mean)
    
    writeRaster(meanr,fout_mean,overwrite=TRUE)
    writeRaster(maxr,fout_max,overwrite=TRUE)
  }
}

##############################################################################
##############################################################################
# This code runs multiple ESMs, SSPs at one time.
##############################################################################$
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



