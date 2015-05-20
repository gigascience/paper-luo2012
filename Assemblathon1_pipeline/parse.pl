#!/usr/bin/perl

use warnings;
use strict;
use Cwd;
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename;
use FindBin qw($Bin $Script);

=head1 Name
    parse.pl -- Parse the profile.

=head1 Description
    Parse the profile to set parsmeters.

=head1 Version
    Version: 1.0,   Date: 2012-9-6

=head1 Usage
    perl parse.pl [option]
    --profile   <string>    name of profile
    --start     <int>       start from which step[0-10 default[0]]
        0   download file
        1   filter
        2   kmer freq
        3   error correction
        4   pregraph or all
        5   contig
        6   map
        7   scaff
        8   gapcloser
	9   filter contamination
        10   consensus
    --stop      <int>       end of which step[0-10 deault[10]]
    --help                  show this usage
=cut

my $profile;
my $step;
my $stop;
my $help;

GetOptions(
    "profile:s"=>\$profile,
    "start:s"=>\$step,
    "stop:s"=>\$stop,
    "help:s"=>\$help
);

die `pod2text $0` if ($help or !$profile);

open IN1,"$profile" or die "fail open input file $profile\n";

my $outdir;
my $progdir = $Bin."\/";
my $download;
my $bz2;
my $dest;
my $filterpara;
my $lanelist;
my $liblist;
my $kmerfreq;
my $kmerfreqpara;
my $correction;
my $correctpara;
my $mergepair;
my $mergelist;
my $estimate;
my $estpara;
my $SOAPdenovo;
my $sparse;
my $all;
my $pregraph;
my $contig;
my $map;
my $map1;
my $scaff;
my $checkmd5;
my $checkfile;
my $md5;
my $err;
my @tmp;
my $prefix;
my $config;
my $kgf;
my $kgfpara;
my $gapcloser;
my $gappara;
my $gapcfg;
my $concfg;
my $align;
my $is13;
my $blast;
my $blastpara;
my $pwd=getcwd;

