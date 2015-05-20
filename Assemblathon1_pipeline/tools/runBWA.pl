#Composé par Aqua
#Email à: rbluo@cs.hku.hk

#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;
use Cwd 'abs_path';

my $BWA = "bwa";
my $SAMTOOL = "samtools";

unless(@ARGV >= 3)
{
	print "perl $0 lib9ColumnList workingFolder reference [is64Enc:1]\n";
	exit;
}

my($fq,$out,$ref,$is64enc) = @ARGV;
if($is64enc eq "0")
{
	$is64enc = "";
}
elsif($is64enc eq "1")
{
	$is64enc = " -I ";
}
else
{
	die "Please input correct Encoding mode.\n";
}

my $b_sh = "align.sh";

$out = abs_path($out);
$out .= "/" unless($out =~/\/$/);
mkdir $out unless(-e $out);
mkdir "$out/reference" unless (-e "$out/reference");
system ("ln $ref* $out/reference/");
$ref = "${out}reference/".basename($ref);

unless(-s "$ref.bwt")
{
	print STDERR "Reference index missing, building...\n";
	system("$BWA index -a is $ref") == 0 or die "$BWA index $ref error!\n";
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

my $out_backup = $out;
$out .= "bam/";
mkdir $out unless (-e $out);
my $BAM= $out . "merged.bam";
my @SAM ;
#open OU, ">$m_sh" or die "$!";

open SH, ">$b_sh" or die "$!";
open IN, "$fq" or die "$!";

my $rd_len = 65535;
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
	$rd_len = $len1 if ($rd_len > $len1);

	if($pe2 ne "NULL") 
	{
		if($is > 1000)
		{
			next;
		}
		$rd_len = $len2 if ($rd_len > $len2);
		$is_total += $is; ++$is_count;
		$lowest = ($is - $sd1 * 3) if ($lowest > ($is - $sd1 * 3));
		$largest = ($is + $sd2 * 3) if ($largest < ($is + $sd2 * 3));
		my $base1 = basename $pe1;
		my $base2 = basename $pe2;
		if($base2 eq $base1)
		{
			$base2 .= "._2";
		}
		$alreadyDone{$base1}=0 unless (defined $alreadyDone{$base1});
		$alreadyDone{$base1}++;
		$base2 .= $alreadyDone{$base1};
		$base1 .= $alreadyDone{$base1};
		my $sai1 = $out . $base1 . ".pipe";
		my $sai2 = $out . $base2 . ".pipe";
		my $bam = $out . $base1 . ".bam";
		print SH "mkfifo $sai1 $sai2; ";
		print SH "$BWA aln $is64enc -i 10 -t 4 $ref $pe1 >$sai1  & ";
		print SH "\\$BWA aln $is64enc -i 10 -t 4  $ref $pe2 >$sai2  & ";
		print SH "\\$BWA sampe $ref $sai1 $sai2 $pe1 $pe2  | ";
		print SH "$SAMTOOL view -S -u -t $ref.fai -  | ";
		print SH "$SAMTOOL sort - $bam.sort  ; ";
		print SH "rm -f $sai1 $sai2"; 
		push @SAM,"$bam.sort.bam";
		print SH " && echo \" $base1 done\"\n";
	}
}
close IN;
$out = $out_backup;
close SH;

print STDERR "Done, please go on to the next step.\n";
