#Composé par Aqua
#Email à: rbluo@cs.hku.hk

#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;
use Cwd 'abs_path';

my $SOAP3 = "soap3-dp";
my $SOAP3index = "2bwt-builder";
my $SOAP3index2 = "BGS-Build";
my $SAMTOOL = "samtools";

unless(@ARGV >= 3)
{
	print "perl $0 lib9ColumnList workingFolder reference [is64Enc:1]\n";
	exit;
}

my($fq,$out,$ref,$is64enc) = @ARGV;
$is64enc = " -I " if(defined $is64enc);
$is64enc |= "";

my $b_sh = "align.sh";
my $c_sh = "sort.sh";

$out = abs_path($out);
$out .= "/" unless($out =~/\/$/);
mkdir $out unless(-e $out);
mkdir "$out/reference" unless (-e "$out/reference");
system ("ln -s $ref* $out/reference/");
$ref = "${out}reference/".basename($ref);

unless(-s "$ref.bwt")
{
	print STDERR "Reference index missing, building...\n";
	system("$SOAP3index $ref") == 0 or die "$SOAP3index $ref error!\n";
	system("$SOAP3index2 $ref.index") == 0 or die "$SOAP3index2 $ref.index error!\n";
}
unless(-s "$ref.fai")
{
	print STDERR "Reference fai missing, building...\n";
	if(system("$SAMTOOL faidx $ref") != 0)
	{
		system("rm $ref.fai");
		die "$SAMTOOL faidx $ref error!\n";
	}
}

print STDERR "Generating shells in current directory...\n";

$out .= "bam/";
mkdir $out unless (-e $out);

open L, ">list" or die "$!";
open SH, ">$b_sh" or die "$!";
open SHsort, ">$c_sh" or die "$!";
open IN, "$fq" or die "$!";

my $rd_len = 0;
my $is_total = 0;
my $is_count = 0;
my $lowest = 65535;
my $largest = 0;
my $bamFilenameCache = "";
my %alreadyDone;

while(<IN>)
{
	if(/^$/)
	{
		next;
	}

	my($pe1, $pe2, $len1, $len2, $is, $sd1, $sd2) = (split /\s+/)[2,3,4,5,6,7,8];
	$rd_len = $len1 if ($rd_len < $len1);

	if($pe2 ne "NULL") 
	{
		if($is > 1000)
		{
			next;
		}
		$rd_len = $len2 if ($rd_len < $len2);
		$is_total += $is; ++$is_count;
		$lowest = ($is - $sd1 * 3) if ($lowest > ($is - $sd1 * 3));
		$largest = ($is + $sd2 * 3) if ($largest < ($is + $sd2 * 3));
		my $base1 = basename $pe1;
		my $base2 = basename $pe2;
	}
}
print SH "$SOAP3 pair-multi $ref.index list -u 1500 -v 1 -L $rd_len $is64enc 1>soap3-dp.log 2>&1\n";
close IN; close SH; close SHsort; close L;

print STDERR "Done, please go on to the next step.\n";
