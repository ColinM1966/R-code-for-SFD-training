# R-code-for-SFD-training

This is a series of R code used for downloading formatting and processing the CHELSA and NASA climate layers. The series A is for the CHELSA layers and B for the NASA layers.

# A. CHELSA
## Working with CHELSA Data
### A.i. Download CHELSA Data
Version 2.1 of the CHELSA data has a limited range of ESMs and SSPs available, to expand the range of ESMs or SSPs the data needs to be downloaded from CMIP6 using the code developed by [Karger 2021](https://gitlabext.wsl.ch/karger/chelsa_cmip6) A modified version of Karger's R code  is reproduced here. The  [Earth System Grid Federation's Metagrid web application](https://aims2.llnl.gov/search) is used in conjunction with this code to obtain information on what ESMs, SSPs, etc, are available.

### A.2.

# B. NASA 
## Working with NASA Data
### B.i. Download NASA layers.
This code downloads the [NASA Earth Exchange Global Daily Downscaled Projections NEX-GDDP-CMIP6](https://registry.opendata.aws/nex-gddp-cmip6/). It requires that the [AWS Command Line Interface](https://awscli.amazonaws.com/AWSCLIV2.msi) is installed.
### B.ii. Clip and convert NASA layers
This code clips the global layers to the area of interest using a reference raster file. It converts precipitation from kg/m/s to mm/day and temperature (tas, tasmax and tasmin) from degrees Kelvin to degrees Celcius. 

## Climate Extreme Indices (CEIs)
The CEIs are based on [Appendix 6](https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WGI_AnnexVI.pdf) of [Climate Change 2021: The Physical Science Basis](https://www.ipcc.ch/report/ar6/wg1/).

### B.iii. Maximum number of consecutive days with more (CWD) or less (CDD) than 1 mm of precipitation per day
This code uses the RLE (Run Length Encoding) function to determine the number of consecutive days above and below 1 mm of precipitation. 

### B.iv. Count of days when rainfall exceeds the CEI thresholds
This code calculates the number of days when the rainfall exceeds 1, 5, 10, 20, & 50 mm.

### B.v. Maximum and mean Rx1day for 30-year climatologies
This code utilizes the clipped and converted PR layer to generate the yearly maximum 1-day rainfall total. The results are then summarised as a mean and maximum value for the 30-year climatology.
