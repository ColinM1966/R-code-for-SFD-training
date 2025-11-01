################################################################################
# Calculates Rx1day (maximum daily rainfall) for all ESMs, scenarios,
# and climatology periods. Output: Annual Rx1day rasters + climatology max and means
################################################################################
# 1. Load packages
library(terra)


# 2. Set up the model to be analysised
base_path <- "C:/Users/User/Documents/Trial/"

ESM      <- "EC-Earth3"
scenario <- "ssp126"      # or "historical"
Variant  <- "r1i1p1f1"
Grid     <- "gr"
Geo      <- "Borneo"
version  <- "v2.0"
## --------------------------------------------------

years <- if(scenario=="historical") 1981:2010 else 2011:2100

annual_files <- c()

# 3. Calaculate the annual Rx1day ----
for (year in years) {
  
  in_file <- file.path(
    base_path,ESM,scenario,"pr",
    paste0(Geo,"_pr_day_",ESM,"_",scenario,"_",Variant,"_",Grid,"_",year,"_",version,".nc")
  )
  
  if(!file.exists(in_file)) {
    message("missing ",in_file)
    next
  }
  
  pr <- rast(in_file)
  crs(pr) <- "EPSG:4326"
  
  ## Rx1day = max daily rainfall
  Rx1 <- app(pr, fun=max, na.rm=TRUE)
  
  out_dir <- file.path(base_path,ESM,scenario,"Rx1day")
  dir.create(out_dir,recursive=TRUE,showWarnings=FALSE)
  
  out_file <- file.path(
    out_dir,
    paste0(Geo,"_Rx1day_",ESM,"_",scenario,"_",Variant,"_",Grid,"_",year,"_",version,".tif")
  )
  
  writeRaster(Rx1,out_file,filetype="GTiff",NAflag=-9999,overwrite=TRUE)
  annual_files <- c(annual_files,out_file)
}


# 4. Calculate the mean and max Rx1day for each climatology
clim_periods <- list(
  "1981-2010" = 1981:2010,
  "2011-2040" = 2011:2040,
  "2041-2070" = 2041:2070,
  "2071-2100" = 2071:2100
)

for (period_name in names(clim_periods)) {
  
  yrs <- clim_periods[[period_name]]
  
  if(!any(years %in% yrs)) next
  
  files_period <- annual_files[
    grep(paste(yrs,collapse="|"),annual_files)
  ]
  
  if(length(files_period)==0) next
  
  stk <- rast(files_period)
  
  Rmean <- app(stk,mean,na.rm=TRUE)
  Rmax  <- app(stk,max ,na.rm=TRUE)
  
  out_mean <- file.path(
    base_path,ESM,scenario,"Rx1day",
    paste0(Geo,"_Rx1day_mean_",ESM,"_",scenario,"_",period_name,"_",version,".tif")
  )
  out_max <- file.path(
    base_path,ESM,scenario,"Rx1day",
    paste0(Geo,"_Rx1day_max_",ESM,"_",scenario,"_",period_name,"_",version,".tif")
  )
  
  writeRaster(Rmean,out_mean,filetype="GTiff",NAflag=-9999,overwrite=TRUE)
  writeRaster(Rmax ,out_max ,filetype="GTiff",NAflag=-9999,overwrite=TRUE)
}





#################################################################################
# This code is for batch runs of ESM/SSP/Climatologies
##################################################################################
library(raster)
library(sp)

# 1. Model setup
models <- list(
  list(ESM = "IPSL-CM6A-LR", Variant = "r1i1p1f1", Grid = "gr"),
  list(ESM = "GFDL-ESM4",    Variant = "r1i1p1f1", Grid = "gr1")
)

#list(ESM = "MPI-ESM1-2-HR",Variant = "r1i1p1f1", Grid = "gn"),
# list(ESM = "MRI-ESM2-0",   Variant = "r1i1p1f1", Grid = "gn"),
# list(ESM = "UKESM1-0-LL",  Variant = "r1i1p1f2", Grid = "gn")

Geo <- "Borneo"
version <- "v2.0"
base_path <- "C:/Users/User/Documents/NASAdata/"

# 2. Scenarios
scenarios <- list(
  historical = 1981:2010,
  ssp126 = 2011:2100,
  ssp245 = 2011:2100,
  ssp370 = 2011:2100,
  ssp585 = 2011:2100
)

# 3. Climatology periods
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

# 4. Loop to calculate annual Rx1day
for (model in models) {
  ESM <- model$ESM
  Variant <- model$Variant
  Grid <- model$Grid
  
  for (ssp in names(scenarios)) {
    years <- scenarios[[ssp]]
    
    for (year in years) {
      input_file <- file.path(base_path, ESM, ssp, "pr", 
                              paste0(Geo, "_pr_day_", ESM, "_", ssp, "_", Variant, "_", Grid, "_", year, "_", version, ".nc"))
      
      if (!file.exists(input_file)) {
        message("Missing file: ", input_file)
        next
      }
      
      pr <- brick(input_file)
      proj4string(pr) <- CRS("+proj=longlat +datum=WGS84")
      
     # Calculate Rx1day (annual max of daily rainfall)
      Rx1day <- calc(pr, fun = max, na.rm = TRUE)
      
      out_dir <- file.path(base_path, ESM, ssp, "Rx1day")
      dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
      
      out_file <- file.path(out_dir, 
                            paste0(Geo, "_Rx1day_", ESM, "_", ssp, "_", Variant, "_", Grid, "_", year,"_", version, ".tif"))
      
      writeRaster(Rx1day, out_file, format = "GTiff", NAflag = -9999, overwrite = TRUE)
      message("Saved: ", out_file)
    }
  }
}

# 5. Climatology max and means for Rx1day
for (model in models) {
  ESM <- model$ESM
  Variant <- model$Variant
  Grid <- model$Grid
  
  for (period_key in names(climatology_periods)) {
    period <- climatology_periods[[period_key]]
    ssp_match <- gsub("_.*", "", period_key)
    
    if (!ssp_match %in% names(scenarios)) next
    
    years <- seq(period[1], period[2])
    files <- file.path(base_path, ESM, ssp_match, "Rx1day", 
                       paste0(Geo, "_Rx1day_", ESM, "_", ssp_match, "_", Variant, "_", Grid, "_", years, "_", version, ".tif"))
    files <- files[file.exists(files)]
    
    if (length(files) == 0) {
      message("No Rx1day files found for ", ESM, " ", period_key)
      next
    }
    
    Rx_stack <- stack(files)
    Rx1day_mean <- calc(Rx_stack, mean, na.rm = TRUE)
    
   Rx1day_max <- calc(Rx_stack, max, na.rm = TRUE)
    
    Rx1day_mean_file <- file.path(base_path, ESM, ssp_match, "Rx1day",
                                  paste0(Geo, "_Rx1day_mean_", ESM, "_", ssp_match, "_", period[1], "-", period[2], "_", version, ".tif"))
    
    Rx1day_max_file <- file.path(base_path, ESM, ssp_match, "Rx1day",
                                 paste0(Geo, "_Rx1day_max_", ESM, "_", ssp_match, "_", period[1], "-", period[2], "_", version, ".tif"))
    
    writeRaster(Rx1day_mean, Rx1day_mean_file, format = "GTiff", NAflag = -9999, overwrite = TRUE)
    writeRaster(Rx1day_max, Rx1day_max_file, format = "GTiff", NAflag = -9999, overwrite = TRUE)
    
    message("Climatology saved: ", Rx1day_mean_file)
    message("Climatology saved: ", Rx1day_max_file)
  }

}

