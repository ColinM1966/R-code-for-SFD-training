#1. Load packages
library(terra)
library(ncdf4)

#2. Define your model
Geo       <- "Borneo"
ESM       <- "GFDL-ESM4"
ssp       <- "historical"   # set to "historical" or "ssp126"/"ssp245"/"ssp370"/"ssp585"
Variant   <- "r1i1p1f1"
grid      <- "gr1"
version   <- "v2.0"

#3. Set your diectory
in_root   <- "E:/NASAdata"   # root where ESM/ssp/... NetCDFs live

#4. Set youthresholds (°C) - will loop and create HI41NOAA, HI46NOAA, ...
thresholds <- c(41, 46, 54)  # 46 is not one of IPCC values - it isw weher learning is severely impacted 

#5. This is in case the variable names are not standard  (you confirmed)
tas_var  <- "tasmax"
hurs_var <- "hurs"

#6. Give the coefficients for NOAA HI using the Rothfusz method in Celsius 
c1 <- -8.784694756
c2 <- 1.61139411
c3 <- 2.33854883889
c4 <- -0.14611605
c5 <- -0.012308094
c6 <- -0.0164248277778
c7 <- 0.002211732
c8 <- 0.00072546
c9 <- -0.000003582

#6. Define the Year you will loop over
years_hist <- 1981:2010
years_fut  <- 2011:2100

#7. Define the climatology windows
clims <- list(
  "1981-2010" = 1981:2010,
  "2011-2040" = 2011:2040,
  "2041-2070" = 2041:2070,
  "2071-2100" = 2071:2100
)

#8. Choose years based on ssp
if (ssp == "historical") {
  years <- years_hist
} else {
  years <- years_fut
}

#9. Build input file path for a variable and year
build_in_path <- function(varname, year) {
  # expected layout: <in_root>/<ESM>/<ssp>/<varname>/<Geo>_<varname>_day_<ESM>_<ssp>_<Variant>_<grid>_<year>_<version>.nc
  file.path(in_root, ESM, ssp, varname,
            paste0(Geo, "_", varname, "_day_", ESM, "_", ssp, "_", Variant, "_", grid, "_", year, "_", version, ".nc"))
}

#10. Output base dir for ESM/ssp
out_base <- function() file.path(in_root, ESM, ssp)  # per your request outputs sit under same root

