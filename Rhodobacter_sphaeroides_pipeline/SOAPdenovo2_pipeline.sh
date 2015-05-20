#!/bin/sh
rootDir=`pwd`
# filter data for SOAPdenovo2:
mkdir filter_data_SOAPdenovo2
cd filter_data_SOAPdenovo2
# rename file to match regex "(\d+\_[^_]+\_FC[^_]+_L\d+)_([^_]+)_1\.fq"
r180i_1="20120906_StaphylococcusAureus_FC1_L1_180i45X_1.fq"
r180i_2="20120906_StaphylococcusAureus_FC1_L1_180i45X_2.fq"
r4000i_1="20120906_StaphylococcusAureus_FC1_L1_4000i45X_1.fq"
r4000i_2="20120906_StaphylococcusAureus_FC1_L1_4000i45X_2.fq"
lib="4000i45X"
ln -s $rootDir/Data/original/shortjump_1.fastq ${r4000i_1}
ln -s $rootDir/Data/original/shortjump_2.fastq ${r4000i_2}
echo  -e "${r4000i_1} 0 50 50\n${r4000i_2} 0 50 10" >lane.lst
echo -e "${lib} 4000" >lib.lst
echo -e "*************************************\nStart to filter reads\n********************\n"
perl $rootDir/bin/makeSH.pl -q 33 -t 16 -p lane.lst lib.lst
sh lane.lst.filter.sh
f4000i_1="$rootDir/filter_data_SOAPdenovo2/${lib}/${r4000i_1}.clean"
f4000i_2="$rootDir/filter_data_SOAPdenovo2/${lib}/${r4000i_2}.clean"
if [ ! -f "${f4000i_1}" ] || [ ! -f "${f4000i_2}" ]; then
  echo -e "File: ${f4000i_1} or ${f4000i_2} does NOT exist!\nError happened in filtering data.\n";
  exit 1;
fi
cd $rootDir
echo -e "\n********************\nReads filtered\n*************************************\n\n"
# Correct data for SOAPdenovo2:
mkdir correct_data_SOAPdenovo2
cd correct_data_SOAPdenovo2
ln -s $rootDir/Data/original/frag_1.fastq ${r180i_1}
ln -s $rootDir/Data/original/frag_2.fastq ${r180i_2}
echo -e "${r180i_1}\n${r180i_2}" >ReadFiles.lst
echo -e "*************************************\nStart to build Kmer frequency table\n********************\n"
$rootDir/bin/KmerFreq_AR_v2.0 -k 17 -c -1 -q 33 -m 1 -t 16 -p Rhodobacter_sphaeroides ReadFiles.lst >kmerfreq.log 2>kmerfreq.err
if [ ! -f "Rhodobacter_sphaeroides.freq.cz" ] || [ ! -f "Rhodobacter_sphaeroides.freq.cz.len" ]; then
  echo -e "File: Rhodobacter_sphaeroides.freq.cz or Rhodobacter_sphaeroides.freq.cz.len doen NOT exist!\nError happened in building kmer frequency table.\n"
  exit 1;
fi
echo -e "\n********************\nKmer frequency table built\n*************************************\n\n*************************************\nStart to correct reads\n********************\n"
$rootDir/bin/Corrector_AR_v2.0 -k 17 -l 3 -m 5 -c 5 -a 0 -e 1 -w 0 -Q 33 -q 30 -x 8 -t 16 -o 1 Rhodobacter_sphaeroides.freq.cz Rhodobacter_sphaeroides.freq.cz.len ReadFiles.lst >correct.log 2>correct.err
c180i_1="$rootDir/correct_data_SOAPdenovo2/${r180i_1}.cor.pair_1.fq.gz"
c180i_2="$rootDir/correct_data_SOAPdenovo2/${r180i_2}.cor.pair_2.fq.gz"
c180i_single="$rootDir/correct_data_SOAPdenovo2/${r180i_1}.cor.single.fq.gz"
if [ ! -f "${c180i_1}" ] || [ ! -f "${c180i_2}" ]; then
  echo "File: ${c180i_1} or ${c180i_2} does NOT exist!\nError happened in correcting error.\n";
  exit 1;
fi
echo -e "\n********************\nReads corrected\n*************************************\n\n"
cd $rootDir
# SOAPdenovo2 assemble:
mkdir assemble_SOAPdenovo2
cd assemble_SOAPdenovo2
echo -e "max_rd_len=100\n[LIB]\navg_ins=180\nasm_flags=3\nreverse_seq=0\nrank=1\nq1=${c180i_1}\nq2=${c180i_2}\nq=${c180i_single}\n" >lib.cfg

echo -e "[LIB]\navg_ins=4000\nasm_flags=2\nreverse_seq=1\nrank=2\nmap_len=35\npair_num_cutoff=11\nq1=${f4000i_1}\nq2=${f4000i_2}\n" >>lib.cfg
cp lib.cfg GapCloser.cfg
echo -e "\n*************************************\nStart to assemble reads\n********************\n"
K=19
$rootDir/bin/SOAPdenovo-63mer_v2.0 all -s lib.cfg -d 1 -R -o Rhodobacter_sphaeroides -K $K -p 16 -F >asm.log 2>asm.err
if [ ! -f "Rhodobacter_sphaeroides.scafSeq" ]; then
  echo -e "File: Rhodobacter_sphaeroides.scafSeq does NOT exist!\nError happened in assembling.\n";
  exit 1;
fi
$rootDir/bin/GapCloser_v1.12 -a Rhodobacter_sphaeroides.scafSeq -b GapCloser.cfg -p $K -l 60 -t 16 -o Rhodobacter_sphaeroides.scafSeq.GC.fa >GapCloser.log

perl /panfs/CD/bin/get_scaftig.pl Rhodobacter_sphaeroides.scafSeq.GC.fa >Rhodobacter_sphaeroides.scafSeq.GC.ctg.fa
cd $rootDir
echo -e "\n********************\nAssemble done\n*************************************\n"
echo -e "All done.\n";
