###############################################################################
#              Time series of CHELSA CMIP6 
# This code creates a monthly timeseries for the ESM. IT involves some
# adaptation of the fefps, and fefpe parameter of the function and a for loop.
# The output will be a netCDF files for each month from 2016, 2100 for tas,
# tasmax, tasmin, and pr, and an annual timeseries for the bioclimatic 
# variables. Notice the change in dates in fefps and fefpe, which need to
# be the end and start of the year. If the model you choose uses a 360 day
# calender (e.g. UKESM1-0-LL), the last day of the year is the 30th.
# (Note: this takes a very long time to run)
###############################################################################
# A. Downloading time series data from CMIP6
# 1. Load package and 
library(reticulate)
library(terra)
use_virtualenv("chelsa_env", required = TRUE)
chelsa_cmip6 <- import("chelsa_cmip6")


# 2. Load reference raster and extracts extent
ref_raster <- rast("C:/Users/User/Documents/Borneo_pr_day_GFDL-ESM4_ssp126_r1i1p1f1_gr1_2015.tif")
e <- ext(ref_raster)

#3.  Define model, scenario and climatology
source_id        <- 'MPI-ESM1-2-LR'     #
experiment_id    <- 'ssp585'            # Shared socioeconomic pathways option ssp126, ssp245, ssp370, ssp585
institution_id   <- 'MPI-M'             #
member_id        <- 'r1i1p1f1'          # 
Base_start       <-  '1981-01-15'       # start date for the baseline
Base_finish      <- '2010-12-15'        # end date for the baseline
Climato_start    <- '2011-01-15'        # start date for the projection
Climato_finish   <- '2040-12-15'        # end date for the projection

#4. construct output folder structure
outdir <- file.path("C:/Users/User/Documents", source_id, experiment_id)
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

# 5. For loop for time series data
for (year in 2016:2100) {
  chelsa_cmip6$GetClim$chelsa_cmip6(
    activity_id   = "ScenarioMIP",
    table_id      = "Amon",
    experiment_id = experiment_id,
    institution_id= institution_id,
    source_id     = source_id,
    member_id     = member_id,
    refps         = Base_start, 
    refpe         = Base_finish,
    fefps         = sprintf("%d-01-01", year),
    fefpe         = sprintf("%d-12-31", year),
    xmin          = e$xmin, 
    xmax          = e$xmax,
    ymin          = e$ymin, 
    ymax          = e$ymax,
    output        = normalizePath(outdir, winslash = "/")
  )
}