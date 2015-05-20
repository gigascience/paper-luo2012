#!/bash/bin
f1="speciesA_200i_40x.1.fastq.gz"
f2="speciesA_200i_40x.2.fastq.gz"
f3="speciesA_300i_40x.1.fastq.gz"
f4="speciesA_300i_40x.2.fastq.gz"
f5="speciesA_3000i_20x_r3.1.fastq.gz"
f6="speciesA_3000i_20x_r3.2.fastq.gz"
f7="speciesA_10000i_20x_r3.1.fastq.gz"
f8="speciesA_10000i_20x_r3.2.fastq.gz"
for f in $f1 $f2 $f3 $f4 $f5 $f6 $f7 $f8; do
  if [ ! -f $f ]; then
    echo "File: $f does NOT exist!\n";
    exit -1;
  fi
done

ln -s $f1 speciesA_L1_200i40x_1.fq.gz
ln -s $f2 speciesA_L1_200i40x_2.fq.gz
ln -s $f3 speciesA_L1_300i40x_1.fq.gz
ln -s $f4 speciesA_L1_300i40x_2.fq.gz
ln -s $f5 speciesA_L1_3000i20xr3_1.fq.gz
ln -s $f6 speciesA_L1_3000i20xr3_2.fq.gz
ln -s $f7 speciesA_L1_10000i20xr3_1.fq.gz
ln -s $f8 speciesA_L1_10000i20xr3_2.fq.gz
