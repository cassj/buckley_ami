#!/usr/local/bin/Rscript

options(stringsAsFactors = FALSE);
library(IRanges)

library(biomaRt)
ensmart <- useMart("ensembl", dataset="mmusculus_gene_ensembl")

tss <- getAnnotation(ensmart, "TSS")
save(tss, file=paste(dirname(filename),"/tss.RData",sep=""))

mirnas <- getAnnotation(ensmart, "miRNA")
save(mirnas, file=paste(dirname(filename),"/mirna.RData",sep=""))

exons <- getAnnotation(ensmart, "Exon")
save(exons, file=paste(dirname(filename),"/exons.RData", sep="" ))





























