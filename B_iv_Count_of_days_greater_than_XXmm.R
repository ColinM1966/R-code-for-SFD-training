################################################################################
## Daily rainfall exceedance analysis for multiple thresholds
## Includes: 
##   A. Annual count of days exceeding threshold
##   B. Climatological max and mean over a set period
################################################################################
## A. 
# 1. Load the required packages
library(terra)

# 2. Define the model you are working on and where find files
base_path <- "C:/Users/User/Documents/Trial/" 

ESM      <- "EC-Earth3"   # Change this to the ESM you are working with
scenario <- "ssp126"      # or "historical", "ssp245", ssp370" or "ssp585"
Variant  <- "r1i1p1f1"    # Check the appropriate variant for your ESM
Grid     <- "gr"          # Check the appropriate grid for your ESM
Geo      <- "Borneo"
version  <- "v2.0"        
thresholds_mm <- c(1,5,10,20,50)   # These are the threshold in Appenda 6 of the IPCC WG I report, can be change to a user defined value 
## --------------------------------------------------

years <- if(scenario=="historical") 1981:2010 else 2011:2100   

for (t_v in thresholds_mm) {
  
  annual_files <- c()
  
  for (year in years) {
    
    folder_path <- paste0(
      base_path,ESM,"/",scenario,"/pr/",
      Geo,"_pr_day_",ESM,"_",scenario,"_",Variant,"_",Grid,"_",
      year,"_",version
    )
    
    days_file <- paste0(folder_path,".nc")
    
    if (!file.exists(days_file)) {
      warning("missing ",days_file)
      next
    }
    
    DaysB <- rast(days_file)
    crs(DaysB) <- "EPSG:4326"
    
    days_above <- app(DaysB, fun=function(x) sum(x>=t_v,na.rm=TRUE))
    
    out_file <- paste0(
      base_path,ESM,"/",scenario,"/R",t_v,"mm/",
      Geo,"_R",t_v,"mm_",
      ESM,"_",scenario,"_",Variant,"_",Grid,"_",year,"_",version,".tif"
    )
    dir.create(dirname(out_file),recursive=TRUE,showWarnings=FALSE)
    writeRaster(days_above,out_file,filetype="GTiff",NAflag=-9999,overwrite=TRUE)
    
    annual_files <- c(annual_files,out_file)
  }
  
  if(length(annual_files)==0) next
  
  ## B. Defines the 4 climatology periods
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
    
    stk  <- rast(files_period)
    meanR <- app(stk,fun=mean,na.rm=TRUE)
    maxR  <- app(stk,fun=max ,na.rm=TRUE)
    
    out_mean <- paste0(
      base_path,ESM,"/",scenario,"/R",t_v,"mm/",
      Geo,"_R",t_v,"mm_mean_",
      ESM,"_",scenario,"_",period_name,"_",version,".tif"
    )
    out_max <- paste0(
      base_path,ESM,"/",scenario,"/R",t_v,"mm/",
      Geo,"_R",t_v,"mm_max_",
      ESM,"_",scenario,"_",period_name,"_",version,".tif"
    )
    
    writeRaster(meanR,out_mean,filetype="GTiff",NAflag=-9999,overwrite=TRUE)
    writeRaster(maxR ,out_max ,filetype="GTiff",NAflag=-9999,overwrite=TRUE)
  }
}


###############################################################################
# Analaysia multiple SSP for one ESM                      
################################################################################
# 1. Load required packages
library(terra)

# 2. Set model-specific info
ESM <- "IPSL-CM6A-LR"    # options are: IPSL-CM6A-LR, GFDL-ESM4, MPI-ESM1-2-HR, MRI-ESM2-0, UKESM1-0-LL
Variant <- "r1i1p1f1"   # options are: r1i1p1f2 (UKESM1), r1i1p1f1 for other models
Grid <- "gr"            # Options: gn (others), gr (ipsl), gr1 (gfdl)
Geo <- "Borneo"
version <- "v2.0"
thresholds_mm <- c(1, 5, 10, 20, 50)
crs_info <- CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")

# 3. Define scenarios and their year ranges
scenarios <- list(
  historical = 1981:2010,
  ssp126 = 2011:2100,
  ssp245 = 2011:2100,
  ssp370 = 2011:2100,
  ssp585 = 2011:2100
)

