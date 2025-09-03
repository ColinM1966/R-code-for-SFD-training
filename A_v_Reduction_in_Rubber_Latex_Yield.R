###############################################################################
#            *****  Reduction in Rubber Latex Production  *****
#              *** terra version (1 ESM & 1 SSP at a time) ***
# Based on findings of Ali et al. 2020 that there is a decline of ~3 g per tapping 
# per tree (g t−1 t−1) per 1 °C rise in minimum temperature above 23°C
###############################################################################

library(terra)
terraOptions(memfrac = 0.6, todisk = TRUE)
# ---------------- USER INPUT ----------------
base_dir <- "D:/Chelsa"    # root directory
out_dir  <- file.path(base_dir, esm, ssp)

esm  <- "MPI-ESM1-2-LR"      # <- set one ESM
ssp  <- "ssp585"             # <- set one SSP
geo  <- "Borneo"             # <- region name
climatologies <- c("1981-2010", "2011-2040")#, "2041-2070", "2071-2100")

# thresholds
b1 <- -23      # Tmin threshold
b2 <- -5.784   # Yield reduction factor

# ---------------- FUNCTIONS ----------------
get_tempdiff <- function(r) r + b1
clean_temp   <- function(r) ifel(r < 0, 0, r)   # avoids pulling into memory
get_LY       <- function(ft, ct) (ft - ct) * b2

# ---------------- BASELINE ----------------
# Load current Tmin (1981–2010) for this ESM
current_file <- list.files(
  file.path(base_dir, esm, ssp),
  pattern = paste0(geo, "_tasmin_", esm, "_", ssp, "_1981-2010\\.nc$"),
  full.names = TRUE
)

if (length(current_file) == 0) stop("No baseline file found for ", esm, " ", ssp)

tminCurrentS <- rast(current_file)

# ---------------- MAIN LOOP ----------------
for (clim in climatologies) {
  
  message("Processing: ", esm, " | ", ssp, " | ", clim)
  
  # Skip SSP runs for historical
  if (clim == "1981-2010" && ssp != "historical") next
  
  # Find future Tmin file for this climatology
  fut_file <- list.files(
    file.path(base_dir, esm, ssp),
    pattern = paste0(geo, "_tasmin_", esm, "_", ssp, "_", clim, "\\.nc$"),
    full.names = TRUE
  )
  
  if (length(fut_file) == 0) {
    warning("No file found for ", esm, " - ", ssp, " - ", clim)
    next
  }
  
  tminFutureS <- rast(fut_file)
  
  # Step 1: Adjust Tmin
  Tempft <- clean_temp(get_tempdiff(tminFutureS))
  Tempct <- clean_temp(get_tempdiff(tminCurrentS))
  
  # Step 2: Latex yield reduction
  LYR <- get_LY(Tempft, Tempct)   # multilayer (12 months)
  
  # Output directory
  esm_out <- file.path(out_dir,"Rubber")
  dir.create(esm_out, recursive = TRUE, showWarnings = FALSE)
  
  # Step 3: Write monthly results as NetCDF
  nc_file <- file.path(
    esm_out,
    paste0(geo, "_Rub_Latex_Monthly_", esm, "_", ssp, "_", clim, ".nc")
  )
  writeCDF(LYR, nc_file,filetype = "netCDF", overwrite = TRUE, NAflag = -9999)
  
  # Step 4: Calculate annual statistics
  annual_mean <- mean(LYR)
  annual_max  <- max(LYR)
  annual_min  <- min(LYR)
  
  # Step 5: Write annual summaries
  writeRaster(
    annual_mean,
    file.path(esm_out, paste0(geo, "_Rub_Latex_AnnualMean_", esm, "_", ssp, "_", clim, ".tif")),
    overwrite = TRUE, NAflag = -9999
  )
  writeRaster(
    annual_max,
    file.path(esm_out, paste0(geo, "_Rub_Latex_AnnualMax_", esm, "_", ssp, "_", clim, ".tif")),
    overwrite = TRUE, NAflag = -9999
  )
  writeRaster(
    annual_min,
    file.path(esm_out, paste0(geo, "_Rub_Latex_AnnualMin_", esm, "_", ssp, "_", clim, ".tif")),
    overwrite = TRUE, NAflag = -9999
  )
}

