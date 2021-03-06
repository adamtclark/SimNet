########################################################
###run simulation
########################################################
filterbyfg<-TRUE
printr2<-TRUE #calculate R2 and p-values for fits?

#load data
trdat<-read.csv("data/filtered_tradeoff_data.csv")

tmp<-trdat[,c("no3", "ptisn", "abv")]
tmp<-tmp[is.finite(rowSums(tmp)),]

tmp[,1]<-log(tmp[,1]); tmp[,2]<-logit(tmp[,2]); tmp[,3]<-log(tmp[,3])
sigma<-cov((tmp))
mu<-colMeans((tmp))

#Number of species planted in each e120 plot, and planted richness treatment
planted_treatments<-data.frame(Plot=pltloc$plot, Number.of.species=pltloc$srich, plantedsr=pltloc$plantedsr)
planted_treatments$plantedsr<-plotlst$Number.of.species[match(planted_treatments$Plot, plotlst$Plot)]

#get trait ranges for each fg
c3rng<-NULL
frng<-NULL
c4rng<-NULL
lrng<-NULL

#quantiles for bounding tradeoff surface
qlow<-0.025
qhigh<-0.975
  
c3rng[[1]]<-quantile(trdat$no3[trdat$fg=="C3"], c(qlow, qhigh), na.rm=T)
frng[[1]]<-quantile(trdat$no3[trdat$fg=="F"], c(qlow, qhigh), na.rm=T)
c4rng[[1]]<-quantile(trdat$no3[trdat$fg=="C4"], c(qlow, qhigh), na.rm=T)
lrng[[1]]<-quantile(trdat$no3[trdat$fg=="L"], c(qlow, qhigh), na.rm=T)

c3rng[[2]]<-quantile(trdat$ptisn[trdat$fg=="C3"], c(qlow, qhigh), na.rm=T)
frng[[2]]<-quantile(trdat$ptisn[trdat$fg=="F"], c(qlow, qhigh), na.rm=T)
c4rng[[2]]<-quantile(trdat$ptisn[trdat$fg=="C4"], c(qlow, qhigh), na.rm=T)
lrng[[2]]<-quantile(trdat$ptisn[trdat$fg=="L"], c(qlow, qhigh), na.rm=T)

c3rng[[3]]<-quantile(trdat$abv[trdat$fg=="C3"], c(qlow, qhigh), na.rm=T)
frng[[3]]<-quantile(trdat$abv[trdat$fg=="F"], c(qlow, qhigh), na.rm=T)
c4rng[[3]]<-quantile(trdat$abv[trdat$fg=="C4"], c(qlow, qhigh), na.rm=T)
lrng[[3]]<-quantile(trdat$abv[trdat$fg=="L"], c(qlow, qhigh), na.rm=T)

#fg for each species in E120
fglst<-c("F", "L", "C4", "F", "C3", "L", "F", "L", "C4", "L", "C3", "C4", "F", "C4")

#list of fg in E120
fglst_sim<-c(sort(fglst), "L")

#get mean sd for with-species trait variation
no3sd_mu<-mean(trdat$sd_no3, na.rm=T)
pNisd_mu<-mean(trdat$sd_ptisn, na.rm=T)
abmisd_mu<-mean(trdat$sd_abv, na.rm=T)

#make covariance matrix
require(mvtnorm)
simdatout<-NULL
maxsp<-14

