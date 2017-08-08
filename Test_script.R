## Example run of occupancy models across a group of species

# This is how I would run things on a cluster that I was the only person on
# when I run things on lotus I use the queue management system to run each species
# as a seperate job

# Tom August

# Clear the workspace
rm(list = ls())

# Install the packages required
# install.packages("devtools")
require(devtools)
# NOTE: JAGs needs to be installed on the system
require(R2jags)
require(reshape2)
require(snowfall)
require(parallel)
#require(Rmpi) #on cluster only

# This is the package written by CEH
# install_github("BiologicalRecordsCentre/sparta")
require(sparta)

# Load in the data
load('Test_Data.rdata') #taxa_data

head(taxa_data)

# This changes the format of the data to the format
# needed for hte modelling
# This takes a few seconds to run
visitData <- formatOccData(taxa = taxa_data$CONCEPT,
                           site = taxa_data$TO_GRIDREF,
                           time_period = taxa_data$TO_STARTDATE)

# initiate a cluster
my_cores <- detectCores()
# I use SOCK on my PC but MPI on a cluster
sfInit(parallel = TRUE,
       type = "SOCK",
       cpus = my_cores - 1,
       useRscript = TRUE)

# export my data to the cluster
# I'm lazy so export everything in this session
sfExportAll()
# export libraries
sfLibrary(sparta)

# Set up my parallel task as a function
para_func <- function(i){
  
  # make this number bigger to run longer. we usually use 20000
  # At 10 it takes ~15-30min per species
  iterations <- 10
  
  # Run the model (this will take a while to run)
  out <- occDetFunc(taxa_name = i,
                    occDetdata = visitData$occDetdata,
                    spp_vis = visitData$spp_vis,
                    write_results = FALSE,
                    n_chains = 1, 
                    n_iterations = iterations, 
                    burnin = iterations/2, 
                    thinning = 3,
                    nyr = 2)  
  
  # save the output
  save(out, file = file.path('output',paste0(i,'.rdata')))

  return(Sys.time())
}

# Run the cluster task
returned <- sfClusterApplyLB(tail(colnames(visitData$spp_vis), -1), fun = para_func)
# stop the cluster
sfStop()

# this should print a lot of timings
returned
