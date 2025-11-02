###############################################################################
#                      Tropical Nights
# Calculate the number of nights above user defined thresholds - the standard IPCC and
# other used in the literature
# Part A.  Calculates number of days above multiple temperature thresholds for tasmin
# Part B. 
###############################################################################
## A. Calculates number of days above multiple temperature thresholds for tasmin
# 1. Load package
library(terra)

# 2. Define PARAMETERS

ESM     <- "GFDL-ESM4"
Variant <- "r1i1p1f1"
Grid    <- "gr1"
Geo     <- "Borneo"
version <- "_v2.0"

scenarios <- list(
  historical = 1981:2010,
  ssp126     = 2011:2100
)

thresholds_C <- c(20,22,25,28,30) # already °C

# 3. Specify the directories 
in_root  <- "D:/NASAdata"
out_root <- "D:/NASAdata"

### ------------------------------------------------------------------------ ###
# 4. The workings

for(SSP in names(scenarios)) {
  
  years <- scenarios[[SSP]]
  
  for(year in years) {
    
    in_file <- file.path(
      in_root,
      ESM,
      SSP,
      "tasmin",
      paste0(
        Geo,"_tasmin_day_",ESM,"_",SSP,"_",Variant,"_",Grid,"_",year,version,".nc"
      )
    )
    
    if(!file.exists(in_file)) {
      warning("Missing file: ", in_file)
      next
    }
    
    message("Processing: ", SSP," - ",year)
    
    DaysB <- tryCatch(
      rast(in_file),
      error = function(e) { warning(e$message); return(NULL) }
    )
    if(is.null(DaysB)) next
    
    crs(DaysB) <- "EPSG:4326"
    
    for(t_C in thresholds_C) {
      
      # terra: sum logical layers
      days_abv <- sum(DaysB >= t_C, na.rm = TRUE)
      
      out_dir <- file.path(out_root, ESM, SSP, paste0("TN_",t_C,"_min"))
      if(!dir.exists(out_dir)) dir.create(out_dir, recursive=TRUE)
      
      out_file <- file.path(
        out_dir,
        paste0(
          Geo,"_TN",t_C,"min_",ESM,"_",SSP,"_",Variant,"_",Grid,"_",year,version,".tif"
        )
      )
      
      writeRaster(days_abv, out_file, overwrite = TRUE, NAflag = -9999)
    }
  }
}

###############################################################################
## B. Climatology mean & max for each threshold
###############################################################################

# 1. Define the climatologies
clims <- list(
  "1981-2010"  = 1981:2010,
  "2011-2040"   = 2011:2040,
  "2041-2070"   = 2041:2070,
  "2071-2100"   = 2071:2100
)

# 2. The workings
for(SSP in names(scenarios)) {
  for(t_C in thresholds_C) {
    
    # parent folder for that threshold
    t_dir <- file.path(out_root, ESM, SSP, paste0("TN_",t_C,"_min"))
    
    for(cname in names(clims)) {
      
      yrs <- clims[[cname]]
      
      # list files for these years only
      fls <- NULL
      for(y in yrs){
        f <- file.path(
          t_dir,
          paste0(Geo,"_TN",t_C,"min_",ESM,"_",SSP,"_",Variant,"_",Grid,"_",y,version,".tif")
        )
        if(file.exists(f)) fls <- c(fls,f)
      }
      
      if(length(fls) == 0) next
      
      rstack <- rast(fls)
      
      mean_r <- mean(rstack, na.rm=TRUE)
      max_r  <- max(rstack, na.rm=TRUE)
      
      # write
      mean_file <- file.path(
        t_dir,
        paste0(
          Geo, "_TN",t_C,"min","_Mean_",
          ESM,"_",SSP,"_",Variant,"_",Grid,"_",cname,version,".tif"
        )
      )
      
      max_file <- file.path(
        t_dir,
        paste0(
          Geo, "_TN",t_C,"min","_Max_",
          ESM,"_",SSP,"_",Variant,"_",Grid,"_",cname,version,".tif"
        )
      )
      
      writeRaster(mean_r, mean_file, overwrite=TRUE, NAflag=-9999)
      writeRaster(max_r , max_file , overwrite=TRUE, NAflag=-9999)    
      message("climatology done: ", SSP," - TN>",t_C,"°C  ",cname)
    }
  }
}
