#!/bin/sh
rootDir=`pwd`
# rename file to match regex "(\d+\_[^_]+\_FC[^_]+_L\d+)_([^_]+)_1\.fq"
r400i_1="20120906_Bombus_impatiens_FC1_L1_400i_1.fq"
r400i_2="20120906_Bombus_impatiens_FC1_L1_400i_2.fq"
r3000i_1="20120906_Bombus_impatiens_FC1_L1_3000i_1.fq"
r3000i_2="20120906_Bombus_impatiens_FC1_L1_3000i_2.fq"
r8000i_1="20120906_Bombus_impatiens_FC1_L1_8000i_1.fq"
r8000i_2="20120906_Bombus_impatiens_FC1_L1_8000i_2.fq"

# filter data for SOAPdenovo1:
mkdir filter_data_SOAPdenovo2
cd filter_data_SOAPdenovo2
if [ ! -f "$rootDir/removeAdaptor/shortjump_1.fastq.rmAd" ]; then
  echo "File: $rootDir/removeAdaptor/shortjump_1.fastq.rmAd does NOT exist! Please run removeAdaptor.sh firstly."
  exit 1;
fi
ln -s $rootDir/removeAdaptor/shortjump_1.fastq.rmAd ${r3000i_1}
ln -s $rootDir/removeAdaptor/shortjump_2.fastq.rmAd ${r3000i_2}
ln -s $rootDir/removeAdaptor/mediumjump_1.fastq.rmAd ${r8000i_1}
ln -s $rootDir/removeAdaptor/mediumjump_2.fastq.rmAd ${r8000i_2}
echo -e "*************************\nStart to filter duplication.\n*************************\n"
$rootDir/bin/SOAPfilter_v2.0 -a 10 -b 64 -c 10 -d 64 -f -1 -B -1 -w -1 -p ${r3000i_1} ${r3000i_2} shortjump.dup.stat ${r3000i_1}.dup.clean ${r3000i_2}.dup.clean
$rootDir/bin/SOAPfilter_v2.0 -a 10 -b 64 -c 10 -d 64 -f -1 -B -1 -w -1 -p ${r8000i_1} ${r8000i_2} mediumjump.dup.stat ${r8000i_1}.dup.clean ${r8000i_2}.dup.clean
cd $rootDir

# Correct data for SOAPdenovo2:
mkdir correct_data_SOAPdenovo2
cd correct_data_SOAPdenovo2
ln -s $rootDir/Data/original/frag_1.fastq ${r400i_1}
ln -s $rootDir/Data/original/frag_2.fastq ${r400i_2}

echo -e "${r400i_1}\n${r400i_2}" >ReadFiles.lst

echo -e "*************************************\nStart to build Kmer frequency table.\n********************\n"
$rootDir/bin/KmerFreq_AR_v2.0 -k 17 -c -1 -q 64 -b 16000000000 -m 1 -t 16 -p Bombus_impatiens ReadFiles.lst >ReadsKmerfreq.log
if [ ! -f "Bombus_impatiens.freq.cz" ] || [ ! -f "Bombus_impatiens.freq.cz.len" ]; then
  echo -e "File: Bombus_impatiens.freq.cz or Bombus_impatiens.freq.cz.len doen NOT exist!\nError happened in building kmer frequency table.\n"
  exit 1;
fi
echo -e "\n********************\nKmer frequency table built.\n*************************************\n\n*************************************\nStart to correct reads.\n********************\n"

