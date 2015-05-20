#!/bin/sh
rootDir=`pwd`
# rename file to match regex "(\d+\_[^_]+\_FC[^_]+_L\d+)_([^_]+)_1\.fq"
r180i_1="20120906_StaphylococcusAureus_FC1_L1_180i45X_1.fq"
r180i_2="20120906_StaphylococcusAureus_FC1_L1_180i45X_2.fq"
r3500i_1="20120906_StaphylococcusAureus_FC1_L1_3500i45X_1.fq"
r3500i_2="20120906_StaphylococcusAureus_FC1_L1_3500i45X_2.fq"

# Correct data for SOAPdenovo2:
mkdir correct_data_SOAPdenovo2
cd correct_data_SOAPdenovo2
ln -s /ifs1/ST_ASMB/PMO/SOAPdenovo2/GAGE/Staphylococcus_aureus/Data/original/frag_1.fastq ${r180i_1}
ln -s /ifs1/ST_ASMB/PMO/SOAPdenovo2/GAGE/Staphylococcus_aureus/Data/original/frag_2.fastq ${r180i_2}
ln -s /ifs1/ST_ASMB/PMO/SOAPdenovo2/GAGE/Staphylococcus_aureus/Data/original/shortjump_1.fastq ${r3500i_1}
ln -s /ifs1/ST_ASMB/PMO/SOAPdenovo2/GAGE/Staphylococcus_aureus/Data/original/shortjump_2.fastq ${r3500i_2}

echo -e "${r180i_1}\n${r180i_2}" >ReadFiles.lst

echo -e "*************************************\nStart to build Kmer frequency table.\n********************\n"
$rootDir/bin/KmerFreq_AR_v2.0 -k 17 -c -1 -q 33 -m 1 -t 16 -p Staphylococcus_aureus ReadFiles.lst >ReadsKmerfreq.log
if [ ! -f "Staphylococcus_aureus.freq.cz" ] || [ ! -f "Staphylococcus_aureus.freq.cz.len" ]; then
  echo "File: Staphylococcus_aureus.freq.cz or Staphylococcus_aureus.freq.cz.len doen NOT exist!\nError happened in building kmer frequency table.\n"
  exit 1;
fi
echo -e "\n********************\nKmer frequency table built.\n*************************************\n\n*************************************\nStart to correct reads.\n********************\n"

$rootDir/bin/Corrector_AR_v2.0 -k 17 -l 3 -a 0 -e 1 -w 0 -Q 33 -q 30 -x 8 -t 16 -o 1 Staphylococcus_aureus.freq.cz Staphylococcus_aureus.freq.cz.len ReadFiles.lst >Reads_Correct.log 2>Reads_Correct.err
c180i_1="$rootDir/correct_data_SOAPdenovo2/${r180i_1}.cor.pair_1.fq.gz"
c180i_2="$rootDir/correct_data_SOAPdenovo2/${r180i_2}.cor.pair_2.fq.gz"
if [ ! -f "${c180i_1}" ] || [ ! -f "${c180i_2}" ]; then
  echo -e "File: ${c180i_1} or ${c180i_2} does NOT exist!\nError happened in correcting error.\n";
  exit 1;
fi
echo -e "\n********************\nReads corrected.\n*************************************\n\n"
cd $rootDir

# SOAPdenovo2 assemble:
mkdir assemble_SOAPdenovo2
cd assemble_SOAPdenovo2
echo -e "max_rd_len=100\n[LIB]\navg_ins=180\nasm_flags=3\nreverse_seq=0\nrank=1\nq1=${c180i_1}\nq2=${c180i_2}\n" >Lib.cfg

if [ ! -f "$rootDir/correct_data_SOAPdenovo2/${r3500i_1}" ] || [ ! -f "$rootDir/correct_data_SOAPdenovo2/${r3500i_2}" ]; then
  echo "File: $rootDir/correct_data_SOAPdenovo2/${r3500i_1} or $rootDir/correct_data_SOAPdenovo2/${r3500i_2} does NOT exist!"
  exit 1;
fi

echo -e "[LIB]\navg_ins=3500\nasm_flags=2\nreverse_seq=1\nrank=2\nmap_len=31\npair_num_cutoff=11\nq1=$rootDir/correct_data_SOAPdenovo2/${r3500i_1}\nq2=$rootDir/correct_data_SOAPdenovo2/${r3500i_2}\n" >>Lib.cfg

cp Lib.cfg GapCloser.cfg

echo -e "\n*************************************\nStart to assemble reads.\n********************\n"
K=31
$rootDir/bin/SOAPdenovo-63mer_v2.0 all -s Lib.cfg -d 1 -R -o Staphylococcus_aureus -K $K -p 16 -F >asm.log 2>asm.err
if [ ! -f "Staphylococcus_aureus.scafSeq" ]; then
  echo -e "File: Staphylococcus_aureus.scafSeq does NOT exist!\nError happened in assembling.\n"
  exit 1;
fi

$rootDir/bin/GapCloser_v1.12 -a Staphylococcus_aureus.scafSeq -b GapCloser.cfg -p $K -l 70 -t 16 -o Staphylococcus_aureus.scafSeq.GC.fa >GapCloser.log
if [ ! -f "Staphylococcus_aureus.scafSeq.GC.fa" ]; then
  echo -e "File: Staphylococcus_aureus.scafSeq.GC.fa does NOT exist!\nError happened in gap filling.\n"
  exit 1;
fi
echo -e "\n********************\nAssemble done.\n*************************************\n"

cd $rootDir
echo -e "\nAll done.\n"