for(j in 1:nrep) {
  
  #sample trait values
  estout<-NULL
  c3<-0
  c4<-0
  f<-0
  l<-0
  
  t1<-0
  t2<-0
  t3<-0
  
  #sample maxsp species that fall into the four functional groups
  while(sum(nrow(estout))<maxsp) {
    rsmp<-rmvnorm(1, mu, sigma)
    candidate<-c(exp(rsmp[1]), ilogit(rsmp[2]), exp(rsmp[3]))
    
    if(!filterbyfg) {
      estout<-rbind(estout, candidate)
    } else {
      if(c3<2) {
        if(candidate[1]>=c3rng[[1]][1] & candidate[1]<=c3rng[[1]][2] &
             candidate[2]>=c3rng[[2]][1] & candidate[2]<=c3rng[[2]][2] &
             candidate[3]>=c3rng[[3]][1] & candidate[3]<=c3rng[[3]][2]) {
          estout<-rbind(estout, candidate)
          c3<-c3+1
        }
      } else if(c4<4 & t1==1) {
        if(candidate[1]>=c4rng[[1]][1] & candidate[1]<=c4rng[[1]][2] &
             candidate[2]>=c4rng[[2]][1] & candidate[2]<=c4rng[[2]][2] &
             candidate[3]>=c4rng[[3]][1] & candidate[3]<=c4rng[[3]][2]) {
          estout<-rbind(estout, candidate)
          c4<-c4+1
        }
      } else if(f<4 & t2==1) {
        if(candidate[1]>=frng[[1]][1] & candidate[1]<=frng[[1]][2] &
             candidate[2]>=frng[[2]][1] & candidate[2]<=frng[[2]][2] &
             candidate[3]>=frng[[3]][1] & candidate[3]<=frng[[3]][2]) {
          estout<-rbind(estout, candidate)
          f<-f+1
        }
      } else if(l<4 & t3==1) {
        if(candidate[1]>=lrng[[1]][1] & candidate[1]<=lrng[[1]][2] &
             candidate[2]>=lrng[[2]][1] & candidate[2]<=lrng[[2]][2] &
             candidate[3]>=lrng[[3]][1] & candidate[3]<=lrng[[3]][2]) {
          estout<-rbind(estout, candidate)
          l<-l+1
        }
      }
      
      if(c3==2) {
        t1<-1
      }
      if(c4==4) {
        t2<-1
      }
      if(f==4) {
        t3<-1
      }
    }
  }
  
  colnames(estout)<-c("no3", "ptisn", "abv")
  for(i in c(1,2,4,8,16)) {
    #draw species corresponding to each planted richness
    tmp<-planted_treatments$Number.of.species[(planted_treatments$plantedsr==i) & planted_treatments$Number.of.species>0]
    
    #sample relative to observed richness in E120 plots
    nsp<-sample(tmp[tmp!=0], 1)
    
    if(i==1) {
      #sample an extra legume with pr = probability of Amoca
      ps<-sample(1:maxsp, nsp, replace=F, prob = c(rep(1, 13), 32/(32+13)))
    } else if(i==16) {
      #sample from all species
      ps<-sample(1:maxsp, nsp, replace=F)
    } else {
      #sample all but final legume (since Amoca was not included in these mixtures)
      ps<-sample(1:(maxsp-1), nsp, replace=F)
    }
    
    #get traits
    no3lst<-estout[ps,"no3"]
    pNi<-estout[ps,"ptisn"]
    abmi<-estout[ps,"abv"]
    
    no3lst_dat<-cbind(no3lst, no3sd_mu)
    pNi_dat<-cbind(pNi, pNisd_mu)
    abmi_dat<-cbind(abmi, abmisd_mu)
    niter<-13 #number of sample years in e120, 2001-2014
    
    if(niter==1 | nrep==1) {
      iterout<-repsmp_single()
    } else {
      iterout<-repsmp()
    }
    esti<-iterout[1:nsp]
    
    esti[!is.finite(esti)]<-0
    
    abvest<-esti
    
    plottot<-sum(abvest)
    
    #save outputs
    simdatout<-rbind(simdatout, data.frame(iter=j, nsp=i, onsp=nsp,
                                           abmi=abmi, pNi=pNi, no3lst=no3lst, abvest=abvest,
                                           plottot=plottot, fg=fglst_sim[ps]))
  }
  if(j/10 == floor(j/10)) {
    print(j/nrep)
  }
}

#load tradeoff data for plotting
datoutfull<-datoutlst[[2]]
datout<-datoutfull

