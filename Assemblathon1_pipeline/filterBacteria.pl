#!/usr/bin/perl -w
use strict;

my $filter_list = shift;
my $scafSeq = shift;
my %ctgHash;
my %scafHash;

open IN, $filter_list or die;
while (<IN>){
	chomp;
#	if (/^>C/ || /^>scaffold88/){
	if (/^>(C\S+)/ || /^>(s\S+)/){
		$ctgHash{$1} = 1;
	}
	else{
		$_ = substr($_, 1);
		@_ = split;
		push @{$scafHash{$_[0]}}, $_[1];
		push @{$scafHash{$_[0]}}, $_[2];
	}
}
close IN;

open OUT, ">$scafSeq.filter" or die;
open IN, $scafSeq or die;
$/=">"; <IN>; $/="\n";
while (<IN>){
#print "$_\n";
#	my $id = chomp $_;
	my $idSeq = $_;
	chomp $idSeq;
	my @arr = split /\s/, $idSeq;
	my $id = $arr[0];
#print "id: $id\n";
	$/=">";
	my $seq = <IN>;
	chomp $seq;
	$/="\n";
	if (!exists $ctgHash{$id} && !exists $scafHash{$id}){
		print OUT ">$idSeq\n$seq";
	}
	elsif (exists $scafHash{$id}){
#		@_ = split /\t/, $id;
		$seq =~ tr/\n//;
		my $gapLen = $scafHash{$id}[1] - $scafHash{$id}[0] + 1;
#print "gapLen: $gapLen\n";
=cut
		my $seq1 = substr($seq, 0, $scafHash{$id}[0]-1);
		my $gapSeq = "N" x $gapLen;
		my $seq2 = substr($seq, $scafHash{$id}[1]);
		print OUT "$id\n$seq1$gapSeq$seq2";
=cut
		substr($seq, $scafHash{$id}[0]-1, $gapLen) = "N" x $gapLen;

		print OUT ">$idSeq\n";
		for (my $i=0; $i<length($seq); $i+=100) {
			print OUT substr($seq, $i, 100),"\n";
		}
	}
}
close IN;
close OUT;
