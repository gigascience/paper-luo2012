#!/usr/bin/perl

=head1 Description

        This pipeline is to use kgf to fill gaps. kgf is a new gap filling program, based on PE reads and gap edge related reads. All the reads assembled by overlap method. This pipeline contains collecting gap related reads, reads filter, gap filling gap analysis, filling gaps  and filling result analysis.
	To get gap related reads, there are two choise. You can use krs to map sequencing reads to raw scaffold sequences, or use SOAPdenovo reads mapping result. This pipeline is used to get reads from SOAPdenovo map results.

=head1 Contact and Version
        Contact: Assemble Development Team(ADT).
        Version: 1.19 
        Date: 2012.3.23

=head1 Usage
  
  	perl SRKGF.pl [options]
  	basical argument:
  	--outdir	<str>	set the output directory. for all steps , no default.
  	--step		<int>	set pipeline running steps. 1: get gap read from grape assemble result.2: contig gap filling 3: fill result analysis. default=123.
  	--thread	<int>	set thread number for kgf gap filling, default=8. for step 12.
	
	step 1 argument:
	--dir		<str>	set SOAPdenovo working directory, reading file: *.scaf, *.scafSeq, *.contig , *.shortreadInGap(.gz), *.PEreadOnContig(.gz), *.RlongReadInGap(.gz) , for step 1
  	--kmer		<int>	set kmer size used in SOAPdenovo. default 31 .  for step 1
  	--prefix	<str>	set prefix used by SOAPdenovo for step 1
  	--scaf		<str>	set scaffold sequence. for step 1
  	--cvg		<int>	set the average coverage depth of contig , usually be found in scaff.log. for step 1.
  	--shortcontig	<int>	set contig length cutoff, when contigs less than it, the contigs will be masked into gap. default 100 - (kmersize). for step 1.
  	--falsecontig	<int>	when contigs less than it and related gap length is One, the shorter contig will be masked into gap. default 150.for step 1. 
  	
	step 2 argument:
  	--contig	<str>	set *.SCAF.contig sequence generate by step1 . for step 2
  	--gapread	<str>	set gap reads. for step 2
  	--cpu		<int>	set scaffolds cut number for kgf gapfilling step, default=4. for step 2.
	
	qsub argument:
	--P		<str>   set the qsub -P , must be set if qsub the work script , No default(user can custom by modifying the variant $P ) .
  	--queue		<str>	set the queue for qsub jobs . no default.
  	--noqsub 	<...>   set when user need to run the scripts local ,default qsub .	
  	
	--verbose  	 	output verbose information to screen  
  	--help      		output help information to screen

=head1 example
perl path/SRKGF.pl --dir path/SOAPdenovo_output_dir  --outdir path/SRKGF_output_dir --prefix SOAPdenovo_file_prefix --kmer SOAPdenovo_Kmer_set --cvg contig_coverage --cpu directory_num_for_kgf --thread kgf_thread  --step 123  --queue  compute_node.q --P Project 

=head1 
perl ./SRKGF.pl --dir /path/02.assemble/  --outdir /path/gap_fill/SRkgf/  --prefix test --kmer 31 --cvg 25 --cpu 8 --thread 8 --step 123 . --queue all.q --P Project

=head1 
more example see Pipe_dir/example.sh . 

=cut

use strict;
use Getopt::Long;
use File::Basename ;
use Data::Dumper;
use FindBin qw($Bin);

my ($path,$path2,$kgf2) = ("$Bin/stat2","$Bin/SR2","$Bin/kgf1.19");

my ($scafSeq,$lib_file,$contig_file,$gapread_file,$dir,$prefix,$IsGz,$noqsub,$Queue,$P);
my ($cpu,$step,$iter, $Help, $Outdir, $Verbose, $thread, $startid,$scafnum, $kvf, $len, $vf, $kmer,$cvg,$contigcutoff1,$contigcutoff2,$longread,$update_file,$new_index);
GetOptions(
	"scaf:s"=>\$scafSeq,
	"dir:s"=>\$dir,
	"prefix:s"=>\$prefix,
	"contig:s"=>\$contig_file,
	"gapread:s"=>\$gapread_file,
	"kmer:i"=>\$kmer,
	"cvg:i"=>\$cvg,
	"cpu:i"=>\$cpu,
	"vf:s"=>\$kvf,
	"step:i"=>\$step,
	"thread:i"=>\$thread,
	"shortcontig:i"=>\$contigcutoff1,
	"falsecontig:i"=>\$contigcutoff2,
	"outdir:s"=>\$Outdir,
	"queue:s"=>\$Queue,
	"P:s"=>\$P,
	"noqsub!"=>\$noqsub,
	"verbose"=>\$Verbose,
	"help"=>\$Help
);

