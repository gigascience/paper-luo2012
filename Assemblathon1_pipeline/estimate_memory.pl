#!/usr/bin/perl -w

=head1 Name
	auto_estimate_memory.pl   		
		
=head1 Version
	Author: du yanlin, duyanlin@genomics.org.cn
	Version: 1.0,  Date: 2010-12-16	
	
=head1 Usage
	perl auto_estimate_memory.pl <pid_file> [all_time] [gap_time] [output_file]	
	
=head1 Options
	-A (optional):set time range[300 s] 
	-G (optional):set time gap[10 s] 
	-P <PID>: process ID
	-O [optional]:output file[$pid.log] 
	
=head1 Exmple
	perl  estimate_memory.pl -P 15178 -O 15178.log
	
=cut

use strict;
use Getopt::Long;

my ($time_all, $time_gap, $time_used);
my ($file_pid, $file_out);
my ($memory_current, $memory_max, $usr, $flag);
my $help;

GetOptions(
	"Pid_file=s"=>\$file_pid,											
	"Out_file=s"=>\$file_out,
	"All_time=i"=> \$time_all,
	"Gap_time=i"=> \$time_gap,
	"help"=> \$help
	);

die `pod2text $0` if ($help);

unless ( defined $file_pid ){
	print "\nPlease input PID, usage followed!!!\n\n\n";
	die `pod2text $0`;
}
#die "NO PID input!!! $0"  unless ( defined $file_pid );
$file_out = $file_pid.".Log"  unless (defined $file_out);
$time_all = 36000000 unless (defined $time_all);
$time_gap = 10 unless (defined $time_gap);

open(OUT,">>".$file_out) or die "can not open output_file.\n";

print OUT ">Memory Infos\n";
print OUT "PID\tTIME\t\tMEM\tMEM_MAX\n";

$time_used = time();
$flag = $time_all;
$memory_max = 0;
while($flag>0){

	my $progress = `ps ux `;
	
	undef $memory_current;

	my @record = split /\n/,$progress;
	shift(@record);
	foreach my $line (@record){
		my @arr = split /\s+/, $line;
		$usr = $arr[0];
		next if($arr[1]!=$file_pid);
		$memory_current = $arr[5];		
	}
	goto LABLE  unless(defined $memory_current);
	if( $memory_current > $memory_max ){
		$memory_max = $memory_current;
	}	
	
	my $time_current = time();	
	my @time_arr = localtime $time_current;
	$time_current = $time_arr[2].":".$time_arr[1].":".$time_arr[0];
	print OUT "$file_pid\t$time_current\t$memory_current\t$memory_max\n";
	
	sleep($time_gap);	
	$flag -= $time_gap;
}
system("kill -9 $file_pid");

LABLE:
$time_used = time()-$time_used;
print OUT "\nPID: $file_pid\tusr: $usr\tElapse: $time_used s\tinterval: $time_gap s\tmaxMemory: $memory_max\n";

close OUT;
