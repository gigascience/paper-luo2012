#!/usr/bin/perl -w
use strict;

if (@ARGV < 1) {
	print "fq2fa.pl: convert fastq file to fasta file.\nUsage:\n  perl $0 *.fastq >*.fasta\n";
	exit;
}

my $fq = shift;
my ($gotHead, $gotSeq, $gotPlus, $gotQual) = (0, 0, 0, 1);
my $seq = "";
my $quality = "";
my ($seqLen, $qualLen) = (0, 0);
my $cmd = ($fq =~ /gz$/) ? "gzip -dc $fq |" : "$fq";

open IN, $cmd or die "Can't open file: $fq\n";
while (<IN>) {
	if (/^@/ && $gotQual == 1) {
		print ">",substr ($_, 1);
		$gotSeq =  1;
		$gotQual = 0;
	} elsif ($gotSeq == 1 && !/^\+/) {
		chomp $_;
		$seq .= $_;
	} elsif (/^\+/ && $gotPlus == 0) {
		$seqLen = length $seq;
		print "$seq\n";
		$seq = "";
		$gotPlus = 1;
		$gotSeq = 0;
	} elsif ($gotPlus == 1) {
		chomp $_;
		$quality .= $_;

		if (($qualLen = length $quality) == $seqLen) {
			$gotPlus = 0;
			$gotQual = 1;

			$seqLen = 0;
			$qualLen = 0;

			$quality = "";
		}
	}
}
close IN;
