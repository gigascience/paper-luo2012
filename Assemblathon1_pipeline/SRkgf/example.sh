# for all
perl /nas/GAG_01A/assembly/Database/Assembly/Package/kgf/SRkgf_unite/SRKGF.pl --dir /ifs1/GAG/annotation/zhanghao2/FF --kmer 33 --prefix ass --outdir /ifs2/DEVELOPMENT/GROUP/zhanghao2/PROGRAM/underway/SR/SR_t/dsFF --cvg 23 --falsecontig 300 --cpu 4 --step 123 --thread 8 --P Project --queue all.q 

# for step 1
perl /nas/GAG_01A/assembly/Database/Assembly/Package/kgf/SRkgf_unite/SRKGF.pl --dir /ifs1/GAG/annotation/zhanghao2/FF --kmer 33 --prefix ass --cvg 23 --outdir /ifs2/DEVELOPMENT/GROUP/zhanghao2/PROGRAM/underway/SR/SR_t/dsFF --shortcontig 70 --falsecontig 300 --step 1  --queue all.q --P Project  

#for step 2/23 method_1 
perl /nas/GAG_01A/assembly/Database/Assembly/Package/kgf/SRkgf_unite/SRKGF.pl --contig /ifs1/GAG/annotation/zhanghao2/FF/ass.scafSeq.SCAF.contig --gapread /ifs1/GAG/annotation/zhanghao2/FF/SRkgf/gapread.fa --cpu 4 --thread 8 --outdir /ifs2/DEVELOPMENT/GROUP/zhanghao2/PROGRAM/underway/SR/SR_t/dsFF --step 23 --queue all.q  --P Project 

#for step 2/23 method_2
perl /nas/GAG_01A/assembly/Database/Assembly/Package/kgf/SRkgf_unite/SRKGF.pl --dir /ifs1/GAG/annotation/zhanghao2/FF --scaf /ifs1/GAG/annotation/zhanghao2/FF/ass.scafSeq --cpu 4 --thread 8 --outdir /ifs2/DEVELOPMENT/GROUP/zhanghao2/PROGRAM/underway/SR/SR_t/dsFF --queue all.q  --step 23  --P Project 

#for step 3
perl /nas/GAG_01A/assembly/Database/Assembly/Package/kgf/SRkgf_unite/SRKGF.pl --outdir /ifs2/DEVELOPMENT/GROUP/zhanghao2/PROGRAM/underway/SR/SR_t/dsFF --step 3  


