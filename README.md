# R-code-for-SFD-training

This is a series of R code used for downloading formatting and processing the CHELSA and NASA climate layers. The series A is for the CHELSA layers and B for the NASA layers.


## B. NASA 
### B.i. Download NASA layers.
This code downloads the [NASA Earth Exchange Global Daily Downscaled Projections NEX-GDDP-CMIP6](https://registry.opendata.aws/nex-gddp-cmip6/). It requires that the [AWS Command Line Interface](https://awscli.amazonaws.com/AWSCLIV2.msi) is installed.
### B.ii. Clip and convert NASA layers
### B.v. Maximum and mean Rx1day for 30-year climatologies
This code utilizes the clipped and converted PR layer to generate the yearly maximum 1-day rainfall total. The results are then summarised as a mean and maximum value for the 30-year climatology.
