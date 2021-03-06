# Adds "chr" to the each chromosome name starting with number or X or Y, Changes MT to chrM
# It uses samtools reheader command
#
addChrToBAM <- function(input, output){
	samtools.binary <- c(file.path(chipster.tools.path, "samtools", "samtools"))
		system(paste(samtools.binary, "view -H", input, "| sed -e 's/SN:\\([0-9XY]\\)/SN:chr\\1/' -e 's/SN:MT/SN:chrM/' |", samtools.binary, "reheader -", input, ">", output))
}

# Changes the file names in BAM header to display names according to chipster-inputs.tsv
#
displayNamesToBAM <- function(input.bam){
		
	# Read BAM header to file
	samtools.binary <- c(file.path(chipster.tools.path, "samtools", "samtools"))
	system(paste(samtools.binary, "view -H", input.bam, "> header.sam"))
	
	# Go through input names and change names
	input.names <- read.table("chipster-inputs.tsv", header=F, sep="\t")
	for (i in 1:nrow(input.names)) {
		sed.command <- paste("s/", input.names[i,1], "/", input.names[i,2], "/", sep="")
		system(paste("sed -i", sed.command, "header.sam"))
	}
	
	# Write new header to BAM
	system(paste(samtools.binary, "reheader header.sam", input.bam, "> tmp.bam"))
	system(paste("mv tmp.bam", input.bam))
}