#$Outdir ||= ".";
$cpu ||= 4;
$step ||=123;
$iter ||=0;
$thread ||= 8 ;
$startid ||=0;
$kvf ||="0G";
$scafnum ||=0;
$kmer ||=31;
$cvg ||=25;
$contigcutoff2 ||= 150;
$contigcutoff1 ||= 100 - $kmer;
$Queue ||= "";

my ($scaf,$reads,$PEreads,$Rlongread,$totalread,$ctgfile);

#die `pod2text $0` if(!$prefix);
die `pod2text $0` if ($Help);
die `pod2text $0` unless(-d $Outdir) ;

#2011-5-26 
sub abs_path
{
	chomp(my $tem_dir = `pwd`);
	foreach(@_){
		$_ || next ;
		/^\// && next ;
		$_ =~ s/^\.//g if(/^\./) ;
		$_ = "$tem_dir/$_";
		s/\/+$//;
	}
}
abs_path($Outdir,$dir,$contig_file,$gapread_file,$scafSeq);
#$Outdir =~ s/\/$//; #delete the last /
mkdir $Outdir unless (-d $Outdir);
$Outdir =~ s/\/+$// ;

my $size=0;
#my $pwd = `pwd`;
#if($Outdir == "\.")
#{
#	$Outdir = $pwd;
#}

print FILLLOG "Starting kgf gap filling , with step: $step \n";

my $fill_Gap = "SRkgf" ;
unless(-d $fill_Gap) {`mkdir $fill_Gap`;}

my $F_Outdir = $Outdir ;
$Outdir = $Outdir."/".$fill_Gap ;
open FILLLOG , ">$Outdir/fill.log";
my $Ori_Outdir = $Outdir ;

my $step_one = "step_1" ;
my $step_two = "step_2" ;
my $step_three = "step_3" ;

