#!/bash/bin
rootDir=`pwd`
nucmer="$rootDir/nucmer"  # change this value if neccessary
if [ ! -f $nucmer ]; then
  echo "Program: ${nucmer} does NOT exist! Please set the variable for \"nucmer\" in removeAdaptor.sh."
  exit 1;
fi

rm -rf removeAdaptor

# remove adaptor
echo "Start to remove adaptor."
mkdir removeAdaptor
cd removeAdaptor
f1="$rootDir/Data/original/mediumjump_1.fastq"
f2="$rootDir/Data/original/mediumjump_2.fastq"
f3="$rootDir/Data/original/shortjump_1.fastq"
f4="$rootDir/Data/original/shortjump_2.fastq"

echo "  Check and link files."
for f in $f1 $f2 $f3 $f4; do
  if [ ! -f $f ]; then
    echo "File: $f does NOT exist! Linking failed.";
    exit 1;
  fi
  ln -s $f
done

echo "  Convert fastq to fasta since nucmer requires fasta as input."
for fastq in *.fastq; do
  len=${#fastq}-5
  name=${fastq:0:$len}
  perl $rootDir/bin/fq2fa.pl $fastq >${name}fa
  if [ ! -f ${name}fa ]; then
    echo "Converting from ${fastq} to ${name}fa failed!"
    exit 1;
  fi
done

echo "  Cut files to small pieces since nucmer can only support 4G input data at most."
for fasta in *.fa; do
  perl $rootDir/bin/fastaDeal.pl -cutf 5 ${fasta}
done

echo "  Align reads to adaptor using nucmer."
for cutDir in *.cut; do
  cd ${cutDir}
  len=${#cutDir}-4
  prefix=${cutDir:0:$len}
  for f in ${prefix}.1 ${prefix}.2 ${prefix}.3 ${prefix}.4 ${prefix}.5; do
    if [ ! -f $f ]; then
      echo "File: $f does NOT exist! Alignment failed.";
      exit 1;
    fi
    $nucmer -l 8 -c 16 -b 32 -g 32 -p $f $rootDir/adapter.fa $f >filter_${f}.log 2>&1
  done
  cd ..
done

echo "  Remove sequence with adaptor."
perl $rootDir/bin/rmAdapterPair.pl shortjump_1.fa.cut shortjump_2.fa.cut shortjump_1.fastq shortjump_2.fastq >shortjumpRmAdapter.log
if [ ! -f "shortjump_1.fastq.rmAd" ] || [ ! -f "shortjump_2.fastq.rmAd" ]; then
  echo "File: shortjump_1.fastq.rmAd or shortjump_2.fastq.rmAd does NOT exist! Removing adaptor failed."
  exit 1;
fi

perl $rootDir/bin/rmAdapterPair.pl mediumjump_1.fa.cut mediumjump_2.fa.cut mediumjump_1.fastq mediumjump_2.fastq >mediumjumpRmAdapter.log
if [ ! -f "mediumjump_1.fastq.rmAd" ] || [ ! -f "mediumjump_2.fastq.rmAd" ]; then
  echo "File: mediumjump_1.fastq.rmAd or mediumjump_2.fastq.rmAd does NOT exist! Removing adaptor failed."
  exit 1;
fi

cd $rootDir
echo -e "Finish removing adaptor.\n\n"
