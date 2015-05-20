#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename;
use FindBin qw($Bin $Script);

=head1 Name
    checkmd5.pl -- Check the md5sum of file.

=head1 Description
    Compare the md5sum with precompute file.

=head1 Version
    Version: 1.0,   Date: 2012-9-5

=head1 Usage
    perl checkmd5.pl [option]
    --md5   <string>    name of md5sum txt file
    --dir   <string>    name of dir
    --help              show this usage
=cut

my $md5;
my $dir;
my $help;

GetOptions(
    "md5:s"=>\$md5,
    "dir:s"=>\$dir,
    "help:s"=>\$help
);

die `pod2text $0` if ($help or !$md5);

if(!defined($dir))
{
    $dir=".\/";
}

#$md5 = $dir.$md5;
open IN1,"$md5" or die "fail open input file $md5\n";

my @temp;
my %hash;

while(<IN1>)
{
    chomp;
    @temp = split;
    $hash{$temp[1]} = $temp[0];
}

my $test;
my $isOk = 1;
while(my($key, $value)=each(%hash)) 
{
    $key = $dir.$key;
    if( ! -e $key)
    {
        print STDERR "File $key is not exist\n";
        exit -1;
    }
    $test = `md5sum $key`;
    @temp = split(/\s+/, $test);
    if($temp[0] ne $value)
    {
        print STDERR "Md5sum of file $key is not the same as pre-compute!\n";
        $isOk = 0;
        exit -1;
    }
}

if($isOk)
{
    print STDOUT "File is OK!\n";
}

close IN1;

