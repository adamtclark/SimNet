#!/usr/bin/env Rscript
setwd("~/Dropbox/GitProjects/SimNet/src/cdr_tradeoff/")
rm(list=ls())

############################################################
# set up for simulations
############################################################

#load packages
require(parallel) #parallelize calculations
require(lmodel2) #fit bivariate major axis regressions
require(mvtnorm) #calculate multivariate normal distribution
require(plot3D) #make tradeoff plots
require(lme4) #fit trait values from data
require(data.table) #for reforming data
require(RColorBrewer) #for mixing palettes

#Load C functions
if(!sum(grep("getbmest.so", dir()))>0) {
  system("R CMD SHLIB getbmest.c")
}

#load site and model data
load("data/simulated_results_coex.RData")

#set up simulations
centermeans<-TRUE #center to true E120 monoculture means?
nrep<-1000 #number of iterations for nonparametric analyses
adjustS<-TRUE #use 1994 total soil C to adjust among-plot variability?
nrep_traits<-1000 #number of iterations for testing within-species trait variation. If 1, then mean values are used
usetr<-TRUE #snap species to tradeoff surface

#run simulation
pdf("figures/cdr_tradeoff_community.pdf", width=8, height=4, colormodel = "cmyk", useDingbats = FALSE)
  source("simulate_communities.R")
dev.off()