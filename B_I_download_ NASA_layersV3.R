###############################################################################
###############################################################################    
#  BI. Downloading the NASA Earth Exchange Global Daily Downscaled Projections 
# (NEX-GDDP-CMIP6) from AWS (https://nex-gddp-cmip6.s3.us-west-2.amazonaws.com/index.html)
#
###############################################################################
# The code requires that you have installed the AWS Command Line Interface from https://aws.amazon.com/cli/
# After installing AWI CLI you can check the path by entering "where aws"in the command prompt, then set the 
# path in line 37 of the code below.
# The NEX-GDDP-CMIP6 subfolder directory naming is Model/Simulation/Variant/variable.
# This code downloads files by the file version in the selected variable (latest is v2.0). 
# There are 9 variable from 35 ESMs available for five simulation - historical covering 1950 to 2014 and four emission scenarios# (SSP126. SSP245, SSP370 & SSP585) covering 2015-2100. 
# Details on the model names, simulations, variants and variable can be found in Table 2 of Thrasher et al (2022) 
# https://www.nature.com/articles/s41597-022-01393-4/tables/3  
###############################################################################
#1. Installing packages    
install.packages("aws.s3")   # package to download layers from AWS, should only need to be run the first time you run the code

#2. Load packages
library(aws.s3)

# ==== USER INPUTS ====
# information for the ESM, simulation, variable and version you are after
esm      <- "EC-Earth3"       # Change to the ESM you are after
ssp      <- "historical"      # options are: historical, ssp126, ssp245, ssp370 or ssp585
variable <- "pr"              # pr, tasmax, tasmin, etc.
variant  <- "r1i1p1f1"        # follows the ESM selected - check Table 2 in the link above
grid     <- "gr"              # follows the ESM selected - check Table 2 in the link above
version  <- "v2.0"            # e.g., v2.0, v1.0 - v2.0 is the lastest, unlike you would use an earlier version

# ==== YEAR RANGE ====
# years you want to download, change to the years of interest
years <- if (ssp == "historical") 1981:2014 else 2015:2100

# ==== SETUP ====
# pathway to where you want to store the files change to relevant drive and directory
s3_base <- "s3://nex-gddp-cmip6/NEX-GDDP-CMIP6"
local_dir <- file.path("I:/Trial", esm, ssp, variable)
dir.create(local_dir, recursive = TRUE, showWarnings = FALSE)

# pathway to aws.exe - set this to where your version is stored
aws_cli <- "\"C:/Program Files/Amazon/AWSCLIV2/aws.exe\""

# ==== LOOP THROUGH YEARS ====
for (year in years) {
  file_name <- sprintf(
    "%s_day_%s_%s_%s_%s_%d_%s.nc",
    variable, esm, ssp, variant, grid, year, version
  )
  
  s3_path <- file.path(s3_base, esm, ssp, variant, variable, file_name)
  local_file <- file.path(local_dir, file_name)
  
  cmd <- sprintf('%s s3 cp --no-sign-request "%s" "%s"', aws_cli, s3_path, local_file)
  cat("Downloading:", file_name, "\n")
  system(cmd)
}