if($step =~ /1/)
{
	die `pod2text $0` unless($dir);
	die `pod2text $0` if(!$prefix);
    	unless (-d $step_one){eval(`mkdir $Outdir/$step_one`);}
	$Outdir = $Outdir."/".$step_one ;
	print FILLLOG "Step one: get reads related with gaps from the result of SOAPdenovo!\n";
	$dir =~ s/\/$//;
	$scaf = $dir."/$prefix.scaf";
	$scafSeq = $dir."/$prefix.scafSeq";
	
	#ensure all necessary files exist.
	unless (-e $scaf && -e $scafSeq)
	{
		print FILLLOG "check file :\n$scaf\nand file :\n$scafSeq\n";
	}

	$reads = $dir."/$prefix.shortreadInGap";
	unless(-e $reads){
		$reads = $dir."/$prefix.shortreadInGap.gz";
		unless(-e $reads)
		{
			print FILLLOG "check file :\n$reads\n";
		}
	}

	$PEreads = $dir."/$prefix.PEreadOnContig";
	unless (-e $PEreads){
		$PEreads = $dir."/$prefix.PEreadOnContig.gz";
		unless (-e $PEreads)
		{
			print FILLLOG  "check file :\n$PEreads\n"
		}
	}

	$Rlongread = $dir."/$prefix.RlongReadInGap";
	unless (-e $Rlongread){
		$Rlongread = $dir."/$prefix.RlongReadInGap.gz";
		unless (-e $Rlongread)
		{
			print FILLLOG  "check file :\n$Rlongread\n";
		}
	}

	$ctgfile = $dir."/$prefix.contig";

	my $linkscaf = "$Outdir/$prefix.scafSeq";
	if(-e $linkscaf)
	{
		$scafSeq = $linkscaf;
	}else{
		`ln -s $scafSeq $Outdir/$prefix.scafSeq`;
		$scafSeq = $linkscaf;
	}

	if($contigcutoff1 < 70)
	{
		$contigcutoff1 = 70;
	}
	my $n = int($contigcutoff1 / $kmer);
	if($n > 3) { $n = 3 ;}
	print FILLLOG  "getreadgap use the offset $n * $kmer\n" ;
	$kmer  = $n * $kmer ;
	`$path2/ggi -s $scafSeq -f $scaf -c $contigcutoff1 -t $contigcutoff2 -o $Outdir/$prefix.scafSeq -p $thread >$Outdir/gapinfo.log 2>$Outdir/ggi.error`;
	
	#ggr has a bug which the *.PEreadOncontig.gz must be generated by SOAPdenovo2 , otherwise ggr will be broken down .
	open WS , ">$Outdir/ggr.sh" ;
	if(-e $Rlongread)
	{
	print  WS "$path2/ggr -g $Outdir/$prefix.scafSeq.gapInfo -s $reads -r $Rlongread -p $PEreads -K $kmer -d $cvg -o $Outdir -m $Outdir/$prefix.scafSeq.maskContig -c $ctgfile >$Outdir/getgapread.log 2>$Outdir/getgapread.error\n" ;
    	}else{
		print  WS "$path2/ggr -g $Outdir/$prefix.scafSeq.gapInfo -s $reads -p $PEreads -K $kmer -d $cvg -o $Outdir -m $Outdir/$prefix.scafSeq.maskContig -c $ctgfile >$Outdir/getgapread.log 2>$Outdir/getgapread.error\n" ;
	}
	my $gapInfoFile = "$Outdir/$prefix.scafSeq.gapInfo" ;
	my $maskCtgFile = "$Outdir/$prefix.scafSeq.maskContig" ;
	my $gvf = (-s $gapInfoFile) + (-s $maskCtgFile) + (-s $ctgfile);
	$gvf = $gvf/1000000 ;
	if($gvf > 1000) #1G
	{
		$gvf = $gvf/1000;
		$gvf = $gvf."G";
	}else {
		$gvf = $gvf."M" ;
	}

	print FILLLOG  "ggr use memory : $gvf\n" ;
	if($noqsub){
		`sh $Outdir/ggr.sh` ;
	}else{
		`nohup $path/qsub-sge.pl --resource="vf=$gvf -P $P -q $Queue" --maxjob 1 --jobprefix gr --convert no $Outdir/ggr.sh` ;
	}
	$contig_file = "$scafSeq.SCAF.contig";
	$longread = "$Outdir/longread.fa.gz" ;
	if(-e $longread)
	{
		`cat $Outdir/shortread.fa.gz $Outdir/PEread.fa.gz $Outdir/longread.fa.gz >$Outdir/gapread.fa.gz` ;
		`rm $Outdir/shortread.fa.gz $Outdir/PEread.fa.gz $Outdir/longread.fa.gz ` ;
	}else{
		`cat $Outdir/shortread.fa.gz $Outdir/PEread.fa.gz >$Outdir/gapread.fa.gz` ;
		`rm $Outdir/shortread.fa.gz $Outdir/PEread.fa.gz` ;
	}
	$gapread_file = "$Outdir/gapread.fa.gz";
	unless(-e $gapread_file){
		print FILLLOG  "gzip error , there has no gapread.fa.gz file\n";
	}
	`perl $path/gz_readstat2.pl $gapread_file >$Outdir/gapread.fa.gz.stat`;
	
	$Outdir = $Ori_Outdir ;
	print FILLLOG  "Get gap read finished!\n";	
}


