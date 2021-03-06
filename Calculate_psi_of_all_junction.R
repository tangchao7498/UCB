
## calculate PSI of AS3
require(parallel)
library(dplyr)
library(plyr)
library(pryr)
require(parallel)
library(ggplot2)
library(cowplot)
library(GenomicRanges)
library(reshape2)
library(vioplot)

depar <- par()

## path and name of SJ merged RData
pfsj <- file.path("/mnt/data5/BGI/UCB/tangchao/data/SJ/SJ(all_more_than_10)_merged_touse.RData")

## path of figure/file output
pffo <- file.path("/mnt/data5/BGI/UCB/tangchao/DSU/")

## path of RData output
pfro <- file.path("/mnt/data5/BGI/UCB/tangchao/DSU/RData/")

## path of gtf
pfgtf <- file.path("/mnt/data1/reference/ensembl/human/Homo_sapiens.GRCh38.87.gtf")


#### 1.load data --------------------------------------------------------------------------------------------------------------------------------

load(pfsj)

SJ_tu -> count_use

require(data.table)  # v1.6.6
require(gdata) 
f_dowle3 = function(DT) {
  # either of the following for loops
  
  # by name :
  for (j in names(DT))
    set(DT,which(is.na(DT[[j]])),j,0)
  
  # or by number (slightly faster than by name) :
  for (j in seq_len(ncol(DT)))
    set(DT,which(is.na(DT[[j]])),j,0)
}

f_dowle3(count_use)




#### 2. Identify alternative splicing events ----------------------------------------------------------------------------------------------------


junc=count_use
#junc.names=do.call(rbind,(strsplit(sub(x=rownames(junc),
#                                       pattern="^([[:alnum:]]+):([[:digit:]]+)-([[:digit:]]+)$",
#                                       replace="\\1;\\2;\\3"),split=";")))
junc.names=do.call(rbind,strsplit(rownames(junc),split="[:-]"))
#alnum-- Letters and Numbers；digit -- Numbers
colnames(junc.names) <- c("chr","start","end")
rownames(junc.names) <- rownames(junc)
junc.names=data.frame(junc.names,stringsAsFactors=F)
junc.names$start=as.integer(junc.names$start)
junc.names$end=as.integer(junc.names$end)

junc.names=junc.names[order(junc.names$chr,junc.names$start,junc.names$end),]
junc.names$names=rownames(junc.names)


junc.as_same_start=do.call(c,mclapply(unique(junc.names$chr),function(chr) {
  junc.chr=junc.names[junc.names$chr==chr,]
  same.start=dlply(junc.chr,c("start"),function(x) x)
  #same.end=dlply(junc.chr,c("end"),function(x) {if(nrow(x)>1) {return(x)} else {return(NULL)}})
  print(chr)
  return(same.start)
},mc.cores=10))


junc.as_same_end=do.call(c,mclapply(unique(junc.names$chr),function(chr) {
  junc.chr=junc.names[junc.names$chr==chr,]
  #same.start=dlply(junc.chr,c("start"),function(x) x)
  same.end=dlply(junc.chr,c("end"),function(x) {if(nrow(x)>1) {return(x)} else {return(NULL)}})
  print(chr)
  return(same.end)
},mc.cores=10))


psi_sj_same_start=mclapply(junc.as_same_start,function(sjs){
  sjs.names=sjs$names[order(as.numeric(sjs$end)-as.numeric(sjs$start))]# find the splicing_in isoform to calculate the psi
  tab=as.matrix(t(junc[sjs.names,]))
  rs<-apply(tab, 1, function(a) sum(a))
  tsrs<-tab/rs
  return(t(tsrs))
},mc.cores = 6)


psi_sj_same_end=mclapply(junc.as_same_end,function(sjs){
  sjs.names=sjs$names[order(as.numeric(sjs$end)-as.numeric(sjs$start))]# find the splicing_in isoform to calculate the psi
  tab=as.matrix(t(junc[sjs.names,]))
  rs<-apply(tab, 1, function(a) sum(a))
  tsrs<-tab/rs
  return(t(tsrs))
},mc.cores = 6)

save(psi_sj_same_start,psi_sj_same_end, file = "/mnt/data5/BGI/UCB/tangchao/DSU/RData/psi_list_left_right.RData")

do.call(rbind,psi_sj_same_start) -> psi_sj_same_start_table
do.call(rbind,psi_sj_same_end) -> psi_sj_same_end_table

length(psi_sj_same_start)
# [1] 368535
length(psi_sj_same_end)
# [1] 368750
dim(psi_sj_same_start_table)
# [1] 460327   3574
dim(psi_sj_same_end_table)
# [1] 146930   3574

save(psi_sj_same_start_table,psi_sj_same_end_table, file = "/mnt/data5/BGI/UCB/tangchao/DSU/RData/psi_list_left_right_table.RData")




#### intron-centric PSI calculation ==============================================================================================================
#### alternative splicing distance is 1 0r 2 bp ==============================

require(parallel)
library(dplyr)
library(plyr)
library(pryr)
require(parallel)
library(ggplot2)
library(cowplot)
library(GenomicRanges)
library(reshape2)
library(vioplot)


