#! /usr/bin/perl

=head1 Name:
	
  makeSH.pl

=head1 Usage:

  perl makeSH.pl <lane.lst> <lib.lst>
    -t <int> thread number for each filter_data job,default 8
    -m <int> the reads pair number in buffer,default 2000000
    -q <int> the ASCII shift of the quality value (usually 64 or 33 for Illumina data),default 64
    -f <int> trim flag,-1 for not trimming, 0 for unify triming, 1 for trim min(maskB length,-b/-d);default[0]
    -y       filter reads with adapter 
    -F       adapter sequence for read1,defaule:AGATCGGAAGAGCGGTTCAGCAGGAATGCCGAG
    -R       adapter sequence for read2,default:AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT
    -z       filter small insert size
    -p       filter PCR duplicate
    -b       add '&' on the end of each line in the shell file
    -h       output help information to screen

  Note:
  1.format of lane.lst
    read1_file_name  5'end_trim_length 3'end_trim_length low_quality_number_cutoff
    read2_file_name  5'end_trim_length 3'end_trim_length Nbase_percentage_cutoff
  2.format of lib.lst
    lib_name  insert_size
  3.read1_file_name must match /L\d+_([^_]+)_1/,$1 is the lib name
  4.low_quality_number_cutoff is an integer, -1 for do not low quality filter,default 40
  5.N_percentage_cutoff is an integer,filter reads with >X percent base is N,-1 for not filter,default 10

=head1 Example:
  lane.lst:
    110114_I481_FC81C7HABXX_L5_HUMiqvDBTDIAAPE_1.fq.gz 2 3 40
    110114_I481_FC81C7HABXX_L5_HUMiqvDBTDIAAPE_2.fq.gz 2 3 10
  lib.lst:
    HUMiqvDBTDIAAPE 500
  perl makeSH.pl -q 64 -f 0 -y -z -p -b lane.lst lib.lst

  that will generate an shell file named lan.lst.filter.sh for do filter work.

=cut

use strict;
use warnings;
use FindBin qw($Bin);
use Getopt::Long;

##get options from command line into variables and set default values
my ($f,$y,$a1,$a2,$z,$p,$b, $thread_num, $buffer_size, $Q_shift, $Help);
Getopt::Long::Configure qw(bundling no_ignore_case);
GetOptions(
	"t:i"=>\$thread_num,
	"m:i"=>\$buffer_size,
	"q:i"=>\$Q_shift,
	"f:i"=>\$f,
	"y"=>\$y,
	"F:s"=>\$a1,
	"R:s"=>\$a2,
	"z"=>\$z,
	"p"=>\$p,
	"b"=>\$b,
	"h"=>\$Help
);

die `pod2text $0` if(@ARGV<2||$Help);

my $lane_lst = shift;
my $lib_lst = shift;

$thread_num ||= 8;
$buffer_size ||= 2000000;
$Q_shift ||= 64;
$f ||= 0;

my $parameter = "";
if($y)
{
	$parameter = "-y";
	$parameter=$parameter . " -F " . $a1 if($a1);
	$parameter=$parameter . " -R " . $a2 if($a2);
}
$parameter .= " -z" if($z);
$parameter .= " -p" if($p);
my $background="";
$background="&" if($b);

my $file_name = `basename $lane_lst`;
chomp $file_name;

my $pwd = `pwd`;
chomp $pwd;

my %Lib;
my $vf="";
open IN,$lib_lst or die "$!";
while(<IN>){
	if (/^(\S+)\s+(\d+)/){
		$Lib{$1}=$2;
		mkdir($1) unless (-d $1);
	}else{
		next;
	}
}
close IN;

open OUT1, ">$file_name.filter.sh" or die "$!";

open IN,$lane_lst or die "$!";

my $stat_output = '';
my $num = 0;
while(<IN>){
	next if !/_1\.fq/;
	chomp;
	$num++;
	
	my ($f1,$start1,$end1,$B_cutoff) = split(/\s+/);
	$start1 ||= 0;
	$end1 ||= 0;
	$B_cutoff ||= 40;
	
	my $line2 = <IN>;
	chomp $line2;
	my ($f2,$start2,$end2,$N_num) = split(/\s+/,$line2);
	$start2 ||= 0;
	$end2 ||= 0;
	if(not defined $N_num or $N_num eq "")
	{$N_num ||= 10;}
	
	my $name = `basename $f1`;
	chomp $name;
	my $name2 = `basename $f2`;
	chomp $name2;
	my $lib;
	if ( $name =~/L\d+_([^_]+)_1/ ){
		$lib = $1;
	}else{
		die;
	}
	next if not exists $Lib{$lib};
	print OUT1 "$Bin/SOAPfilter_v2.0 -t $thread_num -m $buffer_size $parameter -q $Q_shift -w $N_num -B $B_cutoff -l $Lib{$lib} -f $f -a $start1 -b $end1 -c $start2 -d $end2 $f1 $f2 $pwd/$lib/$name.filter.stat $pwd/$lib/$name.clean $pwd/$lib/$name2.clean $background\n";#&& echo OK \n" ;
}

if($background eq "&")
{
	print OUT1 "wait\n";
}

close IN;
close OUT1;