#parse the profile to set parameters
while(<IN1>)
{
    chomp;
    @tmp = split(/\:/,$_);
    if(/^#/)
    {
        next;
    }
    elsif(/^outdir:/)
    {
        $outdir = $tmp[1];
    }
    elsif(/^dest:/)
    {
        $dest = substr($_, 5, length($_) - 5);#$tmp[1].":".$tmp[2];
    }
    elsif(/^bz2:/)
    {
	$bz2 = $tmp[1];
    }
    elsif(/^filterpara:/)
    {
        $filterpara = $tmp[1];
    }
    elsif(/^lanelist:/)
    {
        $lanelist = $tmp[1];
    }
    elsif(/^liblist:/)
    {
        $liblist = $tmp[1];
    }
    elsif(/^kmerfreq:/)
    {
        $kmerfreq = $tmp[1];
    }
    elsif(/^kmerfreqpara:/)
    {
        $kmerfreqpara = $tmp[1];
    }
    elsif(/^correction:/)
    {
        $correction = $tmp[1];
    }
    elsif(/^correctpara:/)
    {
        $correctpara = $tmp[1];
    }
    elsif(/^mergepair:/)
    {
        $mergepair = $tmp[1];
    }
    elsif(/^mergelist:/)
    {
        $mergelist = $tmp[1];
    }
    elsif(/^estpara:/)
    {
        $estpara = $tmp[1];
    }
    elsif(/^SOAPdenovo:/)
    {
        $SOAPdenovo = $tmp[1];
    }
    elsif(/^sparse:/)
    {
        $sparse = $tmp[1];
    }
    elsif(/^all:/)
    {
        $all = $tmp[1];
    }
    elsif(/^pregraph:/)
    {
        $pregraph = $tmp[1];
    }
    elsif(/^contig:/)
    {
        $contig = $tmp[1];
    }
    elsif(/^map:/)
    {
        $map = $tmp[1];
    }
    elsif(/^map1:/)
    {
        $map1 = $tmp[1];
    }
    elsif(/^scaff:/)
    {
        $scaff = $tmp[1];
    }
    elsif(/^md5:/)
    {
        $md5 = $tmp[1];
    }
    elsif(/^err:/)
    {
        $err = $tmp[1];
    }
    elsif(/^kgf:/)
    {
	$kgf = $tmp[1];
    }
    elsif(/^kgfpara:/)
    {
	$kgfpara = $tmp[1];
    }
    elsif(/^gapcloser:/)
    {
        $gapcloser = $tmp[1];
    }
    elsif(/^gappara:/)
    {
        $gappara = $tmp[1];
    }
    elsif(/^gapcfg:/)
    {
        $gapcfg = $tmp[1];
    }
    elsif(/^concfg:/)
    {
        $concfg = $tmp[1];
    }
    elsif(/^align:/)
    {
        $align = $tmp[1];
    }
    elsif(/^is13:/)
    {
        $is13 = $tmp[1];
    }
    elsif(/^blast:/)
    {
        $blast = $tmp[1];
    }
    elsif(/^blastpara:/)
    {
        $blastpara = $tmp[1];
    }
}

close IN1;

#default setting
if(!defined($outdir))
{
    $outdir=getcwd."\/";
    if( !-d $outdir )
    {
        `mkdir $outdir`;
    }
}
elsif($outdir=~/^\//)
{
    $outdir=$outdir."\/";
    if( !-d $outdir )
    {
        `mkdir $outdir`;
    }
}
else
{
    $outdir=getcwd."\/$outdir\/";
    if( !-d $outdir )
    {
        `mkdir $outdir`;
    }
}

if(!defined($err))
{
    $err="err";
}

if(!defined($step))
{
    $step=0;
}

if(!defined($stop))
{
    $stop=10;
}
my $stat=0;

$estimate = $progdir."estimate_memory.pl";
$checkfile = $progdir."checkfile.pl";

#check md5 of the files
if( !defined($md5) )
{
    print "The profile of checkmd5 is not well defined, md5 file not found\n";
    exit -1;
}

$md5 = $progdir.$md5;

#step 0: download files
if($step <= 0 && $stop >= 0)
{
    if( !defined($dest) )
    {
        print "The download address is not provided!\n";
        exit -1;
    }
    $dest.="\/";
    $download = $progdir."download.pl";
    
    if( !-d "$outdir/data" )
    {
        `mkdir $outdir/data`;
    }
    
    $stat = system("perl $download --dest $dest --dir $outdir/data/ --md5 $md5 2>download.out");

    if($stat != 0)
    {
        print "Error in downloading!\n";
        exit -1;
    }
    
    $checkmd5 = $progdir."checkmd5.pl";

    $stat = system("perl $checkmd5 --md5 $md5 --dir $outdir/data/");

    if($stat != 0)
    {
        print "Error in download file!\n";
        exit -1;
    }

    if ($bz2 == 1)
    {
	`cd $outdir/data`;
	$stat = system('for f in *.bz2; do bzip2 -d $f; done');
	if ($stat != 0)
	{
	    print "Error in decompressing bz2 file!\n";
	    exit -1;
	}
	$stat = system('for f in *.fastq; do gzip $f; done');
	if ($stat != 0)
	{
	    print "Error in compressing files!\n";
	    exit -1;
	}
    }

    $stat = system("sh linkFiles.sh");
    if ($stat != 0)
    {
	print "Error in linking files!\n";
	exit -1;
    }
}

if($stop <= 0)
{
    print "Stop at step $stop\n";
    exit;
}

#step 1: filter
if($step <= 1 && $stop >= 1)
{
    if( !defined($lanelist) || !defined($liblist))
    {
        print "The profile of filter is not well defined\n";
        exit -1;
    }
    if( !-d "$outdir/filter" )
    {
        `mkdir $outdir/filter`;
    }

    `rm $outdir/filter/filter.sh -f`;

    if( !-s $lanelist )
    {
        print "The $lanelist is not exist!\n";
        exit -1;
    }
    else
    {
        open IN, "$lanelist" or die "fail open file $lanelist\n";
        while(<IN>)
        {
            chomp;
            @tmp = split;
            if( $tmp[0] =~ /^\//)
            {
                if( !-e "$tmp[0]")
                {
                    print "Error: Data $tmp[0] not exist!\n";
                    exit -1;
                }
                if( !-e "$tmp[0]")
                {
                    `ln -s $tmp[0] $outdir/filter/`;
                }
            }
            else
            {
                if( !-e "$outdir/data/$tmp[0]")
                {
                    print "Error: Data $outdir/data/$tmp[0] not exist!\n";
                    exit -1;
                }
                if( !-e "$outdir/filter/$tmp[0]")
                {
                    `ln -s $outdir/data/$tmp[0] $outdir/filter/`;
                }
            }
        }
        close IN;
    }
    `cp $lanelist $liblist $outdir/filter/`;

    open OUT, ">$outdir/filter/filter.sh" or die "fail open file $outdir/filter/filter.sh\n";
    
    my $background = 0;
    if(defined($filterpara))
    {
        print OUT "perl $progdir/makeSH.pl $filterpara $lanelist $liblist 1>filter.out 2>>filter.err\n";
        
        @tmp = split(/\s+/, $filterpara);
        foreach(@tmp)
        {
            if($_ eq "-b")
            {
                $background = 1;
            }
        }
    }
    else
    {
        print OUT "perl $progdir/makeSH.pl $lanelist $liblist 1>filter.out 2>>filter.err\n";
    }
    print OUT "perl $checkfile --err $err --step filter\n";
    print OUT "if [ \$? != 0 ]\nthen\necho \"Error in makeSH.pl!\";\nexit -1;\nfi\n";

    print OUT "nohup time sh lane.lst.filter.sh 1>>filter.out 2>>filter.err&\n";
    print OUT "sleep 2;\n";
    
    if($background)
    {
        print OUT "rm *.log -f; pstree -pa \$! | perl -e \'{while(\$t=<>){if(\$t=~/-f.+,(\\d+)/){system(\"perl $estimate $estpara -O \$1.log -P \$1 \&\");}}}\'\n";
    }
    else
    {
        print OUT "rm *.log -f;\na=\`pstree -pa \$!\`\n";
        print OUT "while [ -n \"\$a\" ]\ndo\nperl $estimate $estpara -O filter.log -P \`pstree -pa \$! | perl -e \'{while(\$t=<>){if(\$t=~/-f.+,(\\d+)/){print \$1;}}}\'\`\na=\`pstree -pa \$!\`\ndone\n";
    }
    
    print OUT "wait\n";

    print OUT "if [ \$? != 0 ]\nthen\necho \"Error in lane.lst.filter.sh\";\nexit -1;\nfi\n";

    print OUT "perl $checkfile --err $err --step filter\n";
    print OUT "if [ \$? != 0 ]\nthen\necho \"Error in lane.lst.filter.sh!\";\nexit -1;\nfi\n";

    close OUT;

    $stat = system("cd $outdir/filter; sh filter.sh 2>$err; cd $outdir");

    if($stat != 0)
    {
        print "Error in filter step!\n";
        exit -1;
    }
}

if($stop <= 1)
{
    print "Stop at step $stop\n";
    exit;
}

#step 2: kmerfreq
if($step <= 2 && $stop >= 2)
{
    if( !defined($kmerfreq) || !defined($kmerfreqpara) )
    {
        print "The profile of kmerfreq is not well defined\n";
        exit -1;
    }
    if( !-d "$outdir/correction" )
    {
        `mkdir $outdir/correction`;
    }
    `rm $outdir/correction/kmerfreq.sh -f`;
    
    `cp lib.lst $outdir/`;

    if( !-s "$outdir/lib.lst" )
    {
        print "The $outdir/lib.lst does not exist!\n";
        exit -1;
    }
    else
    {
        open IN, "$outdir/lib.lst" or die "fail open file $outdir/lib.lst\n";
        while(<IN>)
        {
            chomp;
            @tmp = split;
            if( !-e "$outdir/filter/$tmp[0]")
            {
                print "Error: dir $outdir/filter/$tmp[0] not exist!\n";
                exit -1;
            }
            if( !-d "$outdir/correction/$tmp[0]" )
		{
			`mkdir $outdir/correction/$tmp[0]`;
		}
#            `ln -s $outdir/filter/$tmp[0]/*.clean.gz $outdir/correction/$tmp[0]`;
            `ln -s $outdir/filter/$tmp[0]/*.clean $outdir/correction/$tmp[0]`;
        }
        close IN;
    }

#    `cd $outdir/correction/; ls */*.clean.gz > read.lst cd $outdir`;
    `cp read.lst $outdir/correction/`;

    open OUT, ">$outdir/correction/kmerfreq.sh" or die "fail open file $outdir/correction/kmerfreq.sh\n";
    
    print OUT "nohup time $progdir/$kmerfreq $kmerfreqpara 1>kmerfreq.out 2>kmerfreq.err &\n";
    
    print OUT "sleep 2;\n";
    
    print OUT "if [ ! \`pstree -pa \$! | perl -e \'{<>;\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\` ]\nthen\nkill \`pstree -pa \$! | perl -e \'{\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\`;\necho \"The id is not found, please check that job is killed!\";\nexit -1;\nfi\n";
    print OUT "rm kmerfreq.log -f; perl $estimate $estpara -O kmerfreq.log -P \`pstree -pa \$! | perl -e \'{while(\$t=<>){\$p=substr(\"$kmerfreq\", 0, 3);\$r=\"\\\`-\$p.+,(\\\\\\\\d+)\";if(\$t=~/\$r/){print \$1;}}}\'\`\n";
    print OUT "perl $checkfile --err $err --step kmerfreq\n";
    print OUT "if [ \$? != 0 ]\nthen\necho \"Error in kmerfreq!\";\nexit -1;\nfi\n";
    
    close OUT;

    $stat = system("cd $outdir/correction; sh kmerfreq.sh 2>$err; cd $outdir");

    if($stat != 0)
    {
        print "Error in kmerfreq step!\n";
        exit -1;
    }
}

if($stop <= 2)
{
    print "Stop at step $stop\n";
    exit;
}

#step 3: error correction
if($step <= 3 && $stop >= 3)
{
    if( !defined($correction) || !defined($correctpara) )
    {
        print "The profile of error correction is not well defined\n";
        exit -1;
    }
    
    `rm $outdir/correction/correction.sh -f`;

    if( !-d "$outdir/correction" )
    {
        print "Please run step 2(kmerfreq) first!\n";
        exit -1;
    }

    open OUT, ">$outdir/correction/correction.sh" or die "fail open file $outdir/correction/correction.sh\n";

    print OUT "nohup time $progdir/$correction $correctpara 1>>correction.out 2>>correction.err &\n";
    print OUT "sleep 2;\n";
    print OUT "if [ ! \`pstree -pa \$! | perl -e \'{<>;\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\` ]\nthen\nkill \`pstree -pa \$! | perl -e \'{\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\`;\necho \"The id is not found, please check that job is killed!\";\nexit -1;\nfi\n";
    print OUT "rm correction.log -f; perl $estimate $estpara -O correction.log -P \`pstree -pa \$! | perl -e \'{while(\$t=<>){\$p=substr(\"$correction\", 0, 3);\$r=\"\\\`-\$p.+,(\\\\\\\\d+)\";if(\$t=~/\$r/){print \$1;}}}\'\`\n";
    print OUT "perl $checkfile --err $err --step correct\n";
    print OUT "if [ \$? != 0 ]\nthen\necho \"Error in correct!\";\nexit -1;\nfi\n";

    if(defined($mergepair) && defined($mergelist))
    {
        `cp $mergelist $outdir/correction/`;
        print OUT "perl $progdir/$mergepair $mergelist\n";
        print OUT "if [ \$? != 0 ]\nthen\necho \"Error in correct!\";\nexit -1;\nfi\n";
    }

    close OUT;

    $stat = system("cd $outdir/correction; sh correction.sh 2>$err; cd $outdir");
   
    if($stat != 0)
    {
        print "Error in correction step!\n";
        exit -1;
    }
}

if($stop <= 3)
{
    print "Stop at step $stop\n";
    exit;
}

if(defined($all) && $all ne "")
{
    @tmp = split(/\s+/, $all);
}
else
{
    @tmp = split(/\s+/, $pregraph);
}

$prefix="";
$config="";
my $prev="";
foreach(@tmp)
{
    if($prev eq "-o")
    {
        $prefix = $_;
    }
    if($prev eq "-s")
    {
        $config = $_;
    }
    $prev = $_;
}

if($prefix eq "" || $config eq "")
{
    print "Error: output prefix or config file not set!\n";
    exit -1;
}

if(!defined($estpara))
{
    print "Error: parameter of estimate script is missing!\n";
    exit -1;
}

#step 4-7: assembly
if($step <= 7 && $stop >= 4)
{
    if(!defined($SOAPdenovo) || (!defined($all) && (!defined($pregraph) || !defined($contig) || !defined($map) || !defined($scaff))))
    {
        print "The profile of assembly is not well defined, parameter of assembly part missing\n";
        exit -1;
    }

    if( !-d "$outdir/assembly" )
    {
        `mkdir $outdir/assembly`;
    }
    
    my $name = $SOAPdenovo;
    my $namesparse;

    $SOAPdenovo = $progdir.$SOAPdenovo;
    if(defined($sparse))
    {
        $namesparse = $sparse;
        $sparse = $progdir.$sparse;
    }
    
    `rm $outdir/assembly/assembly.sh -f`;
    
    `cp $config $outdir/assembly/`;
    
    open OUT, ">$outdir/assembly/assembly.sh" or die "fail open file $outdir/assembly/assembly.sh\n";

    if(defined($all) && $all ne "")
    {
        print OUT "if [ -s $config ]\nthen\necho \"Start to assemble...\";\nelse\necho \"No config file or empty!\";\nexit -1;\nfi\n";
        print OUT "rm $err -f;nohup time $SOAPdenovo all $all 1>all.out 2>all.err &\n";
        print OUT "sleep 2;\n";
        print OUT "if [ ! \`pstree -pa \$! | perl -e \'{<>;\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\` ]\nthen\nkill \`pstree -pa \$! | perl -e \'{\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\`;\necho \"The id is not found, please check that job is killed!\";\nexit -1;\nfi\n";
        print OUT "rm all.log -f; perl $estimate $estpara -O all.log -P \`pstree -pa \$! | perl -e \'{while(\$t=<>){\$p=substr(\"$name\", 0, 3);\$r=\"\\\`-\$p.+,(\\\\\\\\d+)\";if(\$t=~/\$r/){print \$1;last;}}}\'\`\n";
        print OUT "perl $checkfile --prefix $prefix --err $err --step all\n";
        print OUT "if [ \$? != 0 ]\nthen\necho \"Error in SOAPdenovo(all)!\";\nexit -1;\nfi\n";
    }
    else
    {
        if($step <= 4 && $stop >= 4)
        {
            if(defined($sparse))
            {
                print OUT "if [ -s $config ]\nthen\necho \"Start to assemble...\";\nelse\necho \"No config file or empty!\";\nexit -1;\nfi\n";
                print OUT "rm $err -f;nohup time $sparse $pregraph 1>pregraph.out 2>pregraph.err &\n";
                print OUT "sleep 2;\n";
                print OUT "if [ ! \`pstree -pa \$! | perl -e \'{<>;\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\` ]\nthen\nkill \`pstree -pa \$! | perl -e \'{\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\`;\necho \"The id is not found, please check that job is killed!\";\nexit -1;\nfi\n";
                print OUT "rm pregraph.log -f; perl $estimate $estpara -O pregraph.log -P \`pstree -pa \$! | perl -e \'{while(\$t=<>){\$p=substr(\"$namesparse\", 0, 3);\$r=\"\\\`-\$p.+,(\\\\\\\\d+)\";if(\$t=~/\$r/){print \$1;last;}}}\'\`\n";
                print OUT "perl $checkfile --prefix $prefix --err $err --step pregraph\n";
                print OUT "if [ \$? != 0 ]\nthen\necho \"Error in pregraph!\";\nexit -1;\nfi\n";
            }
            else
            {
                print OUT "if [ -s $config ]\nthen\necho \"Start to assemble...\";\nelse\necho \"No config file or empty!\";\nexit -1;\nfi\n";
                print OUT "rm $err -f;nohup time $SOAPdenovo pregraph $pregraph 1>pregraph.out 2>pregraph.err &\n";
                print OUT "sleep 2;\n";
                print OUT "if [ ! \`pstree -pa \$! | perl -e \'{<>;\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\` ]\nthen\nkill \`pstree -pa \$! | perl -e \'{\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\`;\necho \"The id is not found, please check that job is killed!\";\nexit -1;\nfi\n";
                print OUT "rm pregraph.log -f; perl $estimate $estpara -O pregraph.log -P \`pstree -pa \$! | perl -e \'{while(\$t=<>){\$p=substr(\"$name\", 0, 3);\$r=\"\\\`-\$p.+,(\\\\\\\\d+)\";if(\$t=~/\$r/){print \$1;last;}}}\'\`\n";
                print OUT "perl $checkfile --prefix $prefix --err $err --step pregraph\n";
                print OUT "if [ \$? != 0 ]\nthen\necho \"Error in pregraph!\";\nexit -1;\nfi\n";
            }
        }
        elsif($step == 5 && $stop >= 5)
        {
            print OUT "perl $checkfile --prefix $prefix --err $err --step pregraph\n";
            print OUT "if [ \$? != 0 ]\nthen\necho \"Error in pregraph!\";\nexit -1;\nfi\n";
        }
        if($step <= 5 && $stop >= 5)
        {
            print OUT "rm $err -f;nohup time $SOAPdenovo contig $contig 1>contig.out 2>contig.err &\n";
            print OUT "sleep 2;\n";
            print OUT "if [ ! \`pstree -pa \$! | perl -e \'{<>;\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\` ]\nthen\nkill \`pstree -pa \$! | perl -e \'{\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\`;\necho \"The id is not found, please check that job is killed!\";\nexit -1;\nfi\n";
            print OUT "rm contig.log -f; perl $estimate $estpara -O contig.log -P \`pstree -pa \$! | perl -e \'{while(\$t=<>){\$p=substr(\"$name\", 0, 3);\$r=\"\\\`-\$p.+,(\\\\\\d+)\";if(\$t=~/\$r/){print \$1;last;}}}\'\`\n";
            print OUT "perl $checkfile --prefix $prefix --err $err --step contig\n";
            print OUT "if [ \$? != 0 ]\nthen\necho \"Error in contig!\";\nexit -1;\nfi\n";
        }
        elsif($step == 6 && $stop >= 6)
        {
            print OUT "perl $checkfile --prefix $prefix --err $err --step contig\n";
            print OUT "if [ \$? != 0 ]\nthen\necho \"Error in contig!\";\nexit -1;\nfi\n";
        }
        if($step <= 6 && $stop >= 6)
        {
            if(defined($map1))
            {
                my $long;
                my $short;
                $long="";
                $short="";
                $prev="";
                @tmp = split(/\s+/, $map);
                foreach(@tmp)
                {
                    if($prev eq "-s")
                    {
                        $long = $_;
                    }
                    $prev = $_;
                }
                @tmp = split(/\s+/, $map1);
                foreach(@tmp)
                {
                    if($prev eq "-s")
                    {
                        $short = $_;
                    }
                    $prev = $_;
                }

                if($long eq "" || $short eq "")
                {
                    print "Error: config file not set of map!\n";
                    exit -1;
                }
		
		$long = $progdir.$long;
		$short = $progdir.$short;
		
                if( !-d "$outdir/assembly/map1" )
                {
                    `mkdir $outdir/assembly/map1`;
                }
                if( !-d "$outdir/assembly/map2" )
                {
                    `mkdir $outdir/assembly/map2`;
                }

                print OUT "cd $outdir/assembly/map1; ln -s $outdir/assembly/$prefix.contig $outdir/assembly/$prefix.ContigIndex $outdir/assembly/$prefix.preGraphBasic .;cd $outdir/assembly/\n";
		print OUT "cd $outdir/assembly/map2; ln -s $outdir/assembly/$prefix.contig $outdir/assembly/$prefix.ContigIndex $outdir/assembly/$prefix.preGraphBasic .;cd $outdir/assembly/\n";
                
                `cp $long $outdir/assembly/map1/`;
                `cp $short $outdir/assembly/map2/`;
                
                open OUT1, ">$outdir/assembly/map1/map.sh" or die "fail open file $outdir/assembly/map1/map.sh\n";

                print OUT1 "rm $err -f;nohup time $SOAPdenovo map $map 1>map.out 2>map.err &\n";
                print OUT1 "sleep 2;\n";
                print OUT1 "if [ ! \`pstree -pa \$! | perl -e \'{<>;\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\` ]\nthen\nkill \`pstree -pa \$! | perl -e \'{\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\`;\necho \"The id is not found, please check that job is killed!\";\nexit -1;\nfi\n";
                print OUT1 "rm map.log -f; perl $estimate $estpara -O map.log -P \`pstree -pa \$! | perl -e \'{while(\$t=<>){\$p=substr(\"$name\", 0, 3);\$r=\"\\\`-\$p.+,(\\\\\\\\d+)\";if(\$t=~/\$r/){print \$1;last;}}}\'\`\n";
                print OUT1 "perl $checkfile --prefix $prefix --err $err --step map\n";
                print OUT1 "if [ \$? != 0 ]\nthen\necho \"Error in map!\";\nexit -1;\nfi\n";
                
                close OUT1;

                open OUT1, ">$outdir/assembly/map2/map.sh" or die "fail open file $outdir/assembly/map2/map.sh\n";

                print OUT1 "rm $err -f;nohup time $SOAPdenovo map $map1 1>map.out 2>map.err &\n";
                print OUT1 "sleep 2;\n";
                print OUT1 "if [ ! \`pstree -pa \$! | perl -e \'{<>;\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\` ]\nthen\nkill \`pstree -pa \$! | perl -e \'{\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\`;\necho \"The id is not found, please check that job is killed!\";\nexit -1;\nfi\n";
                print OUT1 "rm map.log -f; perl $estimate $estpara -O map.log -P \`pstree -pa \$! | perl -e \'{while(\$t=<>){\$p=substr(\"$name\", 0, 3);\$r=\"\\\`-\$p.+,(\\\\\\\\d+)\";if(\$t=~/\$r/){print \$1;last;}}}\'\`\n";
                print OUT1 "perl $checkfile --prefix $prefix --err $err --step map\n";
                print OUT1 "if [ \$? != 0 ]\nthen\necho \"Error in map!\";\nexit -1;\nfi\n";
                
                close OUT1;

                print OUT "cd $outdir/assembly/map1; sh map.sh; cd $outdir/assembly/ \n";
                print OUT "if [ \$? != 0 ]\nthen\necho \"Error in map1!\";\nexit -1;\nfi\n";
                print OUT "cd $outdir/assembly/map2; sh map.sh; cd $outdir/assembly/ \n";
                print OUT "if [ \$? != 0 ]\nthen\necho \"Error in map2!\";\nexit -1;\nfi\n";

                print OUT "$progdir/mergeReadInGap -a map1/$prefix.readInGap.gz -b map2/$prefix.readInGap.gz >merge.log\n";
                print OUT "if [ \$? != 0 ]\nthen\necho \"Error in map!\";\nexit -1;\nfi\n";
                print OUT "$progdir/mergeReadOnCtg -a map1/$prefix.readOnContig.gz -b map2/$prefix.readOnContig.gz -n \`perl -e \'{\@t;while(<>){chomp;\@t=split;if(/^Total reads/){print \$t[2]; last;}}}\' map1/map.err\`\n";
                print OUT "if [ \$? != 0 ]\nthen\necho \"Error in map!\";\nexit -1;\nfi\n";

                print OUT "perl $progdir/mergePE.pl --map1 map1/$prefix.peGrads --map2 map2/$prefix.peGrads --cfg $config --out $prefix.peGrads\n";

                print OUT "cd $outdir/assembly/; ln -s $outdir/assembly/map1/$prefix.readInGap.gz .\n";
		print OUT "cd $outdir/assembly/; ln -s $outdir/assembly/map1/$prefix.readOnContig.gz .\n";
            }
            else
            {
                print OUT "rm $err -f;nohup time $SOAPdenovo map $map 1>map.out 2>map.err &\n";
                print OUT "sleep 2;\n";
                print OUT "if [ ! \`pstree -pa \$! | perl -e \'{<>;\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\` ]\nthen\nkill \`pstree -pa \$! | perl -e \'{\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\`;\necho \"The id is not found, please check that job is killed!\";\nexit -1;\nfi\n";
                print OUT "rm map.log -f; perl $estimate $estpara -O map.log -P \`pstree -pa \$! | perl -e \'{while(\$t=<>){\$p=substr(\"$name\", 0, 3);\$r=\"\\\`-\$p.+,(\\\\\\\\d+)\";if(\$t=~/\$r/){print \$1;last;}}}\'\`\n";
                print OUT "perl $checkfile --prefix $prefix --err $err --step map\n";
                print OUT "if [ \$? != 0 ]\nthen\necho \"Error in map!\";\nexit -1;\nfi\n";
            }
        }
        elsif($step == 7 && $stop >= 7)
        {
            print OUT "perl $checkfile --prefix $prefix --err $err --step map\n";
            print OUT "if [ \$? != 0 ]\nthen\necho \"Error in map!\";\nexit -1;\nfi\n";
        }
        if($stop >= 7)
        {
            print OUT "rm $err -f;nohup time $SOAPdenovo scaff $scaff 1>scaff.out 2>scaff.err &\n";
            print OUT "sleep 2;\n";
            print OUT "if [ ! \`pstree -pa \$! | perl -e \'{<>;\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\` ]\nthen\nkill \`pstree -pa \$! | perl -e \'{\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\`;\necho \"The id is not found, please check that job is killed!\";\nexit -1;\nfi\n";
            print OUT "rm scaff.log -f; perl $estimate $estpara -O scaff.log -P \`pstree -pa \$! | perl -e \'{while(\$t=<>){\$p=substr(\"$name\", 0, 3);\$r=\"\\\`-\$p.+,(\\\\\\\\d+)\";if(\$t=~/\$r/){print \$1;last;}}}\'\`\n";
            print OUT "perl $checkfile --prefix $prefix --err $err --step scaff\n";
            print OUT "if [ \$? != 0 ]\nthen\necho \"Error in scaff!\";\nexit -1;\nfi\n";
        }
    }
    close OUT;

    $stat = system("cd $outdir/assembly; sh assembly.sh 2>$err; cd $outdir");

    if($stat != 0)
    {
        print "Error in assembly step!\n";
        exit -1;
    }
}

if($stop <= 7)
{
    print "Stop at step $stop\n";
    exit;
}

#step 8: gapcloser
if($step <= 8 && $stop >= 8)
{
    if( defined($kgf) )
    {
	$kgf = $progdir.$kgf;
	if( !-d "$outdir/kgf" )
	{
	    `mkdir $outdir/kgf`;
	}

	`rm -rf $outdir/kgf/*`;

	open OUT, ">$outdir/kgf/kgf.sh" or die "fail open file $outdir/kgf/kgf.sh\n";
	if( !defined $kgfpara )
	{
	    print "Parameters for kgf is not provided.\n";
	    exit -1;
	}
	print OUT "nohup time perl $kgf --dir $outdir/assembly $kgfpara >kgf.log";
        print OUT "sleep 2;\n";
        print OUT "if [ ! \`pstree -pa \$! | perl -e \'{<>;\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\` ]\nthen\nkill \`pstree -pa \$! | perl -e \'{\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\`;\necho \"The id is not found, please check that job is killed!\";\nexit -1;\nfi\n";
        print OUT "rm kgf.log -f; perl $estimate $estpara -O kgf.log -P \`pstree -pa \$! | perl -e \'{<>;\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\`\n";
        print OUT "perl $checkfile --prefix $prefix --err $err --step kgf\n";
        print OUT "if [ \$? != 0 ]\nthen\necho \"Error in kgf!\";\nexit -1;\nfi\n";

	close OUT;


	$stat = system("cd $outdir/kgf; sh kgf.sh 2>err; cd $outdir");
        if($stat != 0)
        {
            print "Error in kgf step!\n";
            exit -1;
        }
    }

    if( !defined($gapcloser) )
    {
        $gapcloser = "GapCloser";
    }
    if( !defined($gapcfg) )
    {
        $gapcfg = $config;
    }
    
    if( !-d "$outdir/gapcloser" )
    {
        `mkdir $outdir/gapcloser`;
    }

    $gapcloser = $progdir.$gapcloser;
    `rm $outdir/gapcloser/gapcloser.sh -f`;

    `cp $gapcfg $outdir/gapcloser/`;
    
    if( !-s "$outdir/gapcloser/$prefix.scafSeq" )
    {
	if( !defined $kgf )
	{
            `ln -s $outdir/assembly/$prefix.scafSeq $outdir/gapcloser/`;
	}
	else
	{
	    `ln -s $outdir/kgf/SRkgf/step_2/$prefix.scafSeq.fill $outdir/gapcloser/`;
	}
    }
    
    open OUT, ">$outdir/gapcloser/gapcloser.sh" or die "fail open file $outdir/gapcloser/gapcloser.sh\n";

    if($step == 8)
    {
	if ( !defined $kgf )
	{
            print OUT "perl $checkfile --prefix $prefix --err $err --step scaff\n";
            print OUT "if [ \$? != 0 ]\nthen\necho \"Error in scaff!\";\nexit -1;\nfi\n";
	}
	else
	{
	    print OUT "perl $checkfile --prefix $prefix --err $err --step kgf\n";
	    print OUT "if [ \$? != 0 ]\nthen\necho \"Error in kgf !\";\nexit -1;\nfi\n";
	}
    }

    if(!defined($gappara))
    {
        print OUT "nohup time $gapcloser -a $prefix.scafSeq -b $gapcfg -o $prefix.scafSeq.GC >gapcloser.out 2>gapcloser.err &\n";
    }
    elsif ( !defined $kgf )
    {
        print OUT "nohup time $gapcloser -a $prefix.scafSeq -b $gapcfg $gappara -o $prefix.scafSeq.GC >gapcloser.out 2>gapcloser.err &\n";
    }
    else
    {
	print OUT "nohup time $gapcloser -a $prefix.scafSeq.fill -b $gapcfg $gappara -o $prefix.scafSeq.GC >gapcloser.out 2>gapcloser.err &\n";
    }

    print OUT "sleep 2;\n";
    print OUT "if [ ! \`pstree -pa \$! | perl -e \'{<>;\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\` ]\nthen\nkill \`pstree -pa \$! | perl -e \'{\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\`;\necho \"The id is not found, please check that job is killed!\";\nexit -1;\nfi\n";
    print OUT "rm gapcloser.log -f; perl $estimate $estpara -O gapcloser.log -P \`pstree -pa \$! | perl -e \'{<>;\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\`\n";
    print OUT "perl $checkfile --prefix $prefix --err $err --step gapcloser\n";
    print OUT "if [ \$? != 0 ]\nthen\necho \"Error in gapcloser!\";\nexit -1;\nfi\n";

    close OUT;
    
    $stat = system("cd $outdir/gapcloser; sh gapcloser.sh 2>$err; cd $outdir");

    if($stat != 0)
    {
        print "Error in gapcloser step!\n";
        exit -1;
    }
}

if($stop <= 8)
{
    print "Stop at step $stop\n";
    exit;
}

#step 9: filter contamination
if($step <=9 && $stop >= 9)
{
    if( !defined($blast) || !defined($blastpara) )
    {
	print "program or parameter of blast is not defined!\n";
	exit -1;
    }

    if( !-d "$outdir/filterContamination" )
    {
	`mkdir $outdir/filterContamination`;
    }

    `rm $outdir/filterContamination/* -rf`;
    if( !-s "$outdir/filterContamination/$prefix.scafSeq.GC" )
    {
	`ln -s $outdir/gapcloser/$prefix.scafSeq.GC $outdir/filterContamination/`;
    }

    `cp $progdir/rmBacteria.pl $outdir/filterContamination/`;
    `cp $progdir/filterBacteria.pl $outdir/filterContamination/`;

    open OUT, ">$outdir/filterContamination/filterContamination.sh" or die "fail open file $outdir/filterContamination.sh\n";

    $blast = $progdir.$blast;
    if( $blastpara =~ /-d (\S+)/ )
    {
	if( !-s $1)
	{
	    print "Bacteria sequence database does NOT exist!\nPlease set one for \"blastpara\" in profile file.\n";
	    exit -1;
	}
    }
    else
    {
	print "Bacteria sequence database was not specified!\nPlease set one for \"blastpara\" in profile file.\n";
	exit -1;
    }
    print OUT "nohup time $blast $blastpara >blast.out 2>blast.err\n";
    print OUT "sleep 2;\n";
    print OUT "if [ ! \`pstree -pa \$! | perl -e \'{<>;\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\` ]\nthen\nkill \`pstree -pa \$! | perl -e \'{\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\`;\necho \"The id is not found, please check that job is killed!\";\nexit -1;\nfi\n";
    print OUT "rm blast.log -f; perl $estimate $estpara -O blast.log -P \`pstree -pa \$! | perl -e \'{<>;\$t=<>;if(\$t=~/,(\\d+)/){print \$1;}}\'\`\n";
    print OUT "ls $prefix.scafSeq.GC.blastall.out >blast.result\n";
    print OUT "perl rmBacteria.pl blast.result >rmBacteria.log 2>rmBacteria.err\n";
    print OUT "perl filterBacteria.pl total.list speciesA.scafSeq.GC >>rmBacteria.log 2>>rmBacteria.err\n";
    print OUT "perl $checkfile --prefix $prefix --err $err --step filtercont\n";
    print OUT "if [ \$? != 0 ]\nthen\necho \"Error in filter contamination!\";\nexit -1;\nfi\n";

    close OUT;

    $stat = system("cd $outdir/filterContamination; sh filterContamination.sh 2>$err; cd $outdir");

    if($stat != 0)
    {
	print "Error in filter contamination step!\n";
	exit -1;
    }
}

#step 10: consensus
if($step <= 10 && $stop >= 10)
{
    if( !defined($align) || !defined($is13) )
    {
        print "The profile of consensus is not well defined\n";
        exit -1;
    }

    if(!defined($concfg))
    {
        $concfg = $config;
    }

    if( !-d "$outdir/consensus" )
    {
        `mkdir $outdir/consensus`;
    }
    `rm $outdir/consensus/* -rf`;
    
    `cp $concfg $outdir/consensus/`;

    if( !-s "$outdir/consensus/$prefix.scafSeq.GC.filter" )
    {
        `ln -s $outdir/filterContamination/$prefix.scafSeq.GC.filter $outdir/consensus/`;
    }
    `cp $progdir/tools/* $outdir/consensus/`;
    
    open OUT, ">$outdir/consensus/consensus.sh" or die "fail open file $outdir/consensus/consensus.sh\n";

    if($step == 10)
    {
        print OUT "perl $checkfile --prefix $prefix --err $err --step filtercont\n";
        print OUT "if [ \$? != 0 ]\nthen\necho \"Error in filter contamination!\";\nexit -1;\nfi\n";
    }
    #bwa samtools 2bwt-builder BGS-Build 
    print OUT "nohup time perl $outdir/consensus/consensusStep1.pl $outdir/consensus/$concfg $outdir/consensus/$prefix.scafSeq.GC.filter $align $is13 1>consensus.out 2>consensus.err &\n";
    print OUT "sleep 2;\n";
    print OUT "rm step1.log -f;\na=\`pstree -pa \$!\`\n";
    print OUT "while [ -n \"\$a\" ]\ndo\nperl $estimate $estpara -O step1.log -P \`pstree -pa \$! | perl -e \'{while(\$t=<>){if(\$t=~/-[bs2B][wabG].+,(\\d+)/){print \$1;}}}\'\`\na=\`pstree -pa \$!\`\ndone\n";
    print OUT "if [ \$? != 0 ]\nthen\necho \"Error in consensusStep1.pl\";\nexit -1;\nfi\n";
    
    #bwa samtools soap3-dp
    print OUT "nohup time sh $outdir/consensus/align.sh 1>>consensus.out 2>>consensus.err &\n";
    print OUT "sleep 2;\n";
    print OUT "a=\`pstree -pa \$!\`\n";
    print OUT "while [ -n \"\$a\" ]\ndo\nb=\`pstree -pa \$! | perl -e \'{while(\$t=<>){if(\$t=~/-[bs][wao].+,(\\d+)/){print \$1;last;}}}\' -\`\npstree -pa \$! | perl -e \'{while(\$t=<>){if(\$t=~/-[bs][wao].+,(\\d+)/){system(\"perl $estimate $estpara -O \$1.log -P \$1 &\");}}}\'\nc=\`pstree -pa \$! | grep \$b -\`\nwhile [ -n \"\$c\" ]\ndo\nsleep 1m\nc=\`pstree -pa \$! | grep \$b -\`\ndone\na=\`pstree -pa \$!\`\ndone\n";
    print OUT "if [ \$? != 0 ]\nthen\necho \"Error in align.sh\";\nexit -1;\nfi\n";
    
    #bcftools samtools java perl vcfutils.pl perl genEFASTAbyVCF.pl perl modSeqbyVCF.pl 
    print OUT "nohup time perl $outdir/consensus/consensusStep2.pl $outdir/consensus/$concfg $outdir/consensus/$prefix.scafSeq.GC.filter 1>>consensus.out 2>>consensus.err &\n";
    print OUT "sleep 2;\n";
    print OUT "a=\`pstree -pa \$!\`\n";
    print OUT "while [ -n \"\$a\" ]\ndo\nb=\`pstree -pa \$! | perl -e \'{while(\$t=<>){if(\$t=~/-[bsj][ca].+,(\\d+)/ || \$t=~/,(\\d+).*vcf/ || \$t=~/,(\\d+).*gen/ || \$t=~/,(\\d+).*mod/){print \$1;last;}}}\' -\`\npstree -pa \$! | perl -e \'{while(\$t=<>){if(\$t=~/-[bsj][ca].+,(\\d+)/ || \$t=~/,(\\d+).*vcf/ || \$t=~/,(\\d+).*gen/ || \$t=~/,(\\d+).*mod/){system(\"perl $estimate $estpara -O \$1.log -P \$1 &\");}}}\'\nc=\`pstree -pa \$! | grep \$b -\`\nwhile [ -n \"\$c\" ]\ndo\nsleep 1m\nc=\`pstree -pa \$! | grep \$b -\`\ndone\na=\`pstree -pa \$!\`\ndone\n";
    print OUT "if [ \$? != 0 ]\nthen\necho \"Error in consensusStep2.pl\";\nexit -1;\nfi\n";
    print OUT "perl $checkfile --prefix $prefix --err $err --step consensus\n";
    print OUT "if [ \$? != 0 ]\nthen\necho \"Error in consensus!\";\nexit -1;\nfi\n";

    close OUT;
    
    $stat = system("cd $outdir/consensus; sh consensus.sh 2>$err; cd $outdir");
    
    if($stat != 0)
    {
       print "Error in consensus step!\n";
       exit -1;
    }
}

if($stop <= 10)
{
    print "Stop at step $stop\n";
    exit;
}

print "Finish!\n";

