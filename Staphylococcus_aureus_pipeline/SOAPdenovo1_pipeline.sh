#!/bin/sh
rootDir=`pwd`
# rename file to match regex "(\d+\_[^_]+\_FC[^_]+_L\d+)_([^_]+)_1\.fq"
r180i_1="20120906_StaphylococcusAureus_FC1_L1_180i45X_1.fq"
r180i_2="20120906_StaphylococcusAureus_FC1_L1_180i45X_2.fq"
r3500i_1="20120906_StaphylococcusAureus_FC1_L1_3500i45X_1.fq"
r3500i_2="20120906_StaphylococcusAureus_FC1_L1_3500i45X_2.fq"

# Correct data for SOAPdenovo1:
mkdir correct_data_SOAPdenovo1
cd correct_data_SOAPdenovo1
ln -s $rootDir/Data/original/frag_1.fastq ${r180i_1}
ln -s $rootDir/Data/original/frag_2.fastq ${r180i_2}
ln -s $rootDir/Data/original/shortjump_1.fastq ${r3500i_1}
ln -s $rootDir/Data/original/shortjump_2.fastq ${r3500i_2}

echo -e "${r180i_1}\n${r180i_2}" >ReadFiles.lst

echo -e "*************************************\nStart to build Kmer frequency table.\n********************\n"
$rootDir/bin/KmerFreq_v1.0 -i ReadFiles.lst -s 17 -q 0 -Q 33 -f 1 -l 1 -g 0 -n 1 -o Staphylococcus_aureus_Reads >ReadsKmerFreq.log
if [ ! -f "Staphylococcus_aureus_Reads.freq" ]; then
  echo -e "File: Staphylococcus_aureus_Reads.freq does NOT exist!\nError happened in building kmer frequency table.\n"
  exit 1;
fi
echo -e "\n********************\nKmer frequency table built.\n*************************************\n\n*************************************\nStart to correct reads.\n********************\n"

$rootDir/bin/Corrector_v1.0 -i ReadFiles.lst -s 17 -r Staphylococcus_aureus_Reads.freq -n 1 -k 3 -e 3 -d 2 -g 0 -t 16 >correctReads.log
ls *.fq.corr >corrected_Reads_file.lst
cp $rootDir/bin/merge_pair.pl ./
perl $rootDir/bin/merge_pair_list.pl corrected_Reads_file.lst >mergeReads.log
len=${#r180i_1}-5
r180i=${r180i_1:0:$len}
c180i_pair="$rootDir/correct_data_SOAPdenovo1/${r180i}.corr.pair"
c180i_single="$rootDir/correct_data_SOAPdenovo1/${r180i}.corr.single"
if [ ! -f "${c180i_pair}" ] || [ ! -f "${c180i_single}" ]; then
  echo -e "File: ${c180i_pair} or ${c180i_single} does NOT exist!\nError happened in correcting error.\n"
  exit 1
fi
echo -e "\n********************\nReads corrected.\n*************************************\n\n"

cd $rootDir
# SOAPdenovo1 assemble:
mkdir assemble_SOAPdenovo1
cd assemble_SOAPdenovo1
echo -e "max_rd_len=100\n[LIB]\navg_ins=180\nasm_flags=3\nreverse_seq=0\nrank=1\np=${c180i_pair}\nf=${c180i_single}" >Lib.cfg

if [ ! -f "$rootDir/correct_data_SOAPdenovo1/${r3500i_1}" ] || [ ! -f "$rootDir/correct_data_SOAPdenovo1/${r3500i_2}" ]; then
  echo "File: $rootDir/correct_data_SOAPdenovo1/${r3500i_1} or $rootDir/correct_data_SOAPdenovo1/${r3500i_2} does NOT exist!"
  exit 1;
fi

echo -e "[LIB]\navg_ins=3500\nasm_flags=2\nreverse_seq=1\nrank=2\nmap_len=31\npair_num_cutoff=11\nq1=$rootDir/correct_data_SOAPdenovo1/${r3500i_1}\nq2=$rootDir/correct_data_SOAPdenovo1/${r3500i_2}\n" >>Lib.cfg

cp Lib.cfg GapCloser.cfg
echo -e "\n*************************************\nStart to assemble reads.\n********************\n"
K=31
$rootDir/bin/SOAPdenovo_v1.0 all -s Lib.cfg -d 1 -R -o Staphylococcus_aureus -K $K -p 16 -F >asm.log 2>asm.err
if [ ! -f "Staphylococcus_aureus.scafSeq" ]; then
  echo -e "File: Staphylococcus_aureus.scafSeq does NOT exist!\nError happened in assembling.\n"
  exit 1;
fi

$rootDir/bin/GapCloser_v1.10 -a Staphylococcus_aureus.scafSeq -b GapCloser.cfg -p $K -t 16 -o Staphylococcus_aureus.scafSeq.GC.fa >GapCloser.log
if [ ! -f "Staphylococcus_aureus.scafSeq.GC.fa" ]; then
  echo -e "File: Staphylococcus_aureus.scafSeq.GC.fa does NOT exist!\nError happened in gap filling.\n"
  exit 1;
fi
echo -e "\n********************\nAssemble done\n*************************************\n"
cd $rootDir
echo -e "\nAll done.\n"