########################################################
###calculate total plot biomass
########################################################
#get average total biomass
simdatout_sum<-with(simdatout, aggregate(cbind(plottot=abvest), list(nsp=nsp, iter=iter), function(x) sum(x)))

#get mean across iterations by planted richness
smdat<-with(simdatout_sum, aggregate(cbind(plottot=plottot), list(nsp=nsp), hurdlemodel))
#std error
smdatsd<-with(simdatout_sum, aggregate(cbind(plottot=plottot), list(nsp=nsp), function(x) sd(log10(x), na.rm=T)))
#mean
smdatmn<-10^mean(log10(unique(simdatout[,c("abmi")])))
smdatmnsd<-sd(log10(unique(simdatout[,c("abmi")])))
#get for observed data
datout$plantedsr<-planted_treatments$plantedsr[match(datout$plt, planted_treatments$Plot)]

obsplt<-with(datout, aggregate(cbind(obs=obs), list(sr=sr, plt=plt, plantedsr=plantedsr), function(x) sum(x, na.rm=T)))
obsdat<-with(obsplt, aggregate(cbind(obs=obs), list(sr=plantedsr), hurdlemodel))
obsdatsd<-with(obsplt, aggregate(cbind(obs=obs), list(sr=plantedsr), function(x) sd(log10(x),na.rm=T)))
obsdatsd_n<-with(obsplt, aggregate(cbind(obs=obs), list(sr=plantedsr), function(x) length(x)))

####################################
#plot total biomass
####################################
adjlst<-c(-0.2, 0.2)
snums<-c(1, 2, 4, 8, 16)

m<-cbind(c(1,1), c(1,1), c(2,4), c(3,5))
layout(m)
par(mar=c(2, 2, 2, 2), oma=c(3,3,0,0))
p2<-10^(log10(snums)-0.02)
p1<-10^(log10(snums)+0.02)

plot(snums, smdat$plottot, col="blue", lwd=2, ylim=c(50, 225),
     xlab="Planted Richness", ylab=expression(paste("Aboveground Biomass, g m"^-2)), axes=F, type="n",
     cex.lab=1.2, log="xy")
abline(h=seq(0, 250, by=25), v=snums, col="lightgrey")
axis(2, at=c(50, 75, 100, 150, 200), cex.axis=1.5); axis(1, at=snums, c(1, 2, 4, 8, 16), cex.axis=1.5); box()

lines(p1, obsdat$obs, col=adjustcolor("black", alpha.f = 0.7), lwd=3)
#lines(p1, obsdat$obs, col=adjustcolor("black", alpha.f = 0.7), lwd=2)
put.fig.letter(label = "A.", location = "topleft", cex=2, x=0.04, y=0.97)


hi<-10^(log10(obsdat$obs)+obsdatsd$obs/sqrt(obsdatsd_n$obs))
lw<-10^(log10(obsdat$obs)-obsdatsd$obs/sqrt(obsdatsd_n$obs))
#segments(p1, hi, p1, lw, lwd=4, lend=2)
segments(p1, hi, p1, lw, col=adjustcolor("black", alpha.f = 0.7), lend=2, lwd=3)
#lines(p1, obsdat$obs, col=adjustcolor("black", alpha.f = 0.7), lwd=2)

lines(p2, (smdat$plottot), col=adjustcolor("blue", alpha.f = 0.7), lwd=3)

hi<-10^(log10(smdat$plottot)+smdatsd$plottot/sqrt(obsdatsd_n$obs))
lw<-10^(log10(smdat$plottot)-smdatsd$plottot/sqrt(obsdatsd_n$obs))
segments(p2, hi, p2, lw, lwd=3, lend=2, col=adjustcolor("blue", alpha.f = 0.7))

