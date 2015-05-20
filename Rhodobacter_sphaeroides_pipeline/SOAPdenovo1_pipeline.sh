#!/bin/sh
rootDir=`pwd`
# filter data for SOAPdenovo1:
mkdir filter_data_SOAPdenovo1
cd filter_data_SOAPdenovo1
# rename file to match regex "(\d+\_[^_]+\_FC[^_]+_L\d+)_([^_]+)_1\.fq"
r180i_1="20120906_RhodobacterSphaeroides_FC1_L1_180i45X_1.fq"
r180i_2="20120906_RhodobacterSphaeroides_FC1_L1_180i45X_2.fq"
r4000i_1="20120906_RhodobacterSphaeroides_FC1_L1_4000i45X_1.fq"
r4000i_2="20120906_RhodobacterSphaeroides_FC1_L1_4000i45X_2.fq"
lib="4000i45X"
ln -s $rootDir/Data/original/shortjump_1.fastq ${r4000i_1}
ln -s $rootDir/Data/original/shortjump_2.fastq ${r4000i_2}
echo  -e "${r4000i_1} 0 50 50\n${r4000i_2} 0 50 10" >lane.lst
echo -e "${lib} 4000" >lib.lst
echo -e "*************************************\nStart to filter reads\n********************\n"
perl $rootDir/bin/makeSH.pl -q 33 -t 16 -p lane.lst lib.lst
sh lane.lst.filter.sh
f4000i_1="$rootDir/filter_data_SOAPdenovo1/${lib}/${r4000i_1}.clean"
f4000i_2="$rootDir/filter_data_SOAPdenovo1/${lib}/${r4000i_2}.clean"
if [ ! -f "${f4000i_1}" ] || [ ! -f "${f4000i_2}" ]; then
  echo -e "File: ${f4000i_1} or ${f4000i_2} does NOT exist!\nError happened in filtering data.\n";
  exit 1;
fi
cd $rootDir
echo -e "\n********************\nReads filtered\n*************************************\n\n"

# Correct data for SOAPdenovo1:
mkdir correct_data_SOAPdenovo1
cd correct_data_SOAPdenovo1
ln -s $rootDir/Data/original/frag_1.fastq ${r180i_1}
ln -s $rootDir/Data/original/frag_2.fastq ${r180i_2}
echo -e "${r180i_1}\n${r180i_2}" >ReadFiles.lst
echo -e "*************************************\nStart to build Kmer frequency table\n********************\n"
$rootDir/bin/KmerFreq_v1.0 -i ReadFiles.lst -s 17 -q 0 -Q 33 -f 1 -l 1 -g 0 -n 1 -o Rhodobacter_sphaeroides >kmerfreq.log
if [ ! -f "Rhodobacter_sphaeroides.freq" ]; then
  echo "File: Rhodobacter_sphaeroides.freq does NOT exist!\nError happened in building kmer frequency table.\n";
  exit 1;
fi
echo -e "\n********************\nKmer frequency table built\n*************************************\n\n*************************************\nStart to correct reads\n********************\n"

$rootDir/bin/Corrector_v1.0 -i ReadFiles.lst -s 17 -r Rhodobacter_sphaeroides.freq -n 1 -k 3 -e 3 -d 2 -g 0 -t 16 >correct.log
ls *.fq.corr >corrected_file.lst
cp $rootDir/bin/merge_pair.pl ./
perl $rootDir/bin/merge_pair_list.pl corrected_file.lst >merge.log
echo -e "\n********************\nReads corrected\n*************************************\n\n"
cd ..
len=${#r180i_1}-5
r180i=${r180i_1:0:$len}
c180i_pair="$rootDir/correct_data_SOAPdenovo1/${r180i}.corr.pair"
c180i_single="$rootDir/correct_data_SOAPdenovo1/${r180i}.corr.single"
if [ ! -f "${c180i_pair}" ] || [ ! -f "${c180i_single}" ]; then
  echo "file: ${c180i_pair} or ${c180i_single} does NOT exist!\nError happened in correcting error.\n"
  exit 1;
fi

# SOAPdenovo1 assemble:
mkdir assemble_SOAPdenovo1
cd assemble_SOAPdenovo1
echo -e "max_rd_len=100\n[LIB]\navg_ins=180\nasm_flags=3\nreverse_seq=0\nrank=1\np=${c180i_pair}\nf=${c180i_single}" >lib.cfg

echo -e "[LIB]\navg_ins=4000\nasm_flags=2\nreverse_seq=1\nrank=2\nmap_len=35\nq1=/${f4000i_1}\nq2=${f4000i_2}\n" >>lib.cfg

sed 's/max_rd_len=100/max_rd_len=70/' lib.cfg >GapCloser.cfg
echo -e "\n*************************************\nStart to assemble reads\n********************\n"
K=23
$rootDir/bin/SOAPdenovo_v1.0 all -s lib.cfg -d 1 -R -o Rhodobacter_sphaeroides -K $K -p 16 >asm.log 2>asm.err
if [ ! -f "Rhodobacter_sphaeroides.scafSeq" ]; then
  echo "File: Rhodobacter_sphaeroides.scafSeq does NOT exist!\nError happened in assembling.\n";
  exit 1;
fi
$rootDir/bin/GapCloser_v1.10 -a Rhodobacter_sphaeroides.scafSeq -b GapCloser.cfg -p $K -t 16 -o Rhodobacter_sphaeroides.scafSeq.GC.fa >GapCloser.log
perl $rootDir/bin/get_scaftig.pl Rhodobacter_sphaeroides.scafSeq.GC.fa >Rhodobacter_sphaeroides.scafSeq.GC.ctg.fa
echo -e "\n********************\nAssemble done\n*************************************\n"
cd $rootDir
echo -e "All done.\n"
