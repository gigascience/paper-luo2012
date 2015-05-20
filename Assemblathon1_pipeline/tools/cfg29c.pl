#!/usr/bin/perl -w
use strict;
use File::Basename;
unless(@ARGV==1)
{
	print "perl $0 <cfg input file>\n";
	exit 1;
}

my ($avg_ins,$rd_len_cutoff,$name,$max_ins,$min_ins,$q1);


open IN,"$ARGV[0]" or die "Cannot open $ARGV[0] to read";
while(<IN>)
{
	chomp();
	if(/^\[LIB\]/)
	{
		undef $avg_ins; undef $rd_len_cutoff; undef $name; undef $max_ins; undef $min_ins; undef $q1;
	}
	$name = "default";
	$rd_len_cutoff = 100;
	if(/^name/)
	{
		($name)=$_=~/=(\S+)/;
	}
	if(/^avg_ins/)
	{
		($avg_ins)=$_=~/(\d+)/;
	}
	if(/^max_ins/)
	{
		($max_ins)=$_=~/(\d+)/;
	}
	if(/^min_ins/)
	{
		($min_ins)=$_=~/(\d+)/;
	}
	if(/^rd_len_cutoff/)
	{
		($rd_len_cutoff)=$_=~/(\d+)/;
	}
	if(/^q=/)
	{
		$q1 = substr($_,2);
		print "id\t$name\t$q1\tNULL\t$rd_len_cutoff\t$rd_len_cutoff\tNULL\tNULL\tNULL\n";
	}
	if(/^q1=/)
	{
		$q1=substr($_,3);
	}
	if(/^q2=/)
	{
		my $q2 = substr($_,3);
		if($avg_ins !~ /\d/)
		{
			$avg_ins = 200;
		}
		my ($min,$max);
		if(defined $max_ins && defined $min_ins)
		{
			$min = int(($avg_ins - $min_ins) / 3);
			$max = int(($max_ins - $avg_ins) / 3);
		}
		else
		{
			my $SD = int(16.6+($avg_ins/100) * 16.6);
			$min = $SD;
			$max = $SD;
		}
		$rd_len_cutoff=100 unless (defined $rd_len_cutoff);
		print "default\t$name\t$q1\t$q2\t$rd_len_cutoff\t$rd_len_cutoff\t$avg_ins\t$min\t$max\n";
	}
}
close IN;

0;