#Calculate and plot R-squared/p-values
if(printr2) {
  bootrsquarelst<-numeric(nrep)
  bootslplst<-numeric(nrep)
  for(i in 1:nrep) {
    bootdat<-NA
    while(length(bootdat)!=5) {
      smp1<-sample(1:nrow(obsplt), rep=T)
      bootdat<-tapply(obsplt$obs[smp1], obsplt$plantedsr[smp1], hurdlemodel)
    }
    
    bootsimulated<-NA
    while(length(bootsimulated)!=5) {
      smp2<-sample(1:nrow(simdatout_sum), nrow(obsplt), rep=T)
      bootsimulated<-tapply(simdatout_sum$plottot[smp2], simdatout_sum$nsp[smp2], hurdlemodel)
    }
   
    sb<-is.finite(log10(bootdat))&is.finite(log10(bootsimulated))
    lmd<-suppressWarnings(suppressMessages(lmodel2(log10(bootdat)[sb]~log10(bootsimulated)[sb], range.y="interval", range.x="interval")))
    ssobs<-sum((log10(bootdat)[sb]-log10(bootsimulated)[sb])^2, na.rm=T)
    sstot<-sum((mean(log10(bootsimulated)[sb], na.rm=T)-log10(bootsimulated)[sb])^2, na.rm=T)
    
    bootrsquarelst[i]<-1-ssobs/sstot
    bootslplst[i]<-lmd$regression.results[4,3]
  }
  
  rsqest<-quantile(bootrsquarelst, 0.5, na.rm=T)
  pvest<-sum(bootslplst<0)/length(bootslplst)
  if(pvest==0) {
    pvest<-1/nrep
  }
  
  r<-"R"
  p<-"p"
  rd<-paste(" =", round(rsqest, 2))
  pv<-paste(" <", ceiling(pvest*1000)/1000)
  
  text(2, 200, bquote(.(r[1])^2 ~ .(rd[1])), cex=1.2)
  text(2, 180, bquote(.(p[1]) ~ .(pv[1])), cex=1.2)
}

####################################
#plot abundance distributions
####################################
abundfun<-function(x) {
  rev(sort(x))
}


