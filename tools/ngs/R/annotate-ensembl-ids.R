# TOOL annotate-ensembl-ids.R: "Annotate Ensembl identifiers" (Annotates Ensembl IDs with gene symbols and descriptions, creates a new table containing these and the values in the original input file. The Ensembl IDs need to be either the rownames or in the first column of the input table.)
# INPUT genelist.tsv: genelist.tsv TYPE GENERIC
# OUTPUT annotated.tsv: annotated.tsv 
# PARAMETER species: Species TYPE [human: human, mouse: mouse, rat: rat] DEFAULT human (The species needs to be specified in order to annotate the Ensembl IDs.)
# RUNTIME R-3.4.3


# ML, 05.02.2015
# ML, 12.11.2015, fixed
# ML, 14.08.2018, fixed + updated to new version
# JH (ML), 11.07.2019, fix entrezgene -> entrezgene_id

# ATM only for human, mouse, rat. 
# The ensembl IDs need to be either the row names or in the first column.

# Load libraries into memory
library(biomaRt)

# Load the data
file <- c("genelist.tsv")
#dat <- read.table(file, header=T, sep="\t", row.names=1)
dat <- read.table(file, header=T, sep="\t")

# Choose the ensembl IDs
if(!is.na(pmatch("ENS", dat[2,1]))) {
	genes <- dat[,1]
}
if(!is.na(pmatch("ENS",  rownames(dat)[2] ))) {
	genes <- rownames(dat)
}

if(is.na(pmatch("ENS", dat[2,1])) &&  is.na(pmatch("ENS",  rownames(dat)[2] ))) {
	stop("CHIPSTER-NOTE: You can only annotate Ensembl IDs with this tool. The IDs need to be either rownames or in the first column of the table.")
}

# Fetch the gene symbols and descriptions from ENSEMBL using biomaRt
if (species=="human") {
	dataset <- "hsapiens_gene_ensembl"
	filt <- "hgnc_symbol"
}
if (species=="mouse") {
	dataset <- "mmusculus_gene_ensembl"
	filt <- "mgi_symbol"
}
if (species=="rat") {
	dataset <- "rnorvegicus_gene_ensembl"
	filt <- "rgd_symbol"
}

# ensembl <- useMart("ensembl", dataset=dataset)
ensembl <- useMart("ENSEMBL_MART_ENSEMBL", dataset=dataset, host="www.ensembl.org")
genes_ensembl_org <- getBM(attributes <- c("entrezgene_id", "ensembl_gene_id", "external_gene_name", "description"), filters = "ensembl_gene_id", values = genes, mart = ensembl, uniqueRows=T)

pmatch_table		<- pmatch(genes, genes_ensembl_org[,2], duplicates.ok=T)
ensembl_table		<- as.data.frame(matrix(NA, nrow=length(genes), ncol=8))
ensembl_table[which(!is.na(pmatch_table)),] <- genes_ensembl_org[pmatch_table[(!is.na(pmatch_table))], ];
rownames(ensembl_table)	<- genes;
colnames(ensembl_table) <- colnames(genes_ensembl_org);

# Build the table:
# if identifiers in the first column:
if(!is.na(pmatch("ENS", dat[2,1]))) {
	results <- cbind(dat[,1], ensembl_table[,3:4], dat[,2:ncol(dat)]);
	colnames(results) <- c(colnames(dat)[1], "symbol", "description", colnames(dat)[2:ncol(dat)])
	# write result table to output
	write.table(results, file="annotated.tsv", col.names=T, quote=F, sep="\t", row.names=F)
}
# if identifiers = rownames:
if(!is.na(pmatch("ENS",  rownames(dat)[2] ))) {
	#results <- cbind(genes, ensembl_table[,3:4], dat);
	results <- cbind(ensembl_table[,3:4], dat);
	colnames(results) <- c("symbol", "description",  colnames(dat));
	rownames(results) <- rownames(dat)
	# write result table to output
	write.table(results, file="annotated.tsv", col.names=T, quote=F, sep="\t", row.names=T)
}




