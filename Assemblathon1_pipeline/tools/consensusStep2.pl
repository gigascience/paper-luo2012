#!/usr/bin/perl -w

#Program Paths;
$SAMTOOLS = "../samtools";
$BCFTOOLS = "../bcftools";
$JAVA = "java";
$MARKDUP = "../MarkDuplicates.jar";
$VCFUTILS = "../vcfutils.pl";
$GENEFASTA = "../genEFASTAbyVCF.pl";
$MODSEQ = "../modSeqbyVCF.pl";

($cfgFN, $ref) = @ARGV;
die "perl $0 <SOAPdenovo Configuration File> <Assembly FASTA>\n" unless defined $ref;

if($cfgFN!~/^\// or $ref!~/^\//)
{
	die "Please input the absolute path\n";
}
$ret = 0;
$nineColFN = "$cfgFN.9c";
die "$nineColFN doesn't exist.\n" if !-e "$nineColFN";

chdir("bam");
#seraching bam files
@bam = `ls *.sort.bam`; chomp @bam;

#merging bam files
if(scalar(@bam) > 1)
{
	$ret = system("$SAMTOOLS merge merged.bam ".(join " ",@bam));
	die "$SAMTOOLS merge failed.\n" if $ret != 0 or !-e "merged.bam";
}
else
{
	system("ln $bam[0] merged.bam");
}

#remove duplication
$ret = system("$JAVA -XX:MaxPermSize=40g -Xmx40g -jar $MARKDUP I=merged.bam O=mergedRD.bam M=mergedRD.metric REMOVE_DUPLICATES=true AS=true VALIDATION_STRINGENCY=SILENT CREATE_INDEX=true TMP_DIR=/tmp MAX_FILE_HANDLES=800");
die "$MARKDUP merge failed.\n" if $ret != 0 or !-e "mergedRD.bam";

#call variant
$ret = system("$SAMTOOLS calmd -AEur mergedRD.bam $ref | $SAMTOOLS mpileup -d 250 -ugf $ref - | $BCFTOOLS view -bvcg - > merged.bcf");
die "Variant calling failed.\n" if $ret != 0 or !-e "merged.bcf";

#generate vcf
$ret = system("$BCFTOOLS view merged.bcf | $VCFUTILS varFilter -D 250 > merged.vcf");
die "BCF2VCF failed.\n" if $ret != 0 or !-e "merged.vcf";

#modify sequence
$ret = system("perl $GENEFASTA $ref merged.vcf > $ref.efasta");
die "$GENEFASTA failed.\n" if $ret != 0 or !-e "$ref.efasta";
$ret = system("perl $MODSEQ $ref merged.vcf > $ref.consensus");
die "$MODSEQ failed.\n" if $ret != 0 or !-e "$ref.consensus";

chdir("..");

0;