#11. Main working 
for (yr in years) {
  message("Processing year: ", yr, " (", ESM, " | ", ssp, ")")
  
  # input NetCDFs (tasmax, hurs). These are expected to contain one layer per day in correct order.
  tas_path  <- build_in_path(tas_var, yr)
  hurs_path <- build_in_path(hurs_var, yr)
  
  if (!file.exists(tas_path)) {
    warning("Missing tasmax file: ", tas_path, " — skipping year ", yr)
    next
  }
  if (!file.exists(hurs_path)) {
    warning("Missing hurs file: ", hurs_path, " — skipping year ", yr)
    next
  }
  
  # read stacks. Try to explicitly select the variable layer if necessary.
  Tstack <- tryCatch({
    # try to request var by name; if that fails, fall back to default rast()
    tryCatch(rast(tas_path, subds = tas_var), error = function(e) rast(tas_path))
  }, error = function(e) {
    warning("Failed reading tasmax: ", e$message); return(NULL)
  })
  
  RHstack <- tryCatch({
    tryCatch(rast(hurs_path, subds = hurs_var), error = function(e) rast(hurs_path))
  }, error = function(e) {
    warning("Failed reading hurs: ", e$message); return(NULL)
  })
  
  if (is.null(Tstack) || is.null(RHstack)) next
  
  # Ensure CRS assigned (assume EPSG:4326 when missing)
  if (is.na(crs(Tstack))) crs(Tstack) <- "EPSG:4326"
  if (is.na(crs(RHstack))) crs(RHstack) <- "EPSG:4326"
  
  # layer count check
  if (nlyr(Tstack) != nlyr(RHstack)) {
    warning("Layer count mismatch (tasmax=", nlyr(Tstack), " hurs=", nlyr(RHstack), ") for year ", yr, " — skipping")
    next
  }
  
  # alias
  TI <- Tstack
  RI <- RHstack
  
  # Rothfusz (vectorised across layers)
  HI_rothfusz <- c1 +
    (c2 * TI) +
    (c3 * RI) +
    (c4 * (TI * RI)) +
    (c5 * (TI ^ 2)) +
    (c6 * (RI ^ 2)) +
    (c7 * ((TI ^ 2) * RI)) +
    (c8 * ((RI ^ 2) * TI)) +
    (c9 * ((TI ^ 2) * (RI ^ 2)))
  
  # Variant B rule: if T < 27°C => HI = T, else HI = Rothfusz
  HIstack <- ifel(TI < 27, TI, HI_rothfusz)
  
  # propagate CRS
  crs(HIstack) <- crs(Tstack)
  
  # create output folders
  hi_stack_dir <- file.path(out_base(), "HIstack")
  dir.create(hi_stack_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Write HIstack NetCDF (one file per year)
  HI_nc_out <- file.path(hi_stack_dir,
                         paste0(Geo, "_HI_", ESM, "_", ssp, "_", Variant, "_", grid, "_", yr, "_", version, ".nc"))
  tryCatch({
    writeCDF(HIstack, filename = HI_nc_out, overwrite = TRUE)
    message("  Wrote HI stack NetCDF: ", basename(HI_nc_out))
  }, error = function(e) {
    warning("  Failed to write HI NetCDF for ", yr, " : ", e$message)
  })
  
  # Loop thresholds and write annual counts as GeoTIFFs
  for (th in thresholds) {
    message("  Threshold: ", th, "°C")
    # logical raster per day: TRUE where HI >= th
    days_above_logic <- HIstack >= th
    # sum across layers (terra treats TRUE as 1)
    days_above_count <- tryCatch({
      sum(days_above_logic, na.rm = TRUE)
    }, error = function(e) {
      warning("    Failed to sum days above: ", e$message); return(NULL)
    })
    if (is.null(days_above_count)) next
    
    out_dir <- file.path(out_base(), paste0("HI", th, "NOAA"))
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    
    out_annual <- file.path(
      out_dir,
      paste0(Geo, "_HI", th, "NOAA_", ESM, "_", ssp, "_", Variant, "_", grid, "_", yr, "_", version, ".tif")
    )
    
    tryCatch({
      writeRaster(days_above_count, filename = out_annual, filetype = "GTiff",
                  overwrite = TRUE, NAflag = -9999, datatype = "INT2S")
      message("    Wrote annual GeoTIFF: ", basename(out_annual))
    }, error = function(e) {
      warning("    Failed to write annual GeoTIFF: ", e$message)
    })
    
    # cleanup per threshold
    rm(days_above_logic, days_above_count); gc()
  } # thresholds
  
  # cleanup per-year
  rm(HIstack, HI_rothfusz, Tstack, RHstack, TI, RI); gc()
} # years

################################################################################
#12. Work out the values for the CLIMATOLOGIES (30-year windows)
# -----------------------------
message("Starting climatology generation...")

for (th in thresholds) {
  
  t_dir <- file.path(out_base(), paste0("HI", th, "NOAA"))
  
  if (!dir.exists(t_dir)) {
    warning("Threshold directory missing for HI", th, " : ", t_dir, " — skipping climatologies for this threshold.")
    next
  }
  
  all_files <- list.files(t_dir, pattern = paste0("^", Geo, "_HI", th, "NOAA_.*\\.tif$"), full.names = TRUE)
  if (length(all_files) == 0) {
    warning("No annual files found in ", t_dir, " for HI", th)
    next
  }
  
  # extract year from filename (expects _YYYY_ in name)
  years_available <- as.integer(sub(".*_([0-9]{4})_.*\\.tif$", "\\1", basename(all_files)))
  file_map <- data.frame(file = all_files, year = years_available, stringsAsFactors = FALSE)
  
  for (cname in names(clims)) {
    yrs <- clims[[cname]]
    files_period <- file_map$file[file_map$year %in% yrs]
    
    if (length(files_period) == 0) {
      message("  No files for climatology window ", cname, " (HI", th, ") — skipping.")
      next
    }
    
    message("  Computing climatology for HI", th, " | window ", cname, " (n=", length(files_period), ")")
    
    s_rast <- tryCatch(rast(files_period), error = function(e) { warning("    rast() failed for files: ", e$message); return(NULL) })
    if (is.null(s_rast)) next
    
    clim_mean <- tryCatch(app(s_rast, fun = mean, na.rm = TRUE), error = function(e) { warning("    mean failed: ", e$message); return(NULL) })
    clim_max  <- tryCatch(app(s_rast, fun = max,  na.rm = TRUE), error = function(e) { warning("    max failed: ", e$message); return(NULL) })
    
    if (is.null(clim_mean) || is.null(clim_max)) next
    
    mean_fn <- file.path(
      t_dir,
      paste0(Geo, "_HI", th, "NOAA_Mean_", ESM, "_", ssp, "_", Variant, "_", grid, "_", cname, "_", version, ".tif")
    )
    
    max_fn <- file.path(
      t_dir,
      paste0(Geo, "_HI", th, "NOAA_Max_",  ESM, "_", ssp, "_", Variant, "_", grid, "_", cname, "_", version, ".tif")
    )
    
    tryCatch({
      writeRaster(clim_mean, mean_fn, filetype = "GTiff", NAflag = -9999, overwrite = TRUE, datatype = "FLT4S")
      writeRaster(clim_max,  max_fn,  filetype = "GTiff", NAflag = -9999, overwrite = TRUE, datatype = "FLT4S")
      message("    Wrote climatologies: ", basename(mean_fn), " ; ", basename(max_fn))
    }, error = function(e) {
      warning("    Failed writing climatologies: ", e$message)
    })
    
    rm(s_rast, clim_mean, clim_max); gc()
  } # cname
} # th

message("Processing complete.")
