#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;

=head1 Name
    checkfile.pl -- Check file of each step.

=head1 Description
    Check the file of each step.

=head1 Version
    Version: 1.0,   Date: 2012-9-6

=head1 Usage
    perl checkfile.pl [option]
    --prefix    <string>    prefix of SOAPdeonvo output
    --err       <string>    name of error output file
    --step      <string>    step, filter kmerfreq correct all pregraph contig map scaff gapcloser or consensus
    --help                  show this usage
=cut

my $err;
my $prefix;
my $step;
my $help;

GetOptions(
    "prefix:s"=>\$prefix,
    "err:s"=>\$err,
    "step:s"=>\$step,
    "help:s"=>\$help
);

die `pod2text $0` if ($help or !$step);

if(!defined($err))
{
    $err="err";
}

if( -s $err )
{
    print "Error in step $step\n";
    exit -1;
}

if($step ne "filter" && $step ne "kmerfreq" && $step ne "correct" && $step ne "pregraph" && $step ne "contig" && $step ne "map" && $step ne "scaff" && $step ne "all" && $step ne "gapcloser" && $step ne "consensus")
{
    print "There is no step $step\n";
    exit -1;
}

if($step eq "pregraph" && $step eq "contig" && $step eq "map" && $step eq "scaff" && $step eq "all" && $step eq "gapcloser" && $step eq "consensus")
{
    die `pod2text $0` if (!$prefix);
}

my $all=0;
if($step eq "all")
{
    $all = 1;
}

if($all)
{
    $step = "pregraph";
}

if($step eq "pregraph")
{
    if( (!-s "../assembly/$prefix.vertex" && !-s "$prefix.vertex") || (!-s "../assembly/$prefix.preArc" && !-s "$prefix.preArc") || (!-s "../assembly/$prefix.preGraphBasic" && !-s "$prefix.preGraphBasic") || (!-s "../assembly/$prefix.edge.gz" && !-s "../assembly/$prefix.edge" && !-s "$prefix.edge.gz" && !-s "$prefix.edge") )
    {
        print "Missing file in step $step\n";
        exit -1;
    }
}

if($all)
{
    $step = "contig";
}

if($step eq "contig")
{
    if( (!-s "../assembly/$prefix.contig" && !-s "$prefix.contig") || (!-s "../assembly/$prefix.preGraphBasic" && !-s "$prefix.preGraphBasic") || (!-s "../assembly/$prefix.updated.edge" && !-s "$prefix.updated.edge") || (!-s "../assembly/$prefix.Arc" && !-s "$prefix.Arc") || (!-s "../assembly/$prefix.ContigIndex" && !-s "$prefix.ContigIndex") )
    {
        print "Missing file in step $step\n";
        exit -1;
    }
}

if($all)
{
    $step = "map";
}

if($step eq "map")
{
    if( (!-s "../assembly/$prefix.readOnContig.gz" && !-s "../assembly/$prefix.readOnContig" && !-s "$prefix.readOnContig.gz" && !-s "$prefix.readOnContig") || (!-s "../assembly/$prefix.readInGap.gz" && !-s "../assembly/$prefix.readInGap" && !-s "$prefix.readInGap.gz" && !-s "$prefix.readInGap") || (!-s "../assembly/$prefix.peGrads" && !-s "$prefix.peGrads") )
    {
        print "Missing file in step $step\n";
        exit -1;
    }
}

if($all)
{
    $step = "scaff";
}

if($step eq "scaff")
{
    if( (!-s "../assembly/$prefix.scafSeq" && !-s "$prefix.scafSeq") || (!-s "../assembly/$prefix.newContigIndex" && !-s "$prefix.newContigIndex") || (!-s "../assembly/$prefix.links" && !-s "$prefix.links") )
    {
        print "Missing file in step $step\n";
        exit -1;
    }
}

if($step eq "gapcloser")
{
    if( (!-s "../gapcloser/$prefix.scafSeq.GC" && !-s "$prefix.scafSeq.GC") )
    {
        print "Missing file in step $step\n";
        exit -1;
    }
}

if($step eq "consensus")
{
    if( (!-s "../consensus/$prefix.scafSeq.GC.consensus" && !-s "$prefix.scafSeq.GC.consensus") )
    {
        print "Missing file in step $step\n";
        exit -1;
    }
}

