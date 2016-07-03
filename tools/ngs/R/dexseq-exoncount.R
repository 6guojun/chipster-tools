# TOOL dexseq-exoncount.R: "Count aligned reads per exons for DEXSeq" (Given mapped reads in a BAM file, this tool counts the reads that fall into each non-overlapping exonic part using the script dexseq-count.py. In order to use the output in DEXSeq, you need to select all samples and run the tool \"Utilities - Define NGS experiment\".)
# INPUT alignment.bam: "BAM alignment file" TYPE GENERIC
# OUTPUT exon-counts.tsv
# OUTPUT OPTIONAL exon-counts-info.txt
# PARAMETER organism: "Reference organism" TYPE [Arabidopsis_thaliana.TAIR10.30, Bos_taurus.UMD3.1.83, Canis_familiaris.BROADD2.67, Canis_familiaris.CanFam3.1.83, Drosophila_melanogaster.BDGP5.78, Drosophila_melanogaster.BDGP6.83, Felis_catus.Felis_catus_6.2.83, Gallus_gallus.Galgal4.83, Gasterosteus_aculeatus.BROADS1.83, Halorubrum_lacusprofundi_atcc_49239.GCA_000022205.1.30, Homo_sapiens.GRCh37.75, Homo_sapiens.GRCh38.83, Homo_sapiens.NCBI36.54, Medicago_truncatula.GCA_000219495.2.30, Mus_musculus.GRCm38.83, Mus_musculus.NCBIM37.67, Oryza_sativa.IRGSP-1.0.30, Ovis_aries.Oar_v3.1.83, Populus_trichocarpa.JGI2.0.30, Rattus_norvegicus.RGSC3.4.69, Rattus_norvegicus.Rnor_5.0.79, Rattus_norvegicus.Rnor_6.0.83, Schizosaccharomyces_pombe.ASM294v2.30, Solanum_tuberosum.3.0.30, Sus_scrofa.Sscrofa10.2.83, Vitis_vinifera.IGGP_12x.30, Yersinia_enterocolitica_subsp_palearctica_y11.GCA_000253175.1.30, Yersinia_pseudotuberculosis_ip_32953_gca_000834295.GCA_000834295.1.30] DEFAULT Homo_sapiens.GRCh38.83 (Which organism is your data from.)
# PARAMETER chr: "Chromosome names in the BAM file look like" TYPE [chr1, 1] DEFAULT 1 (Chromosome names must match in the BAM file and in the reference annotation. Check your BAM and choose accordingly.)
# PARAMETER paired: "Does the BAM file contain paired-end data" TYPE [yes, no] DEFAULT no (Does the alignment data contain paired end or single end reads?)
# PARAMETER stranded: "Was the data produced with a strand-specific protocol" TYPE [yes, no, reverse] DEFAULT no (Select no if your data was not produced with a strand-specific RNA-seq protocol, so that a read is considered overlapping with a feature regardless of whether it is mapped to the same or the opposite strand as the feature. If you select yes, the read has to be mapped to the same strand as the feature.)
# PARAMETER OPTIONAL mode: "Mode to handle reads overlapping more than one feature" TYPE [union, intersection-strict, intersection-nonempty] DEFAULT union (How to deal with reads that overlap more than one gene or exon?)

# 18.09.2012 TH and EK 
# 16.07.2013 EK, BAM sorting changed
# 23.04.2013 MK, added the info output file and strandedness parameter
# 01.06.2014 EK, fixed BAM sorting by name, updated to use dexseq-count.py from DEXSeq v1.8.0, added support for BAMs which don't have the chr prefix in chromosome names, moved NH tag production to a separate script
# AMS 04.07.2014 New genome/gtf/index locations & names

# if BAM contains paired-end data, sort it by read names
samtools.binary <- file.path(chipster.tools.path, "samtools", "samtools")
if(paired == "yes"){
	system(paste(samtools.binary, "sort -n alignment.bam name-sorted"))
	bam<-"name-sorted.bam"
} else {
	bam<-"alignment.bam"
}

# If chromosome names in BAM have chr, we make a temporary copy of gtf with chr names
annotation.gtf <- file.path(chipster.tools.path, "genomes", "dexseq", paste(organism, ".DEXSeq.gtf" ,sep="" ,collapse=""))

if(chr == "chr1"){
	source(file.path(chipster.common.path, "gtf-utils.R"))
	addChrToGtf(annotation.gtf, "annotation_chr.gtf") 
	gtf <- paste("annotation_chr.gtf")
}
if(chr == "1"){
	gtf <- paste(annotation.gtf)
}


# counts reads per non-overlapping exonic regions
dexseq.binary <- file.path(chipster.tools.path, "dexseq-exoncounts", "dexseq_count.py")
dexseq.command <- paste("python", dexseq.binary, "-f bam -r name -s", stranded, "-p", paired, gtf, bam, "exon-counts-out.tsv")
system(dexseq.command)

# separate result file
system("head -n -4 exon-counts-out.tsv > exon-counts.tsv")
system("tail -n 4 exon-counts-out.tsv > exon-counts-info.txt")

# bring in file to R environment for formating
file <- c("exon-counts.tsv")
dat <- read.table(file, header=F, sep="\t")
names(dat) <- c("id", "count")

# write result table to output
write.table(dat, file="exon-counts.tsv", col.names=T, quote=F, sep="\t", row.names=F)


# Handle output names
source(file.path(chipster.common.path, "tool-utils.R"))

# read input names
inputnames <- read_input_definitions()

# Make a matrix of output names
outputnames <- matrix(NA, nrow=1, ncol=2)
outputnames[1,] <- c("exon-counts.tsv", paste(strip_name(inputnames$alignment.bam), ".tsv", sep =""))

# Write output definitions file
write_output_definitions(outputnames)


# EOF