# 4. Loop over all scenarios
for (scenario in names(scenarios)) {
  for (t_v in thresholds_mm) {
    annual_files <- c()  # Store file paths for climatology
    
    for (year in scenarios[[scenario]]) {
      message("Processing: ", ESM, " | ", scenario, " | ", year, " | Threshold: ", t_v, "mm")
      
      # Define file paths
      folder_path <- paste0("C:/Users/User/Documents/NASAdata/", ESM, "/", scenario, "/", "pr", "/", Geo, "_pr_day_", ESM, "_", scenario, "_", Variant, "_", Grid, "_", year,  "_", version)
      days_file <- paste0(folder_path, ".nc")
      
      if (!file.exists(days_file)) {
        warning("File not found: ", days_file)
        next
      }
      
      # Load daily rainfall
      DaysB <- rast(days_file)
      crs(DaysB) <- "EPSG:4326" 
      
      # Count number of days above threshold
      days_above_threshold <- app(DaysB, fun = function(x) sum(x >= t_v, na.rm = TRUE))
      
      # Output path for annual exceedance raster
      output_file <- paste0("C:/Users/User/Documents/NASAdata/", ESM, "/", scenario, "/", "R", t_v, "mm", "/", Geo, "_R", t_v, "mm_", ESM, "_", scenario, "_", Variant, "_", Grid, "_", year,"_", version, ".tif")
      dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
      writeRaster(days_above_threshold, output_file, filetype = "GTiff", NAflag = -9999, overwrite = TRUE)
      
      annual_files <- c(annual_files, output_file)
    }
    
    # B. Climatology mean over the processed years
    file_names <- basename(annual_files)
    years_used <- sub(".*_([0-9]{4})_v[0-9.]+\\.tif$", "\\1", file_names)
    years_used <- as.integer(years_used)
    
    # Attach years to file paths
    file_year_map <- data.frame(file = annual_files, year = years_used, stringsAsFactors = FALSE)
    
    if (scenario == "historical") {
      # Historical: only one climatology period
      files_in_period <- file_year_map$file[file_year_map$year %in% 1981:2010]
      
      if (length(files_in_period) > 0) {
        message("Computing historical climatology 1981–2010 | R", t_v, "mm")
        raster_stack <- rast(files_in_period)
        climatology_mean <- app(raster_stack, fun = mean, na.rm = TRUE)
        climatology_max <- app(raster_stack, fun = max, na.rm = TRUE)
        
        clim_output_file_mean <- paste0(
          "C:/Users/User/Documents/NASAdata/", ESM, "/", scenario, "/",
          "R", t_v, "mm", "/", Geo, "_R", t_v, "mm_mean_", ESM, "_", scenario, "_1981-2010","_", version, ".tif"
        )
        clim_output_file_max <- paste0(
          "C:/Users/User/Documents/NASAdata/", ESM, "/", scenario, "/",
          "R", t_v, "mm", "/", Geo, "_R", t_v, "mm_max_", ESM, "_", scenario, "_1981-2010","_", version, ".tif"
        )
        writeRaster(climatology_mean, clim_output_file_mean, filetype = "GTiff", NAflag = -9999, overwrite = TRUE)
        writeRaster(climatology_max, clim_output_file_max, filetype = "GTiff", NAflag = -9999, overwrite = TRUE)
        message("Saved historical climatology: ", clim_output_file_mean)
        message("Saved historical climatology: ", clim_output_file_max)
      } else {
        warning("No historical files found for R", t_v, "mm")
      }
      
    } else {
      # Future SSPs: three periods
      clim_periods <- list(
        "2011-2040" = 2011:2040,
        "2041-2070" = 2041:2070,
        "2071-2100" = 2071:2100
      )
      
      for (period_name in names(clim_periods)) {
        years_in_period <- clim_periods[[period_name]]
        files_in_period <- file_year_map$file[file_year_map$year %in% years_in_period]
        
        if (length(files_in_period) > 0) {
          message("Computing SSP climatology ", period_name, " | R", t_v, "mm | ", scenario)
          raster_stack <- rast(files_in_period)
          climatology_mean <- app(raster_stack, fun = mean, na.rm = TRUE)
          climatology_max <- app(raster_stack, fun = max, na.rm = TRUE)
          
          clim_output_file_mean <- paste0(
            "C:/Users/User/Documents/NASAdata/", ESM, "/", scenario, "/",
            "R", t_v, "mm", "/", Geo, "_R", t_v, "mm_mean_", ESM, "_", scenario, "_", period_name,"_", version,  ".tif"
          )
          clim_output_file_max <- paste0(
            "C:/Users/User/Documents/NASAdata/", ESM, "/", scenario, "/",
            "R", t_v, "mm", "/", Geo, "_R", t_v, "mm_max_", ESM, "_", scenario, "_", period_name,"_", version,  ".tif"
          )
          
          writeRaster(climatology_mean, clim_output_file_mean, filetype = "GTiff", NAflag = -9999, overwrite = TRUE)
          writeRaster(climatology_max, clim_output_file_max, filetype = "GTiff", NAflag = -9999, overwrite = TRUE)
          
          message("Climatology saved: ", clim_output_file_mean)
          message("Climatology saved: ", clim_output_file_max)
        } else {
          warning("No files for ", scenario, " ", period_name, " R", t_v, "mm")
        }
      }
    }
  }
}


