#######################################################################################
#
# This is a modification of Kargan (2021). The first section should only need 
# to be installed once, it installs resiculate and then uses the reticulate 
# package to install python and the chelsa-cmip6 that is used to download the
# CMIP6 projections.
#
#######################################################################################
# A. Installing reticulate, python and chelsa-cmip6 (should only need to run this once)
# 1. Install and load reticulate (if not already installed)
install.packages("reticulate", dependencies = TRUE)
library(reticulate)

# 2. Install a standalone Python (this avoids the broken Microsoft Store version)
#    This will download and install Python 3.12 under your user directory
reticulate::install_python(version = "3.12")

# 3. Define the path to the newly installed Python
python_path <- "C:/Users/User/AppData/Local/r-reticulate/r-reticulate/pyenv/pyenv-win/versions/3.12.10/python.exe"

# 4. Create a clean virtual environment using that Python
reticulate::virtualenv_create("chelsa_env", python = python_path)

# 5. Tell reticulate to use this environment in this R session
reticulate::use_virtualenv("chelsa_env", required = TRUE)

# 6. Install the chelsa-cmip6 Python package inside the environment
reticulate::py_install("chelsa-cmip6", envname = "chelsa_env", method = "virtualenv")

# 7. Check Python setup (should show Python 3.12 in chelsa_env)
reticulate::py_config()

# 8. Import the chelsa_cmip6 module and make it available in R
chelsa_cmip6 <- reticulate::import("chelsa_cmip6")

# 9. Test: print available functions - not required
print(chelsa_cmip6)
######################################################################################
# B. Downloading data from CMIP6
# 1. Load package and 
library(reticulate)
library(terra)
use_virtualenv("chelsa_env", required = TRUE)
chelsa_cmip6 <- import("chelsa_cmip6")


# 2. Load reference raster and extracts extent
ref_raster <- rast("C:/Users/User/Documents/Borneo_pr_day_GFDL-ESM4_ssp126_r1i1p1f1_gr1_2015.tif")

# extract extent
e <- ext(ref_raster)

#3.  define model, scenario and climatology
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

#5.  run CHELSA call
chelsa_cmip6$GetClim$chelsa_cmip6(
  activity_id   = 'ScenarioMIP', 
  table_id      = 'Amon', 
  experiment_id = experiment_id, 
  institution_id= institution_id, 
  source_id     = source_id, 
  member_id     = member_id, 
  refps         = Base_start, 
  refpe         = Base_finish, 
  fefps         = Climato_start, 
  fefpe         = Climato_finish, 
  xmin          = e$xmin, 
  xmax          = e$xmax,
  ymin          = e$ymin, 
  ymax          = e$ymax,
  output        = normalizePath(outdir, winslash = "/")
)