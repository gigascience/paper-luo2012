#!/usr/bin/perl -w
use strict;

my $blast_result = shift;
#my $scafSeq = shift;
my @contigArr;
my %scafHash;
my $preCtg = "";
my $curCtg;
my $preScaf = "";
my $curScaf;
my $ctgCount = 0;
my $scafCount = 0;

open TOTALOUT, ">total.list" or die;
open IN, $blast_result or die;
while (<IN>){
	chomp;

	open SUBIN, $_ or die;

	while (<SUBIN>){
		chomp;

		@_ = split /\s/;

		if ($_[0] =~ /^C/){
			$curCtg = $_[0];

			next if ($curCtg eq $preCtg);
	
			push @contigArr, $curCtg;
			$preCtg = $curCtg;

			$ctgCount++;
		}
		else{
			if (!exists $scafHash{$_[0]}->{$_[6]}){
				$scafHash{$_[0]}->{$_[6]} = $_[7];
			}
			elsif ($_[7] > $scafHash{$_[0]}->{$_[6]}){
				$scafHash{$_[0]}->{$_[6]} = $_[7];
			}
		}
	}
	close SUBIN;
}
close IN;
open OUT, ">ctg.list" or die;
foreach (@contigArr){
	print OUT ">$_\n";
	print TOTALOUT ">$_\n";
}
close OUT;

open TESTOUT, ">test.out" or die;

print "There are $ctgCount contig.\n";

my %cptScafHash;
foreach my $scaf(sort keys%scafHash){
	print TESTOUT "$scaf\n";

	$scafCount++;
	push @{$cptScafHash{$scaf}}, 0;
	push @{$cptScafHash{$scaf}}, 0;

	foreach my $pos(sort {$a<=>$b} keys%{$scafHash{$scaf}}){
		print TESTOUT "$pos\t$scafHash{$scaf}->{$pos}\t";
		print TESTOUT "$cptScafHash{$scaf}[-1]\n";
		if ($pos > $cptScafHash{$scaf}[-1]){
			push @{$cptScafHash{$scaf}}, $pos;
			push @{$cptScafHash{$scaf}}, $scafHash{$scaf}->{$pos};
		}
		elsif ($scafHash{$scaf}->{$pos} > $cptScafHash{$scaf}[-1]){
			$cptScafHash{$scaf}[-1] = $scafHash{$scaf}->{$pos};
		}
	}
}
#close TESTOUT;
print "There are $scafCount scaffold.\n";

my $length = 0;
open OUT, ">scaf.list" or die;
foreach (keys %cptScafHash){
	print OUT ">$_\n";
	print TOTALOUT ">$_\n";
	print TESTOUT ">$_\t";
	$length = 0;
	for (my $i=2; $i<@{$cptScafHash{$_}}; $i+=2){
		print OUT "$cptScafHash{$_}[$i]\t$cptScafHash{$_}[$i+1]\n";
		$length += $cptScafHash{$_}[$i+1] - $cptScafHash{$_}[$i];
	}
	print TESTOUT "$length\n";
}
close OUT;
close TESTOUT;
close TOTALOUT;
