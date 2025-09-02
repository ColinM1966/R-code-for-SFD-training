###############################################################################
#  III Precipitation (P) to Potential Evaoptranspiration (PET) ratio
#
#  Calculates mean monthly PET using Thornthwaite (1948) equation from mean 
#  monthly temperature and day length. Then convert this to a ratio of 
#  precipitation to PET. The final bit of code uses the run length encoding 
# function to determine the number of consecutive months when the ratio is below 1.
############################################################################
#1. Load required packages
library(terra)
library(geosphere)

#2. Defines model and pathway
esm <- "MPI-ESM1-2-LR"
ssp <- "ssp585"
geo <- "Borneo"
base_dir <- "D:/CHELSA"

#3. Define climatology periods
time_periods <- c("1981-2010", "2011-2040", "2041-2070", "2071-2100")

# for loop for working through the climatologies
for (period in time_periods) {
  
  message("? Processing: ", esm, " | ", ssp, " | ", period)
  
  out_dir  <- file.path(base_dir, esm, ssp, "PtoPET", period)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  
  # --- Load TAS (°C expected) ---
  tas_files <- list.files(
    file.path(base_dir, esm, ssp),
    pattern = paste0(geo,"_tas_",esm,"_",ssp,"_",period,".nc$"),
    full.names = TRUE
  )
  if (length(tas_files) == 0) stop("? No TAS file found for ", period)
  tas <- rast(tas_files)
  
  # --- Load PR (mm/month expected) ---
  pr_files <- list.files(
    file.path(base_dir, esm, ssp),
    pattern = paste0(geo,"_pr_",esm,"_",ssp,"_",period,".nc$"),
    full.names = TRUE
  )
  if (length(pr_files) == 0) stop("? No PR file found for ", period)
  pr <- rast(pr_files)
  
  # Reproject to WGS84 if needed (for geosphere::daylength)
  if (!grepl("longlat", crs(tas))) {
    tas <- project(tas, "EPSG:4326")
    pr  <- project(pr, "EPSG:4326")
  }
  
  # --- Ensure TAS is in °C (CHELSA often is; CMIP raw tas is K). Auto-convert if it looks like Kelvin.
  # If monthly temps have values > 100, assume K and convert.
  if (global(tas, "mean", na.rm = TRUE)[1,1] > 100) {
    tas <- tas - 273.15
  }
  
  # --- Precipitation should be non-negative
  pr <- ifel(pr < 0, 0, pr)
  
  # --- Day length rasters (hours) per month (using mid-month J)
  days <- list()
  lat_vals <- yFromRow(tas, 1:nrow(tas))
  for (i in 1:12) {
    J  <- (i * 30) - 15
    dl <- sapply(lat_vals, function(v) daylength(v, J))  # hours
    mat <- matrix(rep(dl, each = ncol(tas)), nrow = nrow(tas), byrow = FALSE)
    days[[i]] <- rast(mat, extent = ext(tas), crs = crs(tas))
  }
  days <- rast(days); names(days) <- month.abb
  
  # --- Thornthwaite PET
  N <- c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
  
  # Heat index I per cell: sum over 12 months of (T/5)^1.514 for T>0
  I_vals <- (tas / 5) ^ 1.514
  I_vals[tas < 0] <- 0
  I <- app(I_vals, sum, na.rm = TRUE)
  
  # Avoid divide-by-zero where I == 0 (keep I>= tiny)
  I <- ifel(I <= 0, 1e-6, I)
  
  # Alpha per cell
  alpha <- ((6.75e-7) * (I^3)) - ((7.71e-5) * (I^2)) + (0.01792 * I) + 0.49239
  
  # Monthly PET with correct (N/30) factor (this was causing PET inflation before)
  PET_fun <- function(TM, dl, ndays, I, alpha) {
    TM <- ifel(TM < 0, 0, TM)
    mdays <- (dl / 12) * (ndays / 30)      # ? correct Thornthwaite monthly factor
    PET <- 16 * mdays * ((10 * TM / I) ^ alpha)
    ifel(is.na(PET), 0, PET)
  }
  
  PET_list <- vector("list", 12)
  for (i in 1:12) {
    PET_list[[i]] <- PET_fun(tas[[i]], days[[i]], N[i], I, alpha)
  }
  PET <- rast(PET_list); names(PET) <- month.abb
  
  # --- Compute P:PET ratio ---
  ratio <- pr / PET
  
  # --- Run Length Encoding (RLE) for ratio < 1 ---
  rle_fun <- function(x) {
    if (all(is.na(x))) return(NA)
    
    # Condition: months where ratio < 1
    cond <- x < 1
    
    # Use run length encoding
    r <- rle(cond)
    
    # Longest consecutive run of TRUE values
    longest <- if (any(r$values)) max(r$lengths[r$values]) else 0
    return(longest)
  }
  
  # Apply pixel-wise over time
  longest_below1 <- app(ratio, rle_fun)
  
  # --- Save outputs ---
  out_dir <- file.path(base_dir, esm, ssp, "PtoPET", period)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  
  out_nc <- file.path(out_dir, paste0(geo, "_PtoPET_", esm, "_", ssp, "_", period, ".nc"))
  writeCDF(ratio, out_nc, overwrite = TRUE, filetype = "netCDF")
  
  out_rle <- file.path(out_dir, paste0(geo, "_Cum_Dry_Mths_", esm, "_", ssp, "_", period, ".tif"))
  writeRaster(longest_below1, out_rle, overwrite = TRUE)
  
}


}