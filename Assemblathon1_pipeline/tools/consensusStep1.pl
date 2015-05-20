#!/usr/bin/perl -w

#Program Paths;
$RUNBWA = "./runBWA.pl";
$RUNSOAP3 = "./runSOAP3dp.pl";
$CFG29C = "./cfg29c.pl";

($cfgFN, $referenceFN, $pgm, $is64) = @ARGV;
die "perl $0 <SOAPdenovo Configuration File> <Assembly FASTA> <Program to use: soap3dp or bwa> <Is Illumina 1.3+ Encoding: 0 or 1>\n" unless defined $is64;

if($cfgFN!~/^\// or $referenceFN!~/^\//)
{
	die "Please input the absolute path\n";
}

$ret = 0;
$nineColFN = "$cfgFN.9c";

$ret = system("perl $CFG29C $cfgFN > $nineColFN");
die "CFG29C failed\n" if ($ret != 0 or !-e "$nineColFN");

$PWD = `pwd`; chomp $PWD;
if($pgm eq "bwa")
{
	$ret = system("perl $RUNBWA $nineColFN $PWD $referenceFN $is64");
	die "RUNBWA failed\n" if ($ret != 0 or !-e "align.sh");
	print "Please run align.sh and then run consensusStep2.pl\n";
}
elsif($pgm eq "soap3dp")
{
	$ret = system("perl $RUNSOAP3 $nineColFN $PWD $referenceFN $is64");
	die "RUNSOAP3dp failed\n" if ($ret != 0 or !-e "align.sh" or !-e "sort.sh");
	print "Please run align.sh, then sort.sh, and then run consensusStep2.pl\n";
}
else
{
	die "Please select a program: soap3dp or bwa\n";
}

0;