spxlst<-c(1,2,4,8,16)
spxseq<-seq(1:maxsp)
n<-1
for(i in c(2,4,8,16)) {
  plot(c(min(spxlst), max(spxlst)), c(0.1, 110), col="blue", lwd=2,
       xlab="", ylab="", axes=F, type="n", log="xy",
       cex.lab=1.2)
  mtext(paste("Planted Richness =", i), side = 3, cex=0.8, line = -0.1)
  
  abline(h=c(0.1, 1, 10, 100), v=spxlst, col="lightgrey")
  axis(2, at=c(0.1, 1, 10, 100), cex.axis=1); axis(1, at=spxlst, spxlst, cex.axis=1); box()
  put.fig.letter(label = c("B.", "C.", "D.", "E.")[n],
                 location = "topleft", cex=2, x=0.06, y=0.95, xpd=T)
  
  subs<-which(simdatout$nsp==i)
  
  abundmat<-matrix(nrow=length(sort(unique(simdatout$iter))), ncol=maxsp)
  for(j in 1:nrow(abundmat)) {
    subs2<-which(simdatout$iter[subs]==j)
    abundmat[j,1:length(subs2)]<-abundfun(simdatout$abvest[subs][subs2])
  }
  abundmat[is.na(abundmat)]<-0
  abundqt<-apply(abundmat, 2, function(x) quantile(x, c(0.025, pnorm(-1,0,1), 0.5, pnorm(1,0,1), 0.975), na.rm=T))
  
  pltlst<-sort(unique(datout$plt[datout$plantedsr==i]))
  abundmatobs<-matrix(nrow=length(pltlst), ncol=maxsp)
  for(j in 1:nrow(abundmatobs)) {
    subs3<-which(datout$plt==pltlst[j])
    tmp<-abundfun(datout$obs[subs3])
    abundmatobs[j,1:length(tmp)]<-tmp
  }
  abundmatobs[is.na(abundmatobs)]<-0
  abund_obs<-apply(abundmatobs, 2, function(x) quantile(x, c(0.025, pnorm(-1,0,1), 0.5, pnorm(1,0,1), 0.975), na.rm=T))
  
  #simulated
  hi<-abundqt[3,]+(abundqt[4,]-abundqt[3,])/sqrt(obsdatsd_n$obs[obsdatsd_n$sr==i])
  lw<-abundqt[3,]-(abundqt[3,]-abundqt[2,])/sqrt(obsdatsd_n$obs[obsdatsd_n$sr==i])
  hi[hi==0 & (1:length(hi))>i]<-NA
  lw[lw==0 & (1:length(lw))>i]<-NA
  
  sbS<-is.finite(log(hi))&is.finite(log(lw))
  polygon(c(spxseq[sbS], rev(spxseq[sbS])), c(hi[sbS], rev(lw[sbS])), col=adjustcolor("blue", alpha.f = 0.7), border=1)
  
  #observed
  hi<-abund_obs[3,]+(abund_obs[4,]-abund_obs[3,])/sqrt(obsdatsd_n$obs[obsdatsd_n$sr==i])
  lw<-abund_obs[3,]-(abund_obs[3,]-abund_obs[2,])/sqrt(obsdatsd_n$obs[obsdatsd_n$sr==i])
  hi[hi==0 & (1:length(hi))>i]<-NA
  lw[lw==0 & (1:length(lw))>i]<-NA
  
  sbO<-is.finite(log(hi))&is.finite(log(lw))
  polygon(c(spxseq[sbO], rev(spxseq[sbO])), c(hi[sbO], rev(lw[sbO])), col=adjustcolor("black", alpha.f = 0.7), border="black")
  
  #Calculate and plot R-squared/p-values
  if(printr2) {
    bootrsquarelst<-numeric(nrep)
    bootslplst<-numeric(nrep)
    for(i in 1:nrep) {
      bootdat<-apply(abundmatobs[sample(1:nrow(abundmatobs), rep=T),], 2, hurdlemodel)
      bootdat[!is.finite(bootdat)]<-NA
      
      bootsimulated<-apply(abundmat[sample(1:nrow(abundmat), nrow(abundmatobs), rep=T),], 2, hurdlemodel)
      bootsimulated[!is.finite(bootsimulated)]<-NA
      
      sb<-is.finite(log10(bootdat))&is.finite(log10(bootsimulated))
      lmd<-suppressWarnings(suppressMessages(lmodel2(log10(bootdat)[sb]~log10(bootsimulated)[sb], range.y="interval", range.x="interval")))
      ssobs<-sum((log10(bootdat)[sb]-log10(bootsimulated)[sb])^2, na.rm=T)
      sstot<-sum((mean(log10(bootsimulated)[sb], na.rm=T)-log10(bootsimulated)[sb])^2, na.rm=T)
      
      bootrsquarelst[i]<-1-ssobs/sstot
      bootslplst[i]<-lmd$regression.results[4,3]
    }
    
    rsqest<-quantile(bootrsquarelst, 0.5, na.rm=T)
    pvest<-sum(bootslplst<0)/length(bootslplst)
    if(pvest==0) {
      pvest<-1/nrep
    }
    
    r<-"R"
    p<-"p"
    rd<-paste(" =", round(rsqest, 2))
    pv<-paste(" <", ceiling(pvest*1000)/1000)
    
    text(3.8, 75, bquote(.(r[1])^2 ~ .(rd[1])), cex=1.2, pos=4)
    text(3.8, 30, bquote(.(p[1]) ~ .(pv[1])), cex=1.2, pos=4)
  }
  
  n<-n+1
}

par(new=T)
par(mfrow=c(1,1))
mtext(expression(paste("Aboveground Biomass, g m"^-2)), 2, line=3.5)

par(new=T)
par(mfrow=c(1,2))
plot(0, 0, xlab="", ylab="", axes=F, type="n")
mtext("Abundance Rank", 1, line=3.5)

par(new=T)
par(mfrow=c(1,2), mfg=c(1,1))
plot(0, 0, xlab="", ylab="", axes=F, type="n")
mtext("Planted Richness", 1, line=3.5)