$rootDir/bin/Corrector_AR_v2.0 -k 17 -l 3 -a 0 -e 1 -w 0 -Q 64 -q 30 -x 8 -t 16 -o 1 Bombus_impatiens.freq.cz Bombus_impatiens.freq.cz.len ReadFiles.lst >Reads_Correct.log 2>Reads_Correct.err
c400i_1="$rootDir/correct_data_SOAPdenovo2/${r400i_1}.cor.pair_1.fq.gz"
c400i_2="$rootDir/correct_data_SOAPdenovo2/${r400i_2}.cor.pair_2.fq.gz"
c400i_s="$rootDir/correct_data_SOAPdenovo2/${r400i_1}.cor.single.fq.gz"
if [ ! -f "${c400i_1}" ] || [ ! -f "${c400i_2}" ] || [ ! -f "${c400i_s}" ]; then
  echo -e "File: ${c400i_1} or ${c400i_2} or ${c400i_s} does NOT exist!\nError happened in correcting error.\n";
  exit 1;
fi
echo -e "\n********************\nReads corrected.\n*************************************\n\n"
cd $rootDir

# SOAPdenovo2 assemble:
mkdir assemble_SOAPdenovo2
cd assemble_SOAPdenovo2
echo -e "max_rd_len=130\n[LIB]\navg_ins=400\nasm_flags=3\nreverse_seq=0\nrank=1\nq1=${c400i_1}\nq2=${c400i_2}\nq=${c400i_s}" >Lib.cfg
cp Lib.cfg GapCloser.cfg
if [ ! -f "$rootDir/filter_data_SOAPdenovo2/${r3000i_1}.dup.clean" ] || [ ! -f "$rootDir/filter_data_SOAPdenovo2/${r3000i_2}.dup.clean" ]; then
  echo "File: $rootDir/filter_data_SOAPdenovo2/${r3000i_1}.dup.clean or $rootDir/filter_data_SOAPdenovo2/${r3000i_2}.dup.clean does NOT exist!"
  exit 1;
fi

if [ ! -f "$rootDir/filter_data_SOAPdenovo2/${r8000i_1}.dup.clean" ] || [ ! -f "$rootDir/filter_data_SOAPdenovo2/${r8000i_2}.dup.clean" ]; then
  echo "File: $rootDir/filter_data_SOAPdenovo2/${r8000i_1}.dup.clean or $rootDir/filter_data_SOAPdenovo2/${r8000i_2}.dup.clean does NOT exist!"
  exit 1;
fi

echo -e "[LIB]\navg_ins=3000\nasm_flags=2\nreverse_seq=1\nrank=2\nmap_len=31\nq1=$rootDir/filter_data_SOAPdenovo2/${r3000i_1}.dup.clean\nq2=$rootDir/filter_data_SOAPdenovo2/${r3000i_2}.dup.clean\n" >>Lib.cfg
echo -e "[LIB]\navg_ins=8000\nasm_flags=2\nreverse_seq=1\nrank=3\nmap_len=31\nq1=$rootDir/filter_data_SOAPdenovo2/${r8000i_1}.dup.clean\nq2=$rootDir/filter_data_SOAPdenovo2/${r8000i_2}.dup.clean\n" >>Lib.cfg

echo -e "\n*************************************\nStart to assemble reads.\n********************\n"
K=45
$rootDir/bin/SOAPdenovo-63mer_v2.0 all -s Lib.cfg -d 1 -R -o Bombus_impatiens -K $K -p 16 -F >asm.log 2>asm.err
if [ ! -f "Bombus_impatiens.scafSeq" ]; then
  echo -e "File: Bombus_impatiens.scafSeq does NOT exist!\nError happened in assembling.\n"
  exit 1;
fi

$rootDir/bin/GapCloser_v1.12 -a Bombus_impatiens.scafSeq -b GapCloser.cfg -p 31 -l 70 -t 16 -o Bombus_impatiens.scafSeq.GC.fa >GapCloser.log
if [ ! -f "Bombus_impatiens.scafSeq.GC.fa" ]; then
  echo -e "File: Bombus_impatiens.scafSeq.GC.fa does NOT exist!\nError happened in gap filling.\n"
  exit 1;
fi
echo -e "\n********************\nAssemble done.\n*************************************\n"

cd $rootDir
echo -e "\nAll done.\n"