if($step=~/2/ && $cpu > 1)
{
    	unless(-d $step_two){eval(`mkdir $Outdir/$step_two`);}
	$Outdir = $Outdir."/".$step_two ;
	print FILLLOG  "step two: begin to Cut the files and kgf gap filling!";
	if(!$contig_file)
	{
		if($scafSeq){  #2011-4-19
			my @names=split (/\//,$scafSeq);
			my $name = $names[@names -1];
			$scafSeq = "$Outdir/$name";
		}
		if(!$scafSeq){
			print FILLLOG  "please set scaffold sequence!\n";
			exit(1);
		}
		my $SCAFctg = "$scafSeq.SCAF.contig";
		unless (-e $SCAFctg)
		{
			print FILLLOG  "please make sure the progrom can find the file $scafSeq.SCAF.contig in this work directory!\n";
			exit(1);
		}
		$contig_file = "$scafSeq.SCAF.contig";
	}
	
	$gapread_file = "$Ori_Outdir/$step_one/gapread.fa.gz" if(!$gapread_file);

	if(-e $gapread_file && -e $contig_file)
	{
		print FILLLOG  "Load gap file: $gapread_file.\nLoad contig file: $contig_file.\n";
	}else{
		print FILLLOG  "Please input or check $gapread_file or $contig_file!\n";
	}
	
	`perl $path/gz_Cut2.pl $gapread_file $contig_file $cpu $Outdir`;
	`perl $path/gz_Creatkgf.pl $kgf2 $Outdir $cpu $thread >$Outdir/kgf.sh`;

	if($kvf eq '0G')
	{
	    	#$kvf=$thread*2;# + int($len/1000000000/$cpu);
		my $gapread_size = -s $gapread_file ;
		#$gapread_size *= 4 if($gapread_file =~ /(\w+)\.gz/);
		my $contig_size = -s $contig_file ;
		print FILLLOG  "Calculate kgf necessary  memory : size(gapread.fa)/(--cpu) + size(*.SCAF.contig)*2/(--cpu)\n\n" ;
		$kvf = ($gapread_size/$cpu/1000000000) + ($contig_size/$cpu/1000000000)*2 ;
	    	$kvf=$kvf."G";
	}
	print FILLLOG  "begin to fill gaps with kvf: $kvf\n";
	if($noqsub){
		`sh $Outdir/kgf.sh`;
	}else{
		`nohup $path/qsub-sge.pl --resource="vf=$kvf -P $P -q $Queue" --maxjob $cpu --jobprefix fg --convert no $Outdir/kgf.sh` ;
	}
	my $name = basename($scafSeq);
	`cat $Outdir/F*/FilledScaf/seq.thread* $Ori_Outdir/$step_one/$name.CONTIG >$Outdir/$name.fill`;
	`cat $Outdir/F*/Log/log.thread* >$Outdir/fill.Log`;
	#`cat $Outdir/F*/Snp/snp.thread* >$Outdir/fill.snp`;

	my $seq = "$Outdir/gapSeq.fa";
	`cat $Outdir/F*/gapSeq.fa > $seq`;

	`perl $path/get_scaftig.pl $Outdir/$name.fill >$Outdir/$name.fill.scaftig`;
	`perl $path/seq_n50 $Outdir/$name.fill.scaftig >$Outdir/N50.txt`;
	#my $n50 = `grep 'N50' $Outdir/fill.fasta.0.scaftig.N50 |awk '{print FILLLOG  $2}'`;

	my $fill = `perl $path/gapfillratio2.pl $Outdir $cpu `;
	if($fill=~ /Error/)
	{
		print FILLLOG  "\n\n$fill\n\n";
		exit(1);
	}								              
	print FILLLOG  $fill;
	print FILLLOG  "Gap filling finished! \n";
	$Outdir = $Ori_Outdir ;
}

if($step =~ /3/)
{
    	unless (-d $step_three){eval(`mkdir $Outdir/$step_three`);}
	print FILLLOG  "Step Three: analysis the fill result!\n";
	#2011-4-19
	my $depth = "$Outdir/$step_one/gapread.fa.gz.gapread.depth";
	my $seq = "$Outdir/$step_two/gapSeq.fa";
	my $Log = "$Outdir/$step_two/fill.Log";
	my @info=glob("$Outdir/$step_one/*.scafSeq.gapInfo");
	my $gapinfo = $info[0];
	unless (-e $depth && -e $seq && -e $Log && -e $gapinfo)
	{
		print FILLLOG  "please check file: $depth, $seq , $Log and $gapinfo\n";
		print FILLLOG  "make sure the file $depth , $seq , $Log and *.scafSeq.gapInfo under the dir to output!\n";
		exit(1);
	}
	$Outdir = $Outdir."/".$step_three ;
	`grep 'TRGAP' $Log >$Outdir/TR.lst`;
	`grep 'ERGAP' $Log >$Outdir/ER.lst`;
	`perl $path/fullfill.pl $seq >$Outdir/fullfill.lst`;
	`perl $path/get_unfull_info.pl $Outdir/fullfill.lst $gapinfo >$Outdir/unfill.gapInfo 2>$Outdir/unfill.stat`;

	`perl $path/blank.pl $depth $seq >$Outdir/blank.lst`;
	`perl $path/covercheck.pl $Outdir/blank.lst >$Outdir/cover.lst`;
	#`more $Outdir/cover.lst |awk '$3 < 1 {print FILLLOG  $_}' >$Outdir/uncover.lst`;
	`perl $path/gether.pl $Outdir/cover.lst $Outdir/TR.lst $depth $Outdir/ER.lst $Outdir >$Outdir/canfill.stat`;
	`mv $F_Outdir/canfullfill.lst $Outdir/`;
	print FILLLOG  "Step Three finished! Please read file: unfill.stat and canfill.stat \n";
	#`rm $Outdir/gapread.fa`;
}


print FILLLOG  "All Pipeline finished!";
