#!/usr/bin/perl -w
use strict;

if (@ARGV < 4) {
        print "rmAdapterPair.pl: used to remove paired-end reads if at least one of the reads contains adapter.\n";
        print "Usage:\n  perl $0 alnDirOfRead1 alnDirOfRead2 read1SeqFile read2SeqFile >rmAdapterPair.log\n";
        print "Example:\n  perl $0 shortjump_1.fa.cut shortjump_2.fa.cut shortjump_1.fastq shortjump_2.fastq >shortjumpRmAdapterPair.log\n";
        exit;
}

my $alnDir1 = shift;
my $alnDir2 = shift;
my $read1File = shift;
my $read2File = shift;

$alnDir1 = substr ($alnDir1, 0, (length $alnDir1)-1) if ($alnDir1 =~ /\/$/);
$alnDir2 = substr ($alnDir2, 0, (length $alnDir2)-1) if ($alnDir2 =~ /\/$/);

my $ID;
my %readID; # aligned read ID
`ls $alnDir1/*.delta >$alnDir1/delta.lst`;
open LST, "$alnDir1/delta.lst" or die "Can't open file: $alnDir1/delta.lst\n";
while (<LST>) {
	chomp;
	open IN, $_ or die "Can't open file: $_\n";
	while (<IN>) {
		if (/^>/) {
			chomp;
			@_ = split;
			$ID = substr ($_[1], 0, (length $_[1])-2);
			$readID{$ID} = 1;
		}
	}
	close IN;
}
close LST;

`ls $alnDir2/*.delta >$alnDir2/delta.lst`;
open LST, "$alnDir2/delta.lst" or die "Can't open file: $alnDir2/delta.lst\n";
while (<LST>) {
	chomp;
	open IN, $_ or die "Can't open file: $_\n";
	while (<IN>) {
		if (/^>/) {
			chomp;
			@_ = split;
			$ID = substr ($_[1], 0, (length $_[1])-2);
			$readID{$ID} = 1;
		}
	}
	close IN;
} 
close LST;

my $remainNum = 0;
my $totalNum = 0;
my ($plusLine1, $plusLine2, $quaLine1, $quaLine2);
open READ1, "$read1File" or die "Can't open file: $read1File\n";
open READ2, "$read2File" or die "Can't open file: $read2File\n";
open OUT1, ">$read1File.rmAd" or die "Can't open file: $read1File.rmAd\n";
open OUT2, ">$read2File.rmAd" or die "Can't open file: $read2File.rmAd\n";
my ($head1, $head2, $seq1, $seq2);
while (<READ1>) {
	$totalNum ++;
	$head1 = $_;
	$seq1 = <READ1>;
	$plusLine1 = <READ1>;
	$quaLine1 = <READ1>;
	$head2 = <READ2>;
	$seq2 = <READ2>;
	$plusLine2 = <READ2>;
	$quaLine2 = <READ2>;

	$ID = substr ($head1, 1, (length $head1) - 4);
	next if (exists $readID{$ID});
	
	$remainNum ++;
	print OUT1 "$head1$seq1$plusLine1$quaLine1";
	print OUT2 "$head2$seq2$plusLine2$quaLine2";
}
close READ1;
close READ2;
close OUT1;
close OUT2;

print "Total pair number: $totalNum\nRemain pair number: $remainNum\n";