pfsj <- file.path("/mnt/data5/BGI/UCB/tangchao/data/SJ/SJ_merged_raw_te(no_NA).RData")
load(pfsj)


require(data.table)  # v1.6.6
require(gdata) 
f_dowle3 = function(DT) {
  # either of the following for loops
  
  # by name :
  for (j in names(DT))
    set(DT,which(DT[[j]] ==1),j,0)
  
  # or by number (slightly faster than by name) :
  for (j in seq_len(ncol(DT)))
    set(DT,which(DT[[j]] == 1),j,0)
}

f_dowle3(te_table)



#### 2. Identify alternative splicing events ----------------------------------------------------------------------------------------------------


#junc.names=do.call(rbind,(strsplit(sub(x=rownames(junc),
#                                       pattern="^([[:alnum:]]+):([[:digit:]]+)-([[:digit:]]+)$",
#                                       replace="\\1;\\2;\\3"),split=";")))
junc.names=do.call(rbind,strsplit(rownames(te_table),split="[:-]"))
#alnum-- Letters and Numbers；digit -- Numbers
colnames(junc.names) <- c("chr","start","end")
rownames(junc.names) <- rownames(te_table)
junc.names=data.frame(junc.names,stringsAsFactors=F)
junc.names$start=as.integer(junc.names$start)
junc.names$end=as.integer(junc.names$end)
junc.names <- junc.names[junc.names$chr %in% c(1:22,"X","Y"),]
junc.names=junc.names[order(junc.names$chr,junc.names$start,junc.names$end),]
junc.names$names=rownames(junc.names)


junc.as_same_start=do.call(c,mclapply(unique(junc.names$chr),function(chr) {
  junc.chr=junc.names[junc.names$chr==chr,]
  same.start=dlply(junc.chr,c("start"),function(x) x)
  #same.end=dlply(junc.chr,c("end"),function(x) {if(nrow(x)>1) {return(x)} else {return(NULL)}})
  print(chr)
  return(same.start)
},mc.cores=4))


junc.as_same_end=do.call(c,mclapply(unique(junc.names$chr),function(chr) {
  junc.chr=junc.names[junc.names$chr==chr,]
  #same.start=dlply(junc.chr,c("start"),function(x) x)
  same.end=dlply(junc.chr,c("end"),function(x) {if(nrow(x)>1) {return(x)} else {return(NULL)}})
  print(chr)
  return(same.end)
},mc.cores=10))


psi_sj_same_start=mclapply(junc.as_same_start,function(sjs){
  sjs.names=sjs$names[order(as.numeric(sjs$end)-as.numeric(sjs$start))]# find the splicing_in isoform to calculate the psi
  if(nrow(sjs) == 1){
    tsrs <- te_table[sjs.names,]
    tsrs[tsrs>0] <- 1
  }else{
    tab=as.matrix(t(te_table[sjs.names,]))
    rs<-apply(tab, 1, function(a) sum(a))
    tsrs<-t(tab/rs)
  } 
  return(tsrs)
},mc.cores = 10)

save(psi_sj_same_start, file = "/mnt/data5/BGI/UCB/tangchao/DSU/RData/psi_list_same_start_cutoff2.RData")


psi_sj_same_end=mclapply(junc.as_same_end,function(sjs){
  sjs.names=sjs$names[order(as.numeric(sjs$end)-as.numeric(sjs$start))]# find the splicing_in isoform to calculate the psi
  tab=as.matrix(t(te_table[sjs.names,]))
  rs<-apply(tab, 1, function(a) sum(a))
  tsrs<-tab/rs
  return(t(tsrs))
},mc.cores = 10)

save(psi_sj_same_end, file = "/mnt/data5/BGI/UCB/tangchao/DSU/RData/psi_list_same_end_cutoff2.RData")

do.call(rbind,psi_sj_same_start) -> psi_sj_same_start_table
do.call(rbind,psi_sj_same_end) -> psi_sj_same_end_table

length(psi_sj_same_start)
# [1] 368535
length(psi_sj_same_end)
# [1] 368750
dim(psi_sj_same_start_table)
# [1] 460327   3574
dim(psi_sj_same_end_table)
# [1] 146930   3574












read.table("/mnt/data5/BGI/UCB/ExpMat_NewID/Cell_type.txt", sep = "\t", header = F, row.names = 1) -> celltype
colnames(celltype) <- "Cell type"



#1:198692374-198696711-198696910-198699563

sum(SJ_tu[,row.names(celltype)]["1:198692374-198696711",]>0 & SJ_tu[,row.names(celltype)]["1:198692374-198699563",]>0 & SJ_tu[,row.names(celltype)]["1:198696910-198699563",]>0 )
sum(te_table[,row.names(celltype)]["1:198692374-198696711",]>0 & te_table[,row.names(celltype)]["1:198692374-198699563",]>0 & te_table[,row.names(celltype)]["1:198696910-198699563",]>0 )

sum(SJ_tu[,row.names(celltype)]["1:198692374-198696711",]>0)







