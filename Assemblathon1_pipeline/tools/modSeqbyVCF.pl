#!/usr/bin/perl -w

my ($seqfn, $vcffn) = @ARGV;
die "perl $0 sequence vcf\n" unless $vcffn;

open my $seqfh, $seqfn or die "$!, $seqfn\n";
%seq=();

#FASTA sequence import
$/=">"; $/=<$seqfh>; $/="\n";
while(<$seqfh>)
{
        chomp;
        (my $id = $_) =~ s/\s+.*$//;
        
        $/=">";
        my $seq = <$seqfh>;
        chomp $seq;
        $seq =~ s/\s+//g;
        $/="\n";

        $seq{$id} = $seq;
}
close $seqfh;
#FASTA sequence import end

my $currentSeq = "";
my @seqArray = ();
my $pos = -1;
my $length = -1;

sub loadSeq
{
        $id = shift @_;
        $vcfPos = shift @_;
        if($currentSeq ne $id)
        {
                if($currentSeq ne "")
                {
                        $seq{$currentSeq} = '';
                        if($vcfPos != $length)
                        {
                                print join ("", @seqArray[$vcfPos..($length-1)]);
                        }
                        print "\n";
                }
                return if $id eq "";
                $currentSeq = $id;
                print ">$id\n";
                die "FATAL: $id not found in FASTA\n" if not defined $seq{$id};
                @seqArray = split //, $seq{$id};
                $length = scalar(@seqArray);
                $pos = 1;
        }
}

my $vcfCoord = -1;
open my $vcffh, $vcffn or die "$!, $vcffn\n";
while(<$vcffh>)
{
        chomp;
        next if(/^#/);
        @a = split /\s+/;
        next if($a[4] =~ /,/);
        &loadSeq($a[0], $vcfCoord);
        $vcfCoord = $a[1];
        die '$pos > $vcfCoord' if $pos > $vcfCoord;
        print join ("", @seqArray[($pos-1)..($vcfCoord-2)]) if($pos < $vcfCoord);
        #sanity check
        $char = (split //, $a[3])[0];
        die '$char ne $seqArray[($vcfCoord-1)]' if $char ne $seqArray[($vcfCoord-1)];
        
        #should perform vcf quality check here
        $a[7] =~ /AF1=([\d.]+);/;
        if($1 == 1)
        {
                print $a[4];
        }
        else
        {
                print $a[3];
        }
        $pos = $vcfCoord + length($a[3]);
}

&loadSeq("", $vcfCoord);

foreach(keys %seq)
{
        if(length($seq{$_}) != 0)
        {
                print ">$_\n$seq{$_}\n";
        }
}
