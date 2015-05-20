#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename;
use FindBin qw($Bin $Script);

=head1 Name
    mergePE.pl -- Merge peGrads file.

=head1 Description
    Merge peGrads file for mapping.

=head1 Version
    Version: 1.0,   Date: 2012-9-17

=head1 Usage
    perl mergePE.pl [option]
    --map1  <string>    name of peGrads in map1
    --map2  <string>    name of peGrads in map2
    --cfg   <string>    config file
    --out   <string>    output peGrads
    --help              show this usage
=cut

my $map1;
my $map2;
my $cfg;
my $out;
my $help;

GetOptions(
    "map1:s"=>\$map1,
    "map2:s"=>\$map2,
    "cfg:s"=>\$cfg,
    "out:s"=>\$out,
    "help:s"=>\$help
);

die `pod2text $0` if ($help or !$map1 or !$map2 or !$cfg or !$out);

open IN1,"$map1" or die "fail open input file $map1\n";
open IN2,"$map2" or die "fail open input file $map2\n";
open IN3,"$cfg" or die "fail open input file $cfg\n";
open OUT,">$out" or die "fail open input file $out\n";

my @ins;
my @reads;
my @rank;
my @cut;
my $name="";
my $insnum=0;
my $readsnum=0;
my $readlen=0;

my @tmp;
my $i=0;

while(<IN1>)
{
    chomp;
    if(!/^grads/)
    {
        @tmp = split;
        $ins[$i] = $tmp[0];
        $reads[$i] = $tmp[1];
        $rank[$i] = $tmp[2];
        $cut[$i] = $tmp[3];
        $i++;
    }
    else
    {
        @tmp = split;
        $name = $tmp[0];
        $insnum = $tmp[1];
        $readsnum = $tmp[2];
        $readlen = $tmp[3];
    }
}

my $j = $i - 1;

while(<IN2>)
{
    chomp;
    if(!/^grads/)
    {
        @tmp = split;
        $ins[$i] = $tmp[0];
        $reads[$i] = $tmp[1] + $reads[$j];
        $rank[$i] = $tmp[2];
        if($tmp[3] > $cut[$j])
        {
            $cut[$i] = $tmp[3];
        }
        else
        {
            $cut[$i] = $cut[$j];
        }
        $i++;
    }
    else
    {
        @tmp = split;
        $name = $tmp[0];
        $insnum += $tmp[1];
        $readsnum += $tmp[2];
        if($tmp[3] > $readlen)
        {
            $readlen = $tmp[3];
        }
    }
}

my $k = 0;
while(<IN3>)
{
    chomp;
    if($_=~/^\[LIB\]/)
    {
        $k++;
    }
    @tmp = split(/=/, $_);
    if($_=~/^rank/)
    {
        $rank[$k -1] = $tmp[1];
    }
    if($_=~/^pair_num_cutoff/)
    {
        $cut[$k - 1] = $tmp[1];
    }
}

$j = $i - 1;
$i = 0;
print OUT "$name $insnum\t$readsnum\t$readlen\n";
while($i <= $j)
{
    print OUT "$ins[$i]\t$reads[$i]\t$rank[$i]\t$cut[$i]\n";
    $i++;
}

close IN1;
close IN2;
close IN3;
close OUT;
