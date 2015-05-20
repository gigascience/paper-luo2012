#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;

=head1 Name
    downloap.pl -- Downloap files.

=head1 Description
    Dowloap files from ftp.

=head1 Version
    Version: 1.0,   Date: 2012-9-6

=head1 Usage
    perl download.pl [option]
    --dest      <string>    download address, the directory containing all files to be downloaded
    --md5       <string>    name of md5sum txt file
    --dir       <string>    dir of output
    --help                  show this usage
=cut

my $list;
my $dest;
my $md5;
my $dir;
my $help;

GetOptions(
    "dest:s"=>\$dest,
    "md5:s"=>\$md5,
    "dir:s"=>\$dir,
    "help:s"=>\$help
);
die `pod2text $0` if ($help or !$md5 or !$dest);

if(!defined($dir))
{
    $dir=".\/";
}
else
{
    $dir.="\/";
}

open IN1,"$md5" or die "fail open input file $md5\n";
open OUT,">$list" or die "fail open output file $list\n";

my @temp;
my %hash;
while(<IN1>)
{
    chomp;
    @temp = split;
    $hash{$temp[1]} = $temp[0];
}
my $test;
my $file;
while(my($key, $value)=each(%hash))
{
    $file = $dir.$key;
    if( ! -e $file )
    {
        print OUT $key."\n";
        next;
    }
    $test = `md5sum $file`;
    @temp = split(/\s+/, $test);
    if($temp[0] ne $value)
    {
        print OUT $key."\n";
        next;
    }
}
close IN1;
close OUT;

if( !-s "$list" )
{
    print "Files are all downloaded previously, no need to download again.\n";
    exit;
}

my $stat=0;
print "Downloading file from $dest\n";
#-r recursive -l level -c continue -t times -T time -nH no-host-dir -i list
$stat = system("cd $dir;wget -r -l 1 -c -t 2 -T 30 -nH -B $dest -i $list");# --cut-dirs 1
if($stat != 0)
{
    print "Error in downloading from $dest!\n";
    exit -1;
}
